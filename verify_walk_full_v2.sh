#!/data/data/com.termux/files/usr/bin/bash
# Walk + verify + auto-fix + write canonical contents (idempotent; backups .bak si modifié)
set -euo pipefail
ROOT=~/meta-spiratech
cd "$ROOT"

say(){ printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m!!\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31mxx\033[0m %s\n" "$*"; exit 1; }

# TMP sûr pour Termux
TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMPDIR"

# ensure dirs
mkdir -p packages/meta-core/src packages/connectors/src apps/pulseo-web/app/api/rss apps/pulseo-web/app public config scripts grafana

# util: write file only if new or changed (backup .bak once)
write_file(){
  local path="$1"
  local tmp="$2"
  mkdir -p "$(dirname "$path")"
  if [ -f "$path" ]; then
    if cmp -s "$path" "$tmp"; then
      say "OK  $path (unchanged)"
      rm -f "$tmp"
      return 0
    else
      cp "$path" "$path.bak" 2>/dev/null || true
      mv "$tmp" "$path"
      say "UPD $path (backup: $path.bak)"
      return 0
    fi
  else
    mv "$tmp" "$path"
    say "NEW $path"
  fi
}

# helper: write heredoc to a temp file safely
to_tmp(){
  local name="$1"
  local f="$TMPDIR/$name.$$"
  cat > "$f"
  printf "%s" "$f"
}

# ----------------------------
# canonical contents start
# ----------------------------

# 1) packages/meta-core/src/metaLoop.ts
tmp="$(to_tmp metaLoop.ts)" <<'EOT'
// Meta-SpiraTech Loop — sense→think→act→learn
export type MetaEvent = { ts:number; type:string; payload?:any; source?:string };
export type Skill = { id:string; match:(e:MetaEvent)=>boolean; run:(e:MetaEvent,ctx:MetaCtx)=>Promise<void> };
export type Connector = { id:string; send:(e:MetaEvent)=>Promise<void>; pull?:()=>Promise<MetaEvent[]> };

export type MetaCtx = {
  emit:(e:MetaEvent)=>void;
  memory:{ get:(key:string)=>any; set:(key:string,v:any)=>void; append:(key:string,v:any)=>void };
  policy:{ get:(k:string,def?:any)=>any; set:(k:string,v:any)=>void };
  connectors: Map<string,Connector>;
  skills: Skill[];
};

export class MetaLoop {
  private buf: MetaEvent[] = [];
  private ctx: MetaCtx;
  private timer?: any;

  constructor(ctx: MetaCtx){ this.ctx = ctx; }

  sense(e: MetaEvent){ this.buf.push(e); if(this.buf.length>5000) this.buf.shift(); }
  registerSkill(s: Skill){ this.ctx.skills.push(s); }
  registerConnector(c: Connector){ this.ctx.connectors.set(c.id, c); }

  start(intervalMs=1000){
    if(this.timer) return;
    this.timer = setInterval(()=>this.cycle(), intervalMs);
  }
  stop(){ if(this.timer){ clearInterval(this.timer); this.timer=undefined; } }

  private async cycle(){
    // 1) SENSE: pull depuis connecteurs
    for(const c of this.ctx.connectors.values()){
      if(c.pull){ try{ (await c.pull()).forEach(e=>this.sense(e)); }catch{} }
    }
    // 2) THINK/ACT: router vers skills sur la fenêtre récente
    const window = this.buf.filter(e=>e.ts> Date.now()-60_000);
    for(const e of window){
      for(const s of this.ctx.skills){ if(s.match(e)){ await s.run(e,this.ctx); } }
    }
    // 3) LEARN: adaptation simple selon erreurs
    const err = window.filter(e=>e.type.startsWith("error:")).length;
    const cur = this.ctx.policy.get("refreshFactor",1);
    if(err>=3 && cur<3) this.ctx.policy.set("refreshFactor", cur+0.25);
    if(err===0 && cur>1) this.ctx.policy.set("refreshFactor", Math.max(1, cur-0.25));
  }
}

// LocalStorage-backed context (PWA/tablette)
export function makeLocalCtx(): any {
  const mget=(k:string)=>{ try{ return JSON.parse(localStorage.getItem("meta:"+k) || "null"); }catch{return null;} };
  const mset=(k:string,v:any)=>localStorage.setItem("meta:"+k, JSON.stringify(v));
  const madd=(k:string,v:any)=>{ const a=mget(k)||[]; a.push(v); mset(k,a); };
  const pget=(k:string,def?:any)=>mget("policy:"+k) ?? def;
  const pset=(k:string,v:any)=>mset("policy:"+k,v);
  return {
    emit:(e:MetaEvent)=>madd("events", e),
    memory:{ get:mget, set:mset, append:madd },
    policy:{ get:pget, set:pset },
    connectors: new Map<string,Connector>(), skills: [] as Skill[]
  };
}
EOT
write_file "packages/meta-core/src/metaLoop.ts" "$tmp"

# 2) packages/meta-core/src/skills.ts
tmp="$(to_tmp skills.ts)" <<'EOT'
import type { Skill } from "./metaLoop";

export const SkillBatteryGuard: Skill = {
  id:"battery-guard",
  match:e=> e.type==="battery:update" && typeof e.payload?.level==="number",
  run:async (e,ctx)=>{
    const lvl=e.payload.level as number;
    if(lvl<=15){ ctx.policy.set("visuals","dimmed"); ctx.policy.set("mediaQuality","low"); }
    else if(lvl<=30){ ctx.policy.set("visuals","normal"); ctx.policy.set("mediaQuality","medium"); }
    else { ctx.policy.set("visuals","on"); ctx.policy.set("mediaQuality","high"); }
  }
};

export const SkillAutoFix: Skill = {
  id:"auto-fix",
  match:e=> e.type.startsWith("error:"),
  run:async (_e,ctx)=>{
    const rf = ctx.policy.get("refreshFactor",1);
    ctx.policy.set("refreshFactor", Math.min(3, rf+0.5));
  }
};

export const SkillTelemetryBoost: Skill = {
  id:"telemetry-boost",
  match:e=> e.type==="sos:trigger" || e.type==="ritual:tick",
  run:async (_e,ctx)=>{
    ctx.policy.set("telemetry.flushNow", true);
  }
};
EOT
write_file "packages/meta-core/src/skills.ts" "$tmp"

# 3) packages/connectors/src/index.ts
tmp="$(to_tmp connectors.ts)" <<'EOT'
export type ConnEvent = { ts:number; type:string; payload?:any; };
export interface Connector { id:string; send(e:ConnEvent):Promise<void>; pull?():Promise<ConnEvent[]>; }

export class HttpConnector implements Connector{
  constructor(public id:string, private url:string){}
  async send(e:ConnEvent){
    await fetch(this.url, { method:"POST", headers:{ "content-type":"application/json" }, body: JSON.stringify(e) });
  }
}

export class RssConnector implements Connector{
  constructor(public id:string, private feedUrl:string){}
  async send(){ /* noop */ }
  async pull(){
    const r = await fetch(`/api/rss?url=${encodeURIComponent(this.feedUrl)}`);
    const items = await r.json();
    return items.map((x:any)=>({ ts:Date.now(), type:"rss:item", payload:x }));
  }
}

export class WebhookConnector extends HttpConnector {}
EOT
write_file "packages/connectors/src/index.ts" "$tmp"

# 4) apps/pulseo-web/app/providers.tsx
tmp="$(to_tmp providers.tsx)" <<'EOT'
"use client";
import { useEffect } from "react";
// @ts-ignore (adapter ces imports si ton chemin AutoCore diffère)
import { AutoCoreProvider, useAutoCore } from "@pulseo/auto-core";
import { MetaLoop, makeLocalCtx } from "@spiratech/meta-core/metaLoop";
import { SkillBatteryGuard, SkillAutoFix, SkillTelemetryBoost } from "@spiratech/meta-core/skills";

function MetaBridge(){
  const core = (typeof useAutoCore === "function") ? useAutoCore() : { subscribe:()=>()=>{}, actions:new Map() };
  useEffect(()=>{
    const ctx = makeLocalCtx();
    const meta = new MetaLoop(ctx);
    meta.registerSkill(SkillBatteryGuard);
    meta.registerSkill(SkillAutoFix);
    meta.registerSkill(SkillTelemetryBoost);

    const un = core?.subscribe?.((evt:any)=> ctx.emit({ ts:Date.now(), type:evt.type, payload:evt.payload, source:"autocore" }));

    // Battery (Android)
    // @ts-ignore
    navigator.getBattery?.().then((b:any)=>{
      const send=()=>ctx.emit({ ts:Date.now(), type:"battery:update", payload:{ level:Math.round(b.level*100) }});
      b.addEventListener("levelchange",send); b.addEventListener("chargingchange",send); send();
    });

    // Network
    // @ts-ignore
    const n = navigator.connection;
    if(n){ const send=()=>ctx.emit({ ts:Date.now(), type:"network:update", payload:{ type:n.effectiveType, downlink:n.downlink }});
      n.addEventListener("change", send); send(); }

    meta.start(1000);
    const i=setInterval(()=>{
      if(ctx.policy.get("telemetry.flushNow",false)){ core?.actions?.get?.("telemetry.flush")?.(); ctx.policy.set("telemetry.flushNow", false); }
      document.documentElement.dataset.visuals = ctx.policy.get("visuals","on");
      document.documentElement.dataset.mediaQuality = ctx.policy.get("mediaQuality","high");
      document.documentElement.dataset.refreshFactor = String(ctx.policy.get("refreshFactor",1));
    },1000);

    // @ts-ignore
    (window as any).__metaLoop = meta;
    return ()=>{ clearInterval(i); un?.(); meta.stop(); };
  },[]);
  return null;
}

export default function Providers({ children }: { children: React.ReactNode }) {
  const AC:any = AutoCoreProvider ?? ((p:any)=>p.children);
  return <AC><MetaBridge/>{children}</AC>;
}
EOT
write_file "apps/pulseo-web/app/providers.tsx" "$tmp"

# 5) apps/pulseo-web/app/api/rss/route.ts
tmp="$(to_tmp rss_route.ts)" <<'EOT'
import { NextResponse } from "next/server";
export async function GET(req:Request){
  const { searchParams } = new URL(req.url);
  const url = searchParams.get("url");
  if(!url) return NextResponse.json([], { status: 200 });
  const res = await fetch(url, { headers:{ "user-agent":"Pulseo/1.0" }});
  const xml = await res.text();
  const items = Array.from(xml.matchAll(/<item>\s*<title>(.*?)<\/title>.*?<link>(.*?)<\/link>/gs))
    .map((m:any)=>({ title:m[1], link:m[2] }));
  return NextResponse.json(items);
}
EOT
write_file "apps/pulseo-web/app/api/rss/route.ts" "$tmp"

# 6) public/manifest.json
tmp="$(to_tmp manifest.json)" <<'EOT'
{
  "name": "Pulseo",
  "short_name": "Pulseo",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#101010",
  "icons": [{ "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" }]
}
EOT
write_file "public/manifest.json" "$tmp"

# 7) public/sw.js
tmp="$(to_tmp sw.js)" <<'EOT'
self.addEventListener("install", e=>{
  e.waitUntil(caches.open("pulseo-v1").then(c=>c.addAll(["/","/dev/dashboard","/dev/simulate"])));
});
self.addEventListener("fetch", e=>{
  e.respondWith(caches.match(e.request).then(r=> r || fetch(e.request).then(resp=>{
    const clone = resp.clone(); caches.open("pulseo-v1").then(c=>c.put(e.request, clone)); return resp;
  })));
});
EOT
write_file "public/sw.js" "$tmp"

# 8) config/meta.json (si absent)
if [ ! -f "config/meta.json" ]; then
  tmp="$(to_tmp meta.json)" <<'EOT'
{
  "refresh.intervals": { "fast": 1000, "medium": 3000, "slow": 10000 },
  "battery.thresholds": { "low": 30, "critical": 15 },
  "telemetry": { "batchMs": 900000, "flushOnSOS": true },
  "learning": { "errRaiseFactor": 0.5, "errDecay": 0.25 },
  "policy": { "visuals": "on", "mediaQuality": "high", "refreshFactor": 1 }
}
EOT
  write_file "config/meta.json" "$tmp"
else
  say "OK  config/meta.json (exists) — conserve"
fi

# 9) .gitignore minimal
tmp="$(to_tmp gitignore)" <<'EOT'
node_modules
.env*
*.log
coverage
.next
dist
EOT
write_file ".gitignore" "$tmp"

# 10) cleanup
find . -type f \( -name "*~" -o -name "*.bak~" -o -name "*.tmp" \) -print -delete

say "✔️  Walk+Fix terminé (v2)."

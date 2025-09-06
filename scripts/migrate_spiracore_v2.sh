#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT=~/meta-spiratech; cd "$ROOT"
GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
say(){ printf "${GREEN}==>${NC} %s\n" "$*"; }; warn(){ printf "${YELLOW}!!${NC} %s\n" "$*"; }

# Dossiers requis
mkdir -p packages/spira-core-compat/src \
         packages/meta-core/src \
         packages/connectors/src \
         apps/pulseo-web/app/dev \
         apps/pulseo-web/app/api/rss \
         public config scripts grafana

# Util: écriture sûre (backup si différent)
tmpd="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"; mkdir -p "$tmpd"
write(){ dest="$1"; shift; tmp="$tmpd/$(basename "$dest").$$.tmp"; printf "%s" "$*" > "$tmp";
  if [ -f "$dest" ] && cmp -s "$dest" "$tmp"; then rm -f "$tmp"; say "OK  $dest"; else
    [ -f "$dest" ] && cp "$dest" "$dest.bak" 2>/dev/null || true; mv "$tmp" "$dest";
    [ -f "$dest.bak" ] && say "UPD $dest (backup: $dest.bak)" || say "NEW $dest"; fi; }

# 1) SpiraCore Compat (pont unique)
write packages/spira-core-compat/src/index.ts '
// SpiraCore v2 Compat — mappe l’ancien AutoCore/MetaCore vers SpiraCore Runtime
export type SpiraEvent = { ts:number; type:string; payload?:any; source?:string };
export type Action = (payload?:any)=>Promise<void>|void;

export class SpiraRuntime {
  private listeners: ((e:SpiraEvent)=>void)[] = [];
  public actions = new Map<string,Action>();
  emit(e:SpiraEvent){ this.listeners.forEach(fn=>{ try{ fn(e); }catch{} }); }
  subscribe(fn:(e:SpiraEvent)=>void){ this.listeners.push(fn); return ()=>{this.listeners=this.listeners.filter(x=>x!==fn);} }
  registerAction(name:string, fn:Action){ this.actions.set(name, fn); }
}

// Facade compat
export function makeCompat(){
  const rt = new SpiraRuntime();
  const api = {
    runtime: rt,
    // ancien .actions.get("telemetry.flush")…
    actions: rt.actions,
    subscribe: (fn:(e:SpiraEvent)=>void)=> rt.subscribe(fn),
    emit: (type:string, payload?:any)=> rt.emit({ ts:Date.now(), type, payload, source:"spira" })
  };
  return api;
}
'

# 2) MetaLoop (si pas déjà fiable)
[ -f packages/meta-core/src/metaLoop.ts ] || write packages/meta-core/src/metaLoop.ts '
// MetaLoop minimal pour SpiraCore: sense→think→act→learn
export type MetaEvent={ts:number;type:string;payload?:any;source?:string};
export type Skill={id:string;match:(e:MetaEvent)=>boolean;run:(e:MetaEvent,ctx:any)=>Promise<void>};
export class MetaLoop{private b:MetaEvent[]=[];private ctx:any;private t:any;
constructor(ctx:any){this.ctx=ctx;} sense(e:MetaEvent){this.b.push(e);if(this.b.length>5000)this.b.shift();}
registerSkill(s:Skill){this.ctx.skills.push(s);} start(i=1000){if(this.t)return;this.t=setInterval(()=>this.cycle(),i);}
stop(){if(this.t){clearInterval(this.t);this.t=undefined;}} async cycle(){const w=this.b.filter(e=>e.ts>Date.now()-60000);
for(const e of w){for(const s of this.ctx.skills){if(s.match(e))await s.run(e,this.ctx);}}
const err=w.filter(e=>e.type.startsWith("error:")).length;const cur=this.ctx.policy.get("refreshFactor",1);
if(err>=3&&cur<3)this.ctx.policy.set("refreshFactor",cur+0.25); if(err===0&&cur>1)this.ctx.policy.set("refreshFactor",Math.max(1,cur-0.25));}}
export function makeLocalCtx(){const g=(k:string)=>{try{return JSON.parse(localStorage.getItem("meta:"+k)||"null");}catch{return null;}};
const s=(k:string,v:any)=>localStorage.setItem("meta:"+k,JSON.stringify(v));const a=(k:string,v:any)=>{const A=g(k)||[];A.push(v);s(k,A)};
const pg=(k:string,d?:any)=>g("policy:"+k)??d;const ps=(k:string,v:any)=>s("policy:"+k,v);
return{emit:(e:MetaEvent)=>a("events",e),memory:{get:g,set:s,append:a},policy:{get:pg,set:ps},connectors:new Map(),skills:[]};}
'

# 3) Skills essentiels (battery / auto-fix / telemetry / sim reinforce)
write packages/meta-core/src/skills.ts 'import type{Skill}from"./metaLoop";
export const SkillBatteryGuard:Skill={id:"battery-guard",match:e=>e.type==="battery:update"&&typeof e.payload?.level==="number",
run:async(e,ctx)=>{const l=e.payload.level as number;if(l<=15){ctx.policy.set("visuals","dimmed");ctx.policy.set("mediaQuality","low");}
else if(l<=30){ctx.policy.set("visuals","normal");ctx.policy.set("mediaQuality","medium");}
else{ctx.policy.set("visuals","on");ctx.policy.set("mediaQuality","high");}}};
export const SkillAutoFix:Skill={id:"auto-fix",match:e=>e.type.startsWith("error:"),run:async(_e,ctx)=>{const rf=ctx.policy.get("refreshFactor",1);ctx.policy.set("refreshFactor",Math.min(3,rf+0.5));}};
export const SkillTelemetryBoost:Skill={id:"telemetry-boost",match:e=>e.type==="sos:trigger"||e.type==="ritual:tick",run:async(_e,ctx)=>{ctx.policy.set("telemetry.flushNow",true);}};'

# 4) Moteur d’auto-simulation (anticipation long terme)
write packages/meta-core/src/sim.ts 'export type Pred={user:{sos:number;ritual:number;idle:number};risk:{bug:number;perf:number};actions:string[];ts:number};
function c01(x:number){return Math.max(0,Math.min(1,x));}function n3(a:number,b:number,c:number){const s=a+b+c||1;return[a/s,b/s,c/s];}
export class SimulationEngine{private rec:{type:string;ts:number}[]=[];private last?:Pred;ingest(e:{type:string;ts:number}){this.rec.push(e);if(this.rec.length>5000)this.rec.shift();}
step(now=Date.now()):Pred{const W=300000;const w=this.rec.filter(e=>e.ts>now-W);const err=w.filter(e=>e.type.startsWith("error:")).length;
const sos=w.filter(e=>e.type==="sos:trigger").length;const rit=w.filter(e=>e.type==="ritual:tick").length;const net=w.filter(e=>e.type==="network:update"&&e["payload"]?.downlink<1).length;
const bat=w.filter(e=>e.type==="battery:update"&&e["payload"]?.level<=30).length;let pS=c01(0.05+sos*0.1+err*0.02),pR=c01(0.15+rit*0.05),pI=c01(1-(pS+pR));[pS,pR,pI]=n3(pS,pR,pI);
let pB=c01(0.08+err*0.04+net*0.03),pP=c01(0.10+bat*0.03+net*0.05);
if(this.last){const a=0.6;pS=a*this.last.user.sos+(1-a)*pS;pR=a*this.last.user.ritual+(1-a)*pR;pI=a*this.last.user.idle+(1-a)*pI;pB=a*this.last.risk.bug+(1-a)*pB;pP=a*this.last.risk.perf+(1-a)*pP;}
const actions:string[]=[];if(pB>0.25)actions.push("increase_refreshFactor");if(pP>0.25)actions.push("lower_mediaQuality");if(pS>0.20)actions.push("pre_flush_on_SOS");if(bat>0)actions.push("dim_visuals");
const pred:Pred={user:{sos:pS,ritual:pR,idle:pI},risk:{bug:pB,perf:pP},actions,ts:now};this.last=pred;return pred;}}
export function startAutoSimulation(ctx:any,opts:{periodMs?:number}={}){const period=opts.periodMs??(ctx?.policy?.get?.("simulation.periodMs",5000)??5000);
const eng=new SimulationEngine();const tick=()=>{const p=eng.step();ctx.policy.set("pred.user.sos",+p.user.sos.toFixed(3));
ctx.policy.set("pred.user.ritual",+p.user.ritual.toFixed(3));ctx.policy.set("pred.user.idle",+p.user.idle.toFixed(3));
ctx.policy.set("risk.bug",+p.risk.bug.toFixed(3));ctx.policy.set("risk.perf",+p.risk.perf.toFixed(3));ctx.policy.set("next.actions",p.actions);try{localStorage.setItem("meta:pred",JSON.stringify(p));}catch{}};
try{(globalThis as any).__metaSimIngest=(e:{type:string;ts:number})=>eng.ingest(e);}catch{} const id=setInterval(tick,period); (globalThis as any).__metaSimStop=()=>clearInterval(id); tick();}
'

# 5) Connecteurs (http/rss/webhook)
write packages/connectors/src/index.ts 'export type ConnEvent={ts:number;type:string;payload?:any};export interface Connector{id:string;send(e:ConnEvent):Promise<void>;pull?():Promise<ConnEvent[]>;}
export class HttpConnector implements Connector{constructor(public id:string,private url:string){} async send(e:ConnEvent){await fetch(this.url,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(e)})}}
export class RssConnector implements Connector{constructor(public id:string,private feedUrl:string){} async send(){} async pull(){const r=await fetch(`/api/rss?url=${encodeURIComponent(this.feedUrl)}`);const items=await r.json();return items.map((x:any)=>({ts:Date.now(),type:"rss:item",payload:x}))}}
export class WebhookConnector extends HttpConnector{}'

# 6) Provider React — bascule vers **SpiraCore v2** avec compat fallback
write apps/pulseo-web/app/providers.tsx '"use client";
import { useEffect } from "react";
import { makeCompat } from "@spiratech/spira-core-compat";
import { MetaLoop, makeLocalCtx } from "@spiratech/meta-core/metaLoop";
import { SkillBatteryGuard, SkillAutoFix, SkillTelemetryBoost } from "@spiratech/meta-core/skills";
import { startAutoSimulation } from "@spiratech/meta-core/sim";
// @ts-ignore: si ancien AutoCore existe encore, on s’adapte
let Core:any;try{Core=require("@pulseo/auto-core");}catch{Core={AutoCoreProvider:({children}:any)=>children,useAutoCore:()=>({subscribe:()=>()=>{},actions:new Map()})};}
const { AutoCoreProvider, useAutoCore } = Core;

export default function Providers({ children }: { children: React.ReactNode }) {
  const AC:any = AutoCoreProvider ?? ((p:any)=>p.children);
  return <AC><MetaBridge/>{children}</AC>;
}
function MetaBridge(){
  // Choix runtime SpiraCore v2 + compat
  const compat = makeCompat();
  const core = (typeof useAutoCore==="function") ? useAutoCore() : compat;

  useEffect(()=>{
    const ctx = makeLocalCtx();
    const meta = new MetaLoop(ctx);
    meta.registerSkill(SkillBatteryGuard);
    meta.registerSkill(SkillAutoFix);
    meta.registerSkill(SkillTelemetryBoost);

    // pont événements → MetaLoop + simulateur
    const un = core?.subscribe?.((evt:any)=>{ ctx.emit({ ts:Date.now(), type:evt.type, payload:evt.payload, source:"core" });
      try{ /* @ts-ignore */ globalThis.__metaSimIngest?.({ ts:Date.now(), type:evt.type }); }catch{} });

    // Sondes Android (batterie/réseau)
    // @ts-ignore
    navigator.getBattery?.().then((b:any)=>{ const send=()=>{const level=Math.round(b.level*100);
      ctx.emit({ ts:Date.now(), type:"battery:update", payload:{ level }});
      try{ /* @ts-ignore */ globalThis.__metaSimIngest?.({ ts:Date.now(), type:"battery:update" }); }catch{} };
      b.addEventListener("levelchange",send); b.addEventListener("chargingchange",send); send(); });
    // @ts-ignore
    const n:any=navigator.connection; if(n){ const send=()=>{ ctx.emit({ ts:Date.now(), type:"network:update", payload:{ type:n.effectiveType, downlink:n.downlink }});
      try{ /* @ts-ignore */ globalThis.__metaSimIngest?.({ ts:Date.now(), type:"network:update" }); }catch{} }; n.addEventListener("change",send); send(); }

    startAutoSimulation(ctx, { periodMs: ctx.policy.get("simulation.periodMs", 5000) });
    meta.start(1000);

    // action de flush (SpiraCore/compat)
    core?.actions?.set?.("telemetry.flush", async()=>{ /* place ton flush réel ici */ });

    return ()=>{ try{ /* @ts-ignore */ globalThis.__metaSimStop?.(); }catch{}; un?.(); meta.stop(); };
  },[]);
  return null;
}
'

# 7) API RSS (proxy) + page de debug simulation
write apps/pulseo-web/app/api/rss/route.ts 'import { NextResponse } from "next/server";
export async function GET(req:Request){const { searchParams }=new URL(req.url);const url=searchParams.get("url");
if(!url) return NextResponse.json([], { status:200 }); const res=await fetch(url,{headers:{ "user-agent":"Pulseo/1.0" }}); const xml=await res.text();
const items=Array.from(xml.matchAll(/<item>\s*<title>(.*?)<\/title>.*?<link>(.*?)<\/link>/gs)).map((m:any)=>({title:m[1],link:m[2]})); return NextResponse.json(items); }'

write apps/pulseo-web/app/dev/sim/page.tsx '"use client";import {useEffect,useState} from"react";
type Pred={user:{sos:number;ritual:number;idle:number};risk:{bug:number;perf:number};actions:string[];ts:number};
export default function SimPage(){const[p,setP]=useState<Pred|null>(null);useEffect(()=>{const t=setInterval(()=>{try{const raw=localStorage.getItem("meta:pred");if(raw)setP(JSON.parse(raw));}catch{}},1000);return()=>clearInterval(t);},[]);
return(<main style={{padding:16,fontFamily:\"Inter,ui-sans-serif\"}}>
<h1>SpiraCore v2 — Auto-Simulation</h1>{!p?<p>En attente…</p>:<div style={{display:\"grid\",gap:8,maxWidth:520}}>
<div><b>User</b> — SOS {(p.user.sos*100).toFixed(1)}% · Ritual {(p.user.ritual*100).toFixed(1)}% · Idle {(p.user.idle*100).toFixed(1)}%</div>
<div><b>Risques</b> — Bug {(p.risk.bug*100).toFixed(1)}% · Perf {(p.risk.perf*100).toFixed(1)}%</div>
<div><b>Actions</b> — {p.actions.join(\", \")||\"—\"}</div><div style={{opacity:.6}}>ts: {new Date(p.ts).toLocaleTimeString()}</div></div>}
<hr/><p>Les prédictions alimentent la policy pour agir avant l’apparition du problème.</p></main>); }'

# 8) PWA basique (si manquant)
[ -f public/manifest.json ] || write public/manifest.json '{ "name":"Pulseo","short_name":"Pulseo","start_url":"/","display":"standalone","background_color":"#000000","theme_color":"#101010","icons":[{"src":"/icon-192.png","sizes":"192x192","type":"image/png"}] }'
[ -f public/sw.js ]        || write public/sw.js        'self.addEventListener("install",e=>{e.waitUntil(caches.open("pulseo-v2").then(c=>c.addAll(["/","/dev/sim"])))});self.addEventListener("fetch",e=>{e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request)))});'

# 9) Config v2 (merge minimal)
if [ -f config/meta.json ] && command -v jq >/dev/null 2>&1; then
  tmp="config/meta.json.tmp"
  jq '.simulation = (.simulation // {"enabled":true,"periodMs":5000}) | .policy = (.policy // {"visuals":"on","mediaQuality":"high","refreshFactor":1})' config/meta.json > "$tmp" && mv "$tmp" config/meta.json
  say "OK  config/meta.json merge"
else
  [ -f config/meta.json ] || write config/meta.json '{ "policy":{"visuals":"on","mediaQuality":"high","refreshFactor":1}, "simulation":{"enabled":true,"periodMs":5000} }'
fi

# 10) Mini rapport
echo -e "${GREEN}==>${NC} Migration SpiraCore v2 prête. Ouvre /dev/sim pour valider."

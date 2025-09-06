"use client";
import { useEffect } from "react";
// Remplace ces imports par tes chemins réels si différents
// @ts-ignore
import { AutoCoreProvider, useAutoCore } from "@pulseo/auto-core";
import { MetaLoop, makeLocalCtx } from "@spiratech/meta-core/metaLoop";
import { SkillBatteryGuard, SkillAutoFix, SkillTelemetryBoost } from "@spiratech/meta-core/skills";

function MetaBridge(){
  const core = useAutoCore?.() ?? { subscribe:()=>{}, actions:new Map() };
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
    window.__metaLoop = meta;
    return ()=>{ clearInterval(i); un?.(); meta.stop(); };
  },[]);
  return null;
}

export default function Providers({ children }: { children: React.ReactNode }) {
  // Si pas d'AutoCoreProvider dispo, on renvoie juste children + bridge
  const AC:any = AutoCoreProvider ?? ((p:any)=>p.children);
  return <AC><MetaBridge/>{children}</AC>;
}

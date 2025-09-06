"use client";
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

import type{Skill}from"./metaLoop";
export const SkillBatteryGuard:Skill={id:"battery-guard",match:e=>e.type==="battery:update"&&typeof e.payload?.level==="number",
run:async(e,ctx)=>{const l=e.payload.level as number;if(l<=15){ctx.policy.set("visuals","dimmed");ctx.policy.set("mediaQuality","low");}
else if(l<=30){ctx.policy.set("visuals","normal");ctx.policy.set("mediaQuality","medium");}
else{ctx.policy.set("visuals","on");ctx.policy.set("mediaQuality","high");}}};
export const SkillAutoFix:Skill={id:"auto-fix",match:e=>e.type.startsWith("error:"),run:async(_e,ctx)=>{const rf=ctx.policy.get("refreshFactor",1);ctx.policy.set("refreshFactor",Math.min(3,rf+0.5));}};
export const SkillTelemetryBoost:Skill={id:"telemetry-boost",match:e=>e.type==="sos:trigger"||e.type==="ritual:tick",run:async(_e,ctx)=>{ctx.policy.set("telemetry.flushNow",true);}};
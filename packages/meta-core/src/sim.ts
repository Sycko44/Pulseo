export type Pred={user:{sos:number;ritual:number;idle:number};risk:{bug:number;perf:number};actions:string[];ts:number};
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

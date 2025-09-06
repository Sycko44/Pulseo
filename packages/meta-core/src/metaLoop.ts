// Boucle Meta-SpiraTech (sense → think → act → learn)
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
    // 1) sense (connecteurs)
    for(const c of this.ctx.connectors.values()){
      if(c.pull){ try{ (await c.pull()).forEach(e=>this.sense(e)); }catch{} }
    }
    // 2) think/act
    const window = this.buf.filter(e=>e.ts> Date.now()-60_000);
    for(const e of window){
      for(const s of this.ctx.skills){ if(s.match(e)){ await s.run(e,this.ctx); } }
    }
    // 3) learn
    const err = window.filter(e=>e.type.startsWith("error:")).length;
    const cur = this.ctx.policy.get("refreshFactor",1);
    if(err>=3 && cur<3) this.ctx.policy.set("refreshFactor", cur+0.25);
    if(err===0 && cur>1) this.ctx.policy.set("refreshFactor", Math.max(1, cur-0.25));
  }
}

export function makeLocalCtx(): MetaCtx{
  const mget=(k:string)=>{ try{ return JSON.parse(localStorage.getItem("meta:"+k) || "null"); }catch{return null;} };
  const mset=(k:string,v:any)=>localStorage.setItem("meta:"+k, JSON.stringify(v));
  const madd=(k:string,v:any)=>{ const a=mget(k)||[]; a.push(v); mset(k,a); };
  const pget=(k:string,def?:any)=>mget("policy:"+k) ?? def;
  const pset=(k:string,v:any)=>mset("policy:"+k,v);
  return {
    emit:(e)=>madd("events", e),
    memory:{ get:mget, set:mset, append:madd },
    policy:{ get:pget, set:pset },
    connectors: new Map(), skills:[]
  };
}


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

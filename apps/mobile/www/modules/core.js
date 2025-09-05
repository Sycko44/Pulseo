export class Core {
  constructor(){
    this.state = JSON.parse(localStorage.getItem('pulseo_state')||'{}');
    this.listeners = new Map();
  }
  save(){
    localStorage.setItem('pulseo_state', JSON.stringify(this.state));
  }
  on(topic, fn){
    if(!this.listeners.has(topic)) this.listeners.set(topic, new Set());
    this.listeners.get(topic).add(fn);
    return () => this.listeners.get(topic).delete(fn);
  }
  emit(topic, payload){
    (this.listeners.get(topic)||[]).forEach(fn=>fn(payload));
  }
  set(ns, key, value){
    if(!this.state[ns]) this.state[ns]={};
    this.state[ns][key]=value;
    this.save();
    this.emit(`${ns}:${key}`, value);
  }
  get(ns, key, fallback=null){
    return this.state?.[ns]?.[key] ?? fallback;
  }
  list(ns){
    return this.state?.[ns] ?? {};
  }
  dump(){ return this.state; }
}


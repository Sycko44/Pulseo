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

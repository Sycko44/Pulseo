"use client";import {useEffect,useState} from"react";
type Pred={user:{sos:number;ritual:number;idle:number};risk:{bug:number;perf:number};actions:string[];ts:number};
export default function SimPage(){const[p,setP]=useState<Pred|null>(null);useEffect(()=>{const t=setInterval(()=>{try{const raw=localStorage.getItem("meta:pred");if(raw)setP(JSON.parse(raw));}catch{}},1000);return()=>clearInterval(t);},[]);
return(<main style={{padding:16,fontFamily:\"Inter,ui-sans-serif\"}}>
<h1>SpiraCore v2 — Auto-Simulation</h1>{!p?<p>En attente…</p>:<div style={{display:\"grid\",gap:8,maxWidth:520}}>
<div><b>User</b> — SOS {(p.user.sos*100).toFixed(1)}% · Ritual {(p.user.ritual*100).toFixed(1)}% · Idle {(p.user.idle*100).toFixed(1)}%</div>
<div><b>Risques</b> — Bug {(p.risk.bug*100).toFixed(1)}% · Perf {(p.risk.perf*100).toFixed(1)}%</div>
<div><b>Actions</b> — {p.actions.join(\", \")||\"—\"}</div><div style={{opacity:.6}}>ts: {new Date(p.ts).toLocaleTimeString()}</div></div>}
<hr/><p>Les prédictions alimentent la policy pour agir avant l’apparition du problème.</p></main>); }
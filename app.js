if ('serviceWorker' in navigator) { window.addEventListener('load', () => { navigator.serviceWorker.register('service-worker.js').catch(()=>{}); }); }
const startBtn = document.getElementById('start'); const consent = document.querySelector('.consent');
startBtn?.addEventListener('click', () => { consent.classList.remove('hidden'); document.getElementById('main').scrollIntoView({behavior:'smooth'}); });
const continueBtn = document.getElementById('continue'); const chatPanel = document.querySelector('.chat');
continueBtn?.addEventListener('click', () => { consent.classList.add('hidden'); chatPanel.classList.remove('hidden'); addMsg('bot','Salut 👋 Je suis Pulseo. Tu peux écrire ici, ou ouvrir ⚙️ pour personnaliser.'); document.getElementById('input')?.focus(); });
const sendBtn = document.getElementById('send'); const input = document.getElementById('input'); const messages = document.getElementById('messages');
sendBtn?.addEventListener('click', send); input?.addEventListener('keydown', (e)=>{ if(e.key==='Enter'){ e.preventDefault(); send(); }});
async function send(){ const text = (input.value||'').trim(); if(!text) return; addMsg('user', text); try{ await saveMessage('user', text);}catch(e){} input.value=''; setTimeout(async()=>{ const reply='Reçu. (PWA complète) Historien enregistre en local, offline supporté.'; addMsg('bot', reply); try{ await saveMessage('bot', reply);}catch(e){} },350); }
function addMsg(role, text){ const div=document.createElement('div'); div.className='msg ' + (role==='bot' ? 'bot':'user'); div.textContent=text; messages.appendChild(div); messages.scrollTop=messages.scrollHeight; }
document.getElementById('openSettings')?.addEventListener('click',()=>{ document.getElementById('settings').classList.remove('hidden'); document.getElementById('settings').focus(); });
document.getElementById('closeSettings')?.addEventListener('click',()=>{ document.getElementById('settings').classList.add('hidden'); });
document.getElementById('openPrivacy')?.addEventListener('click',(e)=>{ e.preventDefault(); document.getElementById('privacy').showModal(); });
document.getElementById('closePrivacy')?.addEventListener('click',()=>{ document.getElementById('privacy').close(); });
document.getElementById('exportRecap')?.addEventListener('click', async (e)=>{ e.preventDefault(); const data=await exportWeeklyRecap(); const blob=new Blob([data],{type:'text/markdown'}); const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download='pulseo_recap_7j.md'; a.click(); });
document.getElementById('pushToggle')?.addEventListener('change', async (e)=>{ if(!('Notification' in window)){ alert('Notifications non supportées.'); e.target.checked=false; return;} const perm=await Notification.requestPermission(); if(perm!=='granted'){ alert('Permission refusée.'); e.target.checked=false; return;} alert('Permission accordée. Abonnement au push à réaliser côté serveur (VAPID).'); });

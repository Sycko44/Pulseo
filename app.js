// ----- Service Worker (enregistré en sécurité)
if ('serviceWorker' in navigator) {
  addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js').catch(() => {});
  });
}

// ----- Mini "router" de vues pour empêcher tout retour involontaire
const VIEWS = ['splash', 'consent', 'chat'];

function show(view) {
  VIEWS.forEach(v => {
    const el = document.querySelector(`[data-view="${v}"]`);
    if (el) el.classList.toggle('hidden', v !== view);
  });
  sessionStorage.setItem('pulseo:view', view);
}

function restoreView() {
  const saved = sessionStorage.getItem('pulseo:view') || 'splash';
  show(saved);
}
restoreView();

// Bloque toute ancre href="#" résiduelle
addEventListener('click', (e) => {
  const a = e.target.closest('a[href="#"]');
  if (a) { e.preventDefault(); e.stopPropagation(); }
});

// Navigation logique
document.getElementById('start')?.addEventListener('click', () => show('consent'));
document.getElementById('continue')?.addEventListener('click', () => {
  show('chat');
  addMsg('bot', 'Salut 👋 Je suis Pulseo. Tu peux écrire ici.');
  document.getElementById('input')?.focus();
});

// ----- Chat (zéro submit, tout en JS)
const input = document.getElementById('input');
const sendBtn = document.getElementById('send');
const messages = document.getElementById('messages');

sendBtn?.addEventListener('click', send);
input?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    send();
  }
});

async function send() {
  const text = (input?.value || '').trim();
  if (!text) return;

  addMsg('user', text);
  try { await saveMessage('user', text); } catch (_) {}

  input.value = '';

  setTimeout(async () => {
    const reply = 'Reçu. (hotfix activé)';
    addMsg('bot', reply);
    try { await saveMessage('bot', reply); } catch (_) {}
  }, 200);

  // Si un script extérieur tente une navigation, on réimpose la vue chat.
  setTimeout(() => show('chat'), 0);
}

function addMsg(role, text) {
  const div = document.createElement('div');
  div.className = 'msg ' + (role === 'bot' ? 'bot' : 'user');
  div.textContent = text;
  messages.appendChild(div);
  messages.scrollTop = messages.scrollHeight;
}
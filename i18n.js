
const dict = {
  fr: {
    title: "Ton coach au rythme de ta vitalité",
    subtitle: "PWA complète (offline, mémoire locale). Conforme CNIL (local-first, opt-in).",
    start: "Commencer",
    privacy_title: "Confidentialité & Options",
    privacy_desc: "Tout est local-first. Active seulement ce que tu souhaites.",
    continue: "Continuer",
    chat_title: "Discussion",
    msg_label: "Message",
    send: "Envoyer",
    settings: "Réglages"
  },
  en: {
    title: "Your coach at your vitality’s rhythm",
    subtitle: "Full PWA (offline, local memory). CNIL-friendly (local-first, opt-in).",
    start: "Start",
    privacy_title: "Privacy & Options",
    privacy_desc: "Everything is local-first. Enable only what you want.",
    continue: "Continue",
    chat_title: "Chat",
    msg_label: "Message",
    send: "Send",
    settings: "Settings"
  }
};
function applyI18n(lang) {
  const d = dict[lang] || dict.fr;
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    if (d[key]) el.textContent = d[key];
  });
}


const DB_NAME = 'pulseo-db';
const DB_VER = 1;
const STORE_MSG = 'messages';
function openDB(){
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VER);
    req.onupgradeneeded = () => {
      const db = req.result;
      if(!db.objectStoreNames.contains(STORE_MSG)){
        db.createObjectStore(STORE_MSG, { keyPath: 'id', autoIncrement: true });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}
async function saveMessage(role, text){
  const db = await openDB();
  return new Promise((res, rej) => {
    const tx = db.transaction(STORE_MSG, 'readwrite');
    tx.objectStore(STORE_MSG).add({ role, text, ts: Date.now() });
    tx.oncomplete = () => res(true);
    tx.onerror = () => rej(tx.error);
  });
}
async function listMessages(){
  const db = await openDB();
  return new Promise((res, rej) => {
    const tx = db.transaction(STORE_MSG, 'readonly');
    const req = tx.objectStore(STORE_MSG).getAll();
    req.onsuccess = () => res(req.result || []);
    req.onerror = () => rej(req.error);
  });
}
async function exportWeeklyRecap(){
  const msgs = await listMessages();
  if(!msgs.length){
    return "Aucun message enregistré.";
  }
  const oneWeek = 7*24*3600*1000;
  const now = Date.now();
  const recent = msgs.filter(m => now - m.ts <= oneWeek);
  const lines = recent.map(m => `${new Date(m.ts).toLocaleString()} [${m.role}] ${m.text}`);
  return ["# Récapitulatif (7 jours)",""].concat(lines).join("\n");
}

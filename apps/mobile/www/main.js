import { Core } from './modules/core.js';
import { mountSante } from './modules/sante.js';
import { mountOndes } from './modules/ondesubversive.js';
import { mountJournal } from './modules/journal.js';

const core = new Core();
window.pulseo = core; // debug

// Tabs
const tabs = document.querySelectorAll('nav.tabs button');
const panels = {
  home: document.getElementById('tab-home'),
  sante: document.getElementById('tab-sante'),
  ondes: document.getElementById('tab-ondes'),
  journal: document.getElementById('tab-journal'),
  settings: document.getElementById('tab-settings')
};
tabs.forEach(btn => btn.addEventListener('click', () => {
  tabs.forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  Object.values(panels).forEach(p=>p.classList.remove('active'));
  const id = btn.dataset.tab;
  panels[id]?.classList.add('active');
}));

// Mount modules
mountSante(panels.sante, core);
mountOndes(panels.ondes, core);
mountJournal(panels.journal, core);

// Settings
document.getElementById('export-data').addEventListener('click', () => {
  const blob = new Blob([JSON.stringify(core.dump(), null, 2)], {type:'application/json'});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'pulseo-export.json';
  a.click();
});


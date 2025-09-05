export function mountJournal(root, core){
  root.innerHTML = `
    <h2>Journal Développeur</h2>
    <div class="card">
      <label>Titre
        <input type="text" id="j-title" placeholder="Ex: Bug écran Santé">
      </label>
      <label>Contenu
        <textarea id="j-body" rows="5" placeholder="Notes, TODO, idées…"></textarea>
      </label>
      <div class="row">
        <button id="j-add">Ajouter</button>
        <button id="j-export">Exporter JSON</button>
        <button id="j-clear">Vider</button>
      </div>
    </div>
    <div class="card">
      <h3>Entrées</h3>
      <div id="j-list"></div>
    </div>
  `;

  const listDiv = root.querySelector('#j-list');
  const render = () => {
    const list = core.get('journal','entries', []);
    if(!list.length){ listDiv.innerHTML = '<small>Pas d’entrées.</small>'; return; }
    listDiv.innerHTML = list.map((e,i)=>`
      <div class="row">
        <div class="cell"><b>${new Date(e.t).toLocaleString()}</b></div>
        <div class="cell">${e.title || '(sans titre)'}</div>
        <div class="cell">${e.body?.slice(0,120) || ''}</div>
        <div class="cell"><button data-i="${i}" class="rm">Supprimer</button></div>
      </div>
    `).join('');
    listDiv.querySelectorAll('button.rm').forEach(b=>b.addEventListener('click', () => {
      const list = core.get('journal','entries', []);
      list.splice(parseInt(b.dataset.i,10),1);
      core.set('journal','entries', list);
      render();
    }));
  };

  root.querySelector('#j-add').addEventListener('click', () => {
    const title = root.querySelector('#j-title').value.trim();
    const body = root.querySelector('#j-body').value.trim();
    const list = core.get('journal','entries', []);
    list.unshift({ t: Date.now(), title, body });
    core.set('journal','entries', list);
    root.querySelector('#j-title').value='';
    root.querySelector('#j-body').value='';
    render();
  });

  root.querySelector('#j-export').addEventListener('click', () => {
    const blob = new Blob([JSON.stringify(core.get('journal','entries', []), null, 2)], {type:'application/json'});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'pulseo-journal.json';
    a.click();
  });

  root.querySelector('#j-clear').addEventListener('click', () => {
    core.set('journal','entries', []);
    render();
  });

  render();
}


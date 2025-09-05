export function mountSante(root, core){
  root.innerHTML = `
    <h2>Pulseo Santé</h2>
    <div class="card">
      <div class="row">
        <div class="cell">
          <label>Fréquence cardiaque (bpm)
            <input type="number" id="in-bpm" min="20" max="240" placeholder="ex: 72">
          </label>
        </div>
        <div class="cell">
          <label>Température (°C)
            <input type="number" id="in-temp" step="0.1" min="30" max="45" placeholder="ex: 36.8">
          </label>
        </div>
        <div class="cell">
          <label>Tension (mmHg)
            <input type="text" id="in-press" placeholder="ex: 120/80">
          </label>
        </div>
      </div>
      <button id="btn-add">Ajouter mesure</button>
    </div>
    <div class="card">
      <h3>Historique</h3>
      <div id="hist"></div>
      <button id="btn-clear">Effacer l'historique</button>
    </div>
  `;

  const histDiv = root.querySelector('#hist');
  const render = () => {
    const list = core.get('sante','measures', []);
    if(!list.length){ histDiv.innerHTML = '<small>Aucune mesure.</small>'; return; }
    histDiv.innerHTML = list.map(m => `
      <div class="row">
        <div class="cell"><b>${new Date(m.t).toLocaleString()}</b></div>
        <div class="cell">BPM: ${m.bpm ?? '-'}</div>
        <div class="cell">Temp: ${m.temp ?? '-'} °C</div>
        <div class="cell">Tension: ${m.press ?? '-'}</div>
      </div>
    `).join('');
  };

  root.querySelector('#btn-add').addEventListener('click', () => {
    const bpm = parseInt(root.querySelector('#in-bpm').value || '0', 10) || null;
    const temp = parseFloat(root.querySelector('#in-temp').value || '') || null;
    const press = root.querySelector('#in-press').value || null;
    const list = core.get('sante','measures', []);
    list.unshift({ t: Date.now(), bpm, temp, press });
    core.set('sante','measures', list);
    render();
  });
  root.querySelector('#btn-clear').addEventListener('click', () => {
    core.set('sante','measures', []);
    render();
  });

  render();
}


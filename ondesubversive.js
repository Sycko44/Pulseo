export function mountOndes(root, core){
  root.innerHTML = `
    <h2>OndeSubversive</h2>
    <div class="card">
      <p>Espace expérimental. Placeholders pour modules “onde”.</p>
      <label>Paramètre alpha
        <input type="number" id="alpha" step="0.1" value="${core.get('ondes','alpha',1)}">
      </label>
      <label>Mode
        <select id="mode">
          <option value="normal">Normal</option>
          <option value="hybride">Hybride</option>
          <option value="reel">Réel</option>
        </select>
      </label>
      <button id="save">Enregistrer</button>
    </div>
    <div class="card">
      <h3>État</h3>
      <pre id="state"></pre>
    </div>
  `;
  const mode = root.querySelector('#mode');
  mode.value = core.get('ondes','mode','normal');
  const state = () => {
    root.querySelector('#state').textContent = JSON.stringify(core.list('ondes'), null, 2);
  };
  root.querySelector('#save').addEventListener('click', () => {
    core.set('ondes','alpha', parseFloat(root.querySelector('#alpha').value||'1')||1);
    core.set('ondes','mode', mode.value);
    state();
  });
  state();
}


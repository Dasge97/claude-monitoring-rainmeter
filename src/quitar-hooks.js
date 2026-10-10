// Quita de %USERPROFILE%\.claude\settings.json los hooks del panel (los que contienen panel-sesiones/hook.js).
// No toca ningún otro hook ni ajuste. Guarda una copia antes de escribir. Lo ejecuta desinstalar.ps1.
// Uso: node quitar-hooks.js [ruta-de-settings.json] [--en-seco]
//   --en-seco: dice qué quitaría, sin escribir nada.
const fs = require('fs');
const os = require('os');
const path = require('path');

const args = process.argv.slice(2);
const enSeco = args.includes('--en-seco');
const ruta = args.find(a => !a.startsWith('--')) || path.join(os.homedir(), '.claude', 'settings.json');

if (!fs.existsSync(ruta)) {
  console.log('No existe', ruta, '- nada que quitar');
  process.exit(0);
}
const s = JSON.parse(fs.readFileSync(ruta, 'utf8'));
const esDelPanel = h => (h && h.command || '').includes('panel-sesiones/hook.js');

let quitados = 0;
if (s.hooks && typeof s.hooks === 'object') {
  for (const ev of Object.keys(s.hooks)) {
    const grupos = s.hooks[ev];
    if (!Array.isArray(grupos)) continue;
    const nuevos = [];
    for (const g of grupos) {
      if (!g || !Array.isArray(g.hooks) || !g.hooks.some(esDelPanel)) {
        nuevos.push(g);
        continue;
      }
      const resto = g.hooks.filter(h => !esDelPanel(h));
      quitados += g.hooks.length - resto.length;
      console.log(`  ${ev}: quitado ${g.hooks.length - resto.length} hook(s) del panel`);
      // El grupo se conserva si le quedan otros hooks; si solo tenía los del panel, se quita entero.
      if (resto.length) nuevos.push({ ...g, hooks: resto });
    }
    if (nuevos.length === grupos.length && nuevos.every((g, i) => g === grupos[i])) continue; // sin cambios
    if (nuevos.length) s.hooks[ev] = nuevos;
    else delete s.hooks[ev];
  }
}

if (!quitados) {
  console.log('No hay hooks del panel en', ruta);
  process.exit(0);
}
if (enSeco) {
  console.log(`En seco: se quitarían ${quitados} hook(s) de ${ruta}. No se ha escrito nada.`);
  process.exit(0);
}
fs.copyFileSync(ruta, ruta + '.antes-de-quitar-panel-sesiones.bak');
const tmp = ruta + '.' + process.pid + '.tmp';
fs.writeFileSync(tmp, JSON.stringify(s, null, 2) + '\n', 'utf8');
fs.renameSync(tmp, ruta);
console.log(`Quitados ${quitados} hook(s) del panel de ${ruta}`);

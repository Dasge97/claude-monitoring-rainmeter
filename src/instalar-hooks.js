// Añade el hook del panel a %USERPROFILE%\.claude\settings.json sin tocar lo que ya hay.
// Lo ejecuta instalar.ps1. Si el hook ya está, actualiza su comando y su timeout. Guarda una copia antes de escribir.
const fs = require('fs');
const os = require('os');
const path = require('path');

const ruta = path.join(os.homedir(), '.claude', 'settings.json');
let s = {};
if (fs.existsSync(ruta)) {
  fs.copyFileSync(ruta, ruta + '.antes-panel-sesiones.bak');
  s = JSON.parse(fs.readFileSync(ruta, 'utf8'));
}
s.hooks = s.hooks || {};

// Ruta completa de node.exe: si Node se acaba de instalar, Claude Code aún no lo tiene en su PATH.
const node = process.execPath.replace(/\\/g, '/');
const script = path.join(__dirname, 'hook.js').replace(/\\/g, '/');
const comando = `"${node}" "${script}"`;
const esDelPanel = h => (h.command || '').includes('panel-sesiones/hook.js');
const eventos = ['SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Notification', 'Stop', 'SessionEnd'];

for (const ev of eventos) {
  s.hooks[ev] = s.hooks[ev] || [];
  const existente = s.hooks[ev].flatMap(g => g.hooks || []).find(esDelPanel);
  if (existente) {
    existente.command = comando;
    existente.timeout = 10;
    continue;
  }
  const grupo = { hooks: [{ type: 'command', command: comando, shell: 'bash', timeout: 10 }] };
  if (ev === 'PreToolUse' || ev === 'PostToolUse') grupo.matcher = '*';
  s.hooks[ev].push(grupo);
}
fs.mkdirSync(path.dirname(ruta), { recursive: true });
fs.writeFileSync(ruta, JSON.stringify(s, null, 2) + '\n', 'utf8');
console.log('Hooks del panel registrados en', ruta);

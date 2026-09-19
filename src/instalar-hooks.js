// Añade el hook del panel a %USERPROFILE%\.claude\settings.json sin tocar lo que ya hay.
// Lo ejecuta instalar.ps1. Si el hook ya está, solo actualiza su timeout. Guarda una copia antes de escribir.
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

const script = path.join(__dirname, 'hook.js').replace(/\\/g, '/');
const comando = `node "${script}"`;
const eventos = ['SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Notification', 'Stop', 'SessionEnd'];

for (const ev of eventos) {
  s.hooks[ev] = s.hooks[ev] || [];
  const existente = s.hooks[ev].flatMap(g => g.hooks || []).find(h => h.command === comando);
  if (existente) {
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

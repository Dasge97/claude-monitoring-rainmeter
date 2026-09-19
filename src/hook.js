// Hook global de Claude Code: guarda el estado de cada sesión para el panel de Rainmeter
// y lanza una notificación de Windows cuando una sesión termina o necesita al usuario.
// Nunca escribe en stdout: en SessionStart y UserPromptSubmit eso se añadiría al contexto de Claude.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const BASE = __dirname;
const DIR_SESIONES = path.join(BASE, 'sesiones');
const PANEL = path.join(BASE, 'panel.txt');
// Lo escribe el interruptor "Avisos" del panel: 0 = solo monitorizar, sin notificaciones. Si no existe, avisa.
const AVISOS = path.join(BASE, 'avisos.txt');
const HORAS_CADUCIDAD = 12;
// Sonidos de los avisos (.wav). Si no existen, la notificación suena con el sonido de Windows. Ver README.
const SONIDO_TERMINADO = 'sonidos/terminado.wav';
const SONIDO_NECESITA = 'sonidos/necesita.wav';

function leerEntrada() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return null;
  }
}

function limpiar(texto, max) {
  const t = String(texto || '').replace(/[\t\r\n]+/g, ' ').trim();
  return t.length > max ? t.slice(0, max - 1) + '…' : t;
}

function describirHerramienta(nombre, entrada) {
  const e = entrada || {};
  const fichero = e.file_path || e.notebook_path;
  switch (nombre) {
    case 'Bash':
    case 'PowerShell':
      return e.description || e.command;
    case 'Edit':
    case 'Write':
    case 'NotebookEdit':
      return 'Editando ' + path.basename(fichero || '');
    case 'Read':
      return 'Leyendo ' + path.basename(fichero || '');
    case 'Grep':
    case 'Glob':
      return 'Buscando ' + (e.pattern || '');
    case 'Agent':
    case 'Task':
      return 'Subagente: ' + (e.description || '');
    case 'WebSearch':
      return 'Buscando en la web: ' + (e.query || '');
    case 'WebFetch':
      return 'Leyendo una web';
    case 'TodoWrite':
      return 'Actualizando la lista de tareas';
    default:
      if (nombre.startsWith('mcp__')) return 'MCP: ' + nombre.split('__').slice(2).join(' ');
      return nombre;
  }
}

// Se espera a que termine: Claude Code mata los procesos hijos del hook al acabar,
// y PowerShell tarda cerca de un segundo en mostrar la notificación.
function notificar(titulo, mensaje, carpeta, sonido) {
  try {
    spawnSync(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
        '-File', path.join(BASE, 'notificar.ps1'),
        '-Titulo', titulo, '-Mensaje', mensaje || ' ', '-Carpeta', carpeta || '',
        '-Sonido', path.join(BASE, sonido)],
      { stdio: 'ignore', windowsHide: true, timeout: 8000 }
    );
  } catch {}
}

function avisosActivados() {
  try {
    return fs.readFileSync(AVISOS, 'utf8').trim() !== '0';
  } catch {
    return true;
  }
}

// true si la ventana que tiene el foco en Windows es la de VS Code con esta carpeta.
function ventanaActiva(carpeta) {
  try {
    const r = spawnSync(path.join(BASE, 'panel-util.exe'), ['activa', carpeta],
      { encoding: 'utf8', windowsHide: true, timeout: 2000 });
    return r.stdout === '1';
  } catch {
    return false;
  }
}

// En Windows el rename falla (EPERM) si otro hook de la misma sesión está escribiendo a la vez
// o si Rainmeter está leyendo panel.txt en ese instante: se reintenta unas cuantas veces.
function escribirAtomico(fichero, contenido) {
  const tmp = fichero + '.' + process.pid + '.tmp';
  fs.writeFileSync(tmp, contenido, 'utf8');
  for (let intento = 0; ; intento++) {
    try {
      fs.renameSync(tmp, fichero);
      return;
    } catch (e) {
      if (intento >= 10) {
        try { fs.unlinkSync(tmp); } catch {}
        throw e;
      }
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 20);
    }
  }
}

// PID del claude.exe que ejecuta este hook (0 si no se encuentra, p. ej. en pruebas).
function pidClaude() {
  try {
    const r = spawnSync(path.join(BASE, 'panel-util.exe'), ['padre', String(process.pid)],
      { encoding: 'utf8', windowsHide: true, timeout: 3000 });
    return parseInt(r.stdout, 10) || 0;
  } catch {
    return 0;
  }
}

function procesoVivo(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (e) {
    return e.code === 'EPERM';
  }
}

// Reúne todas las sesiones en panel.txt, una por línea separada por tabuladores:
// estado, nombre, detalle, segundos desde 1970 del último cambio, carpeta, pid de claude.exe, inicio.
// Borra las sesiones caducadas y las de un claude.exe que ya no existe (ventana de VS Code cerrada).
function regenerarPanel() {
  const ahora = Date.now() / 1000;
  const sesiones = [];
  for (const f of fs.readdirSync(DIR_SESIONES)) {
    if (!f.endsWith('.json')) continue;
    const ruta = path.join(DIR_SESIONES, f);
    try {
      const s = JSON.parse(fs.readFileSync(ruta, 'utf8'));
      if (ahora - s.ts > HORAS_CADUCIDAD * 3600 || (s.pid && !procesoVivo(s.pid))) {
        fs.unlinkSync(ruta);
        continue;
      }
      sesiones.push(s);
    } catch {}
  }
  sesiones.sort((a, b) => a.inicio - b.inicio);

  // Si hay varias sesiones en el mismo proyecto, se distinguen por su primer mensaje
  // o, si aún no lo tienen, por un número de orden.
  const porNombre = {};
  for (const s of sesiones) porNombre[s.nombre] = (porNombre[s.nombre] || 0) + 1;
  const vistos = {};
  const lineas = sesiones.map(s => {
    let nombre = s.nombre;
    if (porNombre[s.nombre] > 1) {
      vistos[s.nombre] = (vistos[s.nombre] || 0) + 1;
      nombre += ' · ' + (s.tema || '#' + vistos[s.nombre]);
    }
    return [s.estado, nombre, s.detalle, Math.floor(s.ts), s.carpeta, s.pid || 0, Math.floor(s.inicio)].join('\t');
  });
  escribirAtomico(PANEL, lineas.join('\n') + '\n');
}

function main() {
  const d = leerEntrada();
  if (!d || !d.session_id) return;
  fs.mkdirSync(DIR_SESIONES, { recursive: true });

  const ruta = path.join(DIR_SESIONES, d.session_id + '.json');
  let s = null;
  try { s = JSON.parse(fs.readFileSync(ruta, 'utf8')); } catch {}
  const carpeta = d.cwd || (s && s.carpeta) || '';
  const ahora = Date.now() / 1000;
  if (!s) s = { inicio: ahora, estado: 'gris', detalle: 'Pausado', ultimoAviso: 0 };
  s.carpeta = carpeta;
  s.nombre = path.basename(carpeta) || 'sesión';
  if (s.pid === undefined) s.pid = pidClaude();

  const anterior = s.estado;
  let aviso = null;

  switch (d.hook_event_name) {
    case 'SessionStart':
      if (d.source === 'compact') return;
      s.estado = 'gris';
      s.detalle = 'Pausado';
      break;
    case 'UserPromptSubmit':
      s.estado = 'amarillo';
      s.detalle = 'Pensando: ' + (d.prompt || '');
      if (!s.tema && d.prompt) s.tema = limpiar(d.prompt, 25);
      break;
    case 'PreToolUse':
      if (d.tool_name === 'AskUserQuestion') {
        s.estado = 'rojo';
        s.detalle = 'Te está haciendo una pregunta';
        aviso = s.detalle;
      } else if (d.tool_name === 'ExitPlanMode') {
        s.estado = 'rojo';
        s.detalle = 'Tiene un plan para que lo revises';
        aviso = s.detalle;
      } else {
        s.estado = 'amarillo';
        s.detalle = describirHerramienta(d.tool_name || '', d.tool_input);
      }
      break;
    case 'PostToolUse':
      s.estado = 'amarillo';
      break;
    case 'Notification': {
      const tipo = d.notification_type || '';
      const mensaje = d.message || '';
      // El aviso de "lleva un rato esperando" no cambia nada: la sesión ya está en verde.
      if (tipo === 'idle_prompt' || /waiting for your input/i.test(mensaje)) return;
      if (tipo === 'auth_success') return;
      s.estado = 'rojo';
      s.detalle = mensaje || 'Necesita tu atención';
      aviso = s.detalle;
      break;
    }
    case 'Stop':
      s.estado = 'verde';
      s.detalle = 'Terminado';
      aviso = d.last_assistant_message || 'Ha terminado';
      break;
    case 'SessionEnd':
      try { fs.unlinkSync(ruta); } catch {}
      regenerarPanel();
      return;
    default:
      return;
  }

  s.detalle = limpiar(s.detalle, 60);
  if (s.estado !== anterior || d.hook_event_name !== 'PostToolUse') s.ts = ahora;
  if (!s.ts) s.ts = ahora;

  // Evita dos avisos seguidos por el mismo motivo (p. ej. PreToolUse de AskUserQuestion + Notification).
  // No se avisa si los avisos están desactivados en el panel,
  // ni si el usuario ya está mirando la ventana de VS Code de esta sesión.
  if (aviso && !(anterior === s.estado && ahora - s.ultimoAviso < 10) && avisosActivados() && !ventanaActiva(carpeta)) {
    s.ultimoAviso = ahora;
    const terminado = s.estado === 'verde';
    const titulo = (terminado ? '✅ ' : '🔴 ') + s.nombre + (terminado ? ' ha terminado' : ' te necesita');
    notificar(titulo, limpiar(aviso, 180), carpeta, terminado ? SONIDO_TERMINADO : SONIDO_NECESITA);
  }

  escribirAtomico(ruta, JSON.stringify(s));
  regenerarPanel();
}

try {
  main();
} catch (e) {
  try { fs.appendFileSync(path.join(BASE, 'errores.log'), new Date().toISOString() + ' ' + (e && e.stack) + '\n'); } catch {}
}
process.exit(0);

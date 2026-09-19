# claude-monitoring-rainmeter

Panel de escritorio para Windows que muestra qué está haciendo cada sesión de Claude Code
(extensión de VS Code o CLI) y avisa con una notificación cuando una sesión termina o te necesita.

Pensado para trabajar con varias ventanas de VS Code a la vez, cada una con su agente.

## Qué hace

- **Panel en Rainmeter**, semitransparente y siempre encima. Una fila por sesión con:
  - un punto de color: amarillo = trabajando, rojo = te necesita (parpadea), verde = ha terminado,
    gris = sin actividad (una sesión terminada pasa a gris a los 10 minutos);
  - el nombre de la carpeta del proyecto;
  - lo que está haciendo ahora mismo (el comando, el fichero que edita, la pregunta que te hace…);
  - hace cuánto cambió.
- Las filas se ordenan por urgencia: primero las rojas.
- Si hay dos sesiones en el mismo proyecto, cada fila muestra el principio de su primer mensaje.
- Clic en una fila: trae al frente la ventana de VS Code de esa sesión.
- **Modo mínimo**: solo los puntos de colores; se despliega al pasar el ratón.
  Se cambia con clic en el título o en el menú del botón derecho.
- **Notificación de Windows** cuando una sesión termina o te necesita, con un sonido distinto para cada caso.
  Al pulsarla se trae al frente la ventana de VS Code de esa sesión.
  No salta si ya tienes delante la ventana de esa sesión.
- Al cerrar una ventana de VS Code, sus sesiones desaparecen del panel en unos 10 segundos.

No hay que hacer nada en cada sesión: los hooks van en la configuración global de Claude Code
y se aplican a todas.

## Requisitos

- Windows 10 u 11.
- [Rainmeter](https://www.rainmeter.net). Por defecto arranca con Windows, así que el panel también.
- [Node.js](https://nodejs.org).
- Claude Code con Git Bash (el que usa Claude Code en Windows).
- .NET Framework 4 (viene con Windows; se usa su compilador de C#).

## Instalación

```powershell
git clone https://github.com/Dasge97/claude-monitoring-rainmeter.git
cd claude-monitoring-rainmeter
powershell -ExecutionPolicy Bypass -File instalar.ps1
```

El instalador:

1. Copia el código a `%USERPROFILE%\.claude\panel-sesiones`.
2. Compila `panel-util.exe` y `enfocar-vscode.exe`.
3. Registra el enlace `panelclaude://` en `HKCU\Software\Classes` (para que la notificación abra la ventana).
4. Añade los hooks a `%USERPROFILE%\.claude\settings.json`. Antes guarda una copia en
   `settings.json.antes-panel-sesiones.bak`. No toca los hooks que ya tengas.
5. Genera la skin `PanelClaude` en la carpeta de skins de Rainmeter y la activa.

Para actualizar después de cambiar algo en `src/`, vuelve a ejecutar `instalar.ps1`.
Las sesiones de Claude Code que ya estaban abiertas pueden necesitar reiniciarse para leer los hooks.

## Sonidos

El repositorio no incluye sonidos. Pon dos ficheros `.wav` en `%USERPROFILE%\.claude\panel-sesiones\sonidos\`
(o en la carpeta `sonidos/` del repositorio antes de instalar):

- `terminado.wav`: cuando una sesión termina.
- `necesita.wav`: cuando una sesión te pide permiso o te hace una pregunta.

Si no están, la notificación sale sin sonido.
Conviene que no tengan silencio al principio, para que suenen a la vez que aparece la notificación.
Páginas para buscar sonidos: [Mixkit](https://mixkit.co/free-sound-effects/), [Pixabay](https://pixabay.com/sound-effects/),
[Myinstants](https://www.myinstants.com).

## Cómo funciona

```
Claude Code ──(hooks)──> hook.js ──> sesiones/<id>.json ──> panel.txt ──> Rainmeter (panel.lua)
                            │
                            └──> notificar.ps1 ──> notificación de Windows + sonido
```

- `hook.js` se ejecuta en cada evento de cada sesión (`SessionStart`, `UserPromptSubmit`, `PreToolUse`,
  `PostToolUse`, `Notification`, `Stop`, `SessionEnd`). Guarda el estado de la sesión en `sesiones/<id>.json`
  y reescribe `panel.txt` con todas las sesiones, una por línea.
- `panel.lua` (script de la skin) lee `panel.txt` cada medio segundo y pinta las filas.
- `panel-util.exe` hace tres consultas que no se pueden hacer desde Rainmeter ni desde Node sin dependencias:
  - `padre <pid>`: qué `claude.exe` ha lanzado el hook (para saber cuándo se cierra la sesión);
  - `pids`: qué `claude.exe` siguen vivos (el panel lo consulta cada 10 segundos);
  - `activa <carpeta>`: si la ventana con el foco es la de VS Code de esa carpeta.
- `enfocar-vscode.exe` busca la ventana de VS Code por su título (`… - <carpeta> - Visual Studio Code`)
  y la trae al frente. Si no la encuentra, la abre con `code`.

Detalles que costó descubrir:

- Rainmeter solo muestra bien los acentos si el `.ini` y el `.lua` están en UTF-16 LE.
  Por eso el original de `panel.lua` está en UTF-8 y `generar-skin.js` copia a la skin una versión convertida.
- Claude Code mata los procesos hijos del hook cuando el hook termina.
  Por eso el hook espera a que la notificación y el sonido acaben.
- Abrir `vscode://file/...` hace que VS Code pida confirmación. Por eso se usa `enfocar-vscode.exe`.

## Desinstalar

1. En Rainmeter, descarga la skin `PanelClaude` y borra su carpeta de skins.
2. Quita de `%USERPROFILE%\.claude\settings.json` los hooks cuyo comando contiene `panel-sesiones/hook.js`.
3. Borra `%USERPROFILE%\.claude\panel-sesiones` y la clave `HKCU\Software\Classes\panelclaude`.

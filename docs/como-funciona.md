# Cómo funciona por dentro

[← Volver al README](../README.es.md) · [English](how-it-works.md)

## Esquema

```
Claude Code ──(hooks)──> hook.js ──> sesiones/<id>.json ──> panel.txt ──> Rainmeter (panel.lua)
                            │
                            ├──> panel-util.exe      (qué claude.exe es, ¿está viva?, ¿ventana activa?)
                            └──> notificar.ps1 ──> notificación de Windows + sonido
                                        │
                                        └── al pulsarla: panelclaude:// ──> enfocar-vscode.exe
```

## Piezas

Todo se instala en `%USERPROFILE%\.claude\panel-sesiones`, salvo la skin, que va a la carpeta de skins de Rainmeter.

| Fichero | Qué hace |
|---|---|
| `hook.js` | Se ejecuta en cada evento de cada sesión de Claude Code. Guarda el estado de la sesión en `sesiones/<id>.json` y reescribe `panel.txt` con todas las sesiones. Decide cuándo avisar. |
| `notificar.ps1` | Muestra la notificación de Windows y reproduce el sonido. |
| `panel-util.exe` | Consultas de procesos y ventanas que no se pueden hacer desde Rainmeter ni desde Node sin dependencias. |
| `enfocar-vscode.exe` | Trae al frente la ventana de VS Code de una carpeta. |
| `panel.lua` | Script de la skin de Rainmeter. Lee `panel.txt` cada medio segundo y pinta las filas. |
| `generar-skin.js` | Genera `PanelClaude.ini` y copia `panel.lua` a la skin. |
| `instalar-hooks.js` | Añade los hooks a `%USERPROFILE%\.claude\settings.json` sin tocar los que ya hay. |

## Eventos de Claude Code que se usan

| Evento | Estado en el panel | Aviso |
|---|---|---|
| `SessionStart` | gris, "Pausado" | — |
| `UserPromptSubmit` | amarillo, "Pensando: <tu mensaje>" | — |
| `PreToolUse` | amarillo, con lo que va a hacer (comando, fichero, búsqueda…) | — |
| `PreToolUse` de `AskUserQuestion` o `ExitPlanMode` | rojo, "Te está haciendo una pregunta" / "Tiene un plan…" | sí |
| `PostToolUse` | amarillo | — |
| `Notification` (permiso, pregunta) | rojo, con el mensaje de Claude Code | sí |
| `Stop` | verde, "Terminado" | sí, con el último mensaje de Claude |
| `SessionEnd` | se quita del panel | — |

El aviso de "lleva un rato esperando" (`idle_prompt`) se ignora: la sesión ya está en verde.

Una sesión en verde pasa a gris, "Pausado", a los 10 minutos. Ese cambio lo hace `panel.lua` al pintar;
no hay ningún evento de Claude Code detrás.

## Formato de `panel.txt`

Una sesión por línea, campos separados por tabuladores:

```
estado  nombre  detalle  último_cambio  carpeta  pid_de_claude.exe  inicio
```

Las fechas son segundos desde 1970 (UTC). Si hay varias sesiones en la misma carpeta, el nombre lleva
el principio del primer mensaje de cada una (`web-tienda · arregla el login…`).

## `panel-util.exe`

| Comando | Devuelve | Para qué |
|---|---|---|
| `padre <pid>` | PID del `claude.exe` antecesor | El hook lo guarda en la sesión la primera vez. |
| `pids` | PIDs de los `claude.exe` vivos (`,12,34,`) | El panel lo pide cada 10 s y oculta las sesiones cuyo proceso ya no existe. |
| `activa <carpeta>` | `1` o `0` | Si la ventana con el foco es la de VS Code de esa carpeta, no se avisa. |

## Encontrar la ventana de VS Code

VS Code titula sus ventanas `<fichero> - <carpeta> - Visual Studio Code` (o `<carpeta> - Visual Studio Code`).
`enfocar-vscode.exe` recorre las ventanas visibles, busca la de esa carpeta y la trae al frente.
Si no hay ninguna, abre la carpeta con `code`.

Se registra el enlace `panelclaude://` en `HKCU\Software\Classes\panelclaude` para que la notificación
pueda llamar a `enfocar-vscode.exe` al pulsarla.

## Detalles que costó descubrir

- **Acentos en Rainmeter.** Rainmeter solo muestra bien los acentos si el `.ini` y el `.lua` están en UTF-16 LE.
  El original de `panel.lua` está en UTF-8 y `generar-skin.js` copia a la skin una versión convertida.
- **Procesos hijos del hook.** Claude Code mata los procesos que lanza el hook cuando el hook termina.
  Por eso el hook espera a que la notificación y el sonido acaben, y el timeout del hook es de 10 s.
- **`vscode://file/...`** hace que VS Code pida confirmación. Por eso se usa `enfocar-vscode.exe`.
- **Sonido a tiempo.** El `.wav` se carga antes de mostrar la notificación y se reproduce con `SoundPlayer`,
  que arranca sin retraso. Conviene que el `.wav` no tenga silencio al principio.
- **Escrituras a la vez.** Cuando Claude lanza varias herramientas en paralelo, varios hooks de la misma sesión
  escriben a la vez y Windows rechaza el `rename`. El hook reintenta hasta 10 veces.
- **Ventana cerrada de golpe.** Al cerrar VS Code, `claude.exe` muere sin lanzar `SessionEnd`.
  Por eso se guarda su PID y el panel comprueba cada 10 s cuáles siguen vivos.
- **Node recién instalado.** El hook se registra con la ruta completa de `node.exe`, porque una sesión de
  Claude Code abierta antes de instalar Node no lo encontraría en su PATH.

## Rendimiento

Cada evento lanza un proceso de Node corto: unos 50-60 ms en un PC normal. Solo los avisos
(fin de sesión o petición de permiso) esperan un par de segundos más, mientras suena el sonido.

## Desinstalar

1. En Rainmeter, descarga la skin `PanelClaude` y borra su carpeta de skins.
2. Quita de `%USERPROFILE%\.claude\settings.json` los hooks cuyo comando contiene `panel-sesiones/hook.js`.
   El instalador dejó una copia de antes en `settings.json.antes-panel-sesiones.bak`.
3. Borra `%USERPROFILE%\.claude\panel-sesiones` y la clave `HKCU\Software\Classes\panelclaude`.

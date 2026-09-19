# How it works

[← Back to the README](../README.md) · [Español](como-funciona.md)

## Overview

```
Claude Code ──(hooks)──> hook.js ──> sesiones/<id>.json ──> panel.txt ──> Rainmeter (panel.lua)
                            │
                            ├──> panel-util.exe      (which claude.exe, is it alive?, active window?)
                            └──> notificar.ps1 ──> Windows notification + sound
                                        │
                                        └── on click: panelclaude:// ──> enfocar-vscode.exe
```

## Parts

Everything is installed in `%USERPROFILE%\.claude\panel-sesiones`, except the skin, which goes to Rainmeter's skins folder.
File names are in Spanish.

| File | What it does |
|---|---|
| `hook.js` | Runs on every event of every Claude Code session. Saves the session state to `sesiones/<id>.json` and rewrites `panel.txt` with all sessions. Decides when to notify. |
| `notificar.ps1` | Shows the Windows notification and plays the sound. |
| `panel-util.exe` | Process and window queries that Rainmeter and dependency-free Node.js cannot do. |
| `enfocar-vscode.exe` | Brings a folder's VS Code window to the front. |
| `panel.lua` | Rainmeter skin script. Reads `panel.txt` every half second and draws the rows. |
| `generar-skin.js` | Generates `PanelClaude.ini` and copies `panel.lua` into the skin. |
| `avisos.txt` | Written by the panel's *Avisos* switch: `1` notifies, `0` only monitors. If missing, notifications are on. `hook.js` reads it before each notification. |
| `instalar-hooks.js` | Adds the hooks to `%USERPROFILE%\.claude\settings.json` without touching existing ones. |

## Claude Code events used

| Event | Panel status | Notification |
|---|---|---|
| `SessionStart` | grey, "Pausado" | — |
| `UserPromptSubmit` | yellow, "Pensando: <your message>" | — |
| `PreToolUse` | yellow, with what it is about to do (command, file, search…) | — |
| `PreToolUse` for `AskUserQuestion` or `ExitPlanMode` | red, it is asking a question / has a plan | yes |
| `PostToolUse` | yellow | — |
| `Notification` (permission, question) | red, with Claude Code's message | yes |
| `Stop` | green, "Terminado" | yes, with Claude's last message |
| `SessionEnd` | removed from the panel | — |

The "waiting for your input" reminder (`idle_prompt`) is ignored: the session is already green.

A green session turns grey, "Pausado", after 10 minutes. `panel.lua` does this when drawing;
there is no Claude Code event behind it.

## `panel.txt` format

One session per line, tab-separated fields:

```
status  name  detail  last_change  folder  claude.exe_pid  start
```

Times are seconds since 1970 (UTC). When several sessions share a folder, the name includes
the beginning of each session's first message (`web-tienda · arregla el login…`).

## `panel-util.exe`

| Command | Returns | Used for |
|---|---|---|
| `padre <pid>` | PID of the ancestor `claude.exe` | The hook stores it in the session the first time. |
| `pids` | PIDs of the running `claude.exe` processes (`,12,34,`) | The panel asks every 10 s and hides sessions whose process is gone. |
| `activa <folder>` | `1` or `0` | If the focused window is that folder's VS Code window, no notification. |

## Finding the VS Code window

VS Code titles its windows `<file> - <folder> - Visual Studio Code` (or `<folder> - Visual Studio Code`).
`enfocar-vscode.exe` goes through the visible windows, finds the one for that folder and brings it to the front.
If there is none, it opens the folder with `code`.

The `panelclaude://` link is registered in `HKCU\Software\Classes\panelclaude` so the notification
can call `enfocar-vscode.exe` when clicked.

## Things that took a while to figure out

- **Accents in Rainmeter.** Rainmeter only shows accented characters correctly if the `.ini` and `.lua` files are UTF-16 LE.
  The source `panel.lua` is UTF-8 and `generar-skin.js` copies a converted version into the skin.
- **Hook child processes.** Claude Code kills the processes started by a hook when the hook ends.
  That is why the hook waits for the notification and the sound to finish, and the hook timeout is 10 s.
- **`vscode://file/...`** makes VS Code ask for confirmation. That is why `enfocar-vscode.exe` exists.
- **Sound timing.** The `.wav` is loaded before the notification is shown and played with `SoundPlayer`,
  which starts without delay. The `.wav` should have no silence at the start.
- **Concurrent writes.** When Claude runs several tools in parallel, several hooks of the same session
  write at once and Windows rejects the `rename`. The hook retries up to 10 times.
- **Window closed abruptly.** When VS Code closes, `claude.exe` dies without firing `SessionEnd`.
  That is why its PID is stored and the panel checks every 10 s which ones are still alive.
- **Freshly installed Node.js.** The hook is registered with the full path to `node.exe`, because a Claude Code
  session opened before Node.js was installed would not find it in its PATH.

## Performance

Each event starts a short Node.js process: about 50-60 ms on a normal PC. Only notifications
(session finished or permission request) take a couple of seconds longer, while the sound plays.

## Uninstall

1. In Rainmeter, unload the `PanelClaude` skin and delete its folder in the skins folder.
2. Remove from `%USERPROFILE%\.claude\settings.json` the hooks whose command contains `panel-sesiones/hook.js`.
   The installer left a copy of the previous file in `settings.json.antes-panel-sesiones.bak`.
3. Delete `%USERPROFILE%\.claude\panel-sesiones` and the `HKCU\Software\Classes\panelclaude` key.

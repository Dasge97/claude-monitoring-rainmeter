<div align="center">

# Claude Monitoring for Rainmeter

A desktop panel for Windows that shows what each Claude Code session is doing<br>
and notifies you when one finishes or needs your input.

**English** · [Español](README.es.md)

[![Version](https://img.shields.io/badge/version-1.0.0-2ea44f)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)
[![Windows 10 | 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)](#installation)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-hooks-D97757?logo=claude&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![Rainmeter](https://img.shields.io/badge/Rainmeter-skin-19A2E0?logo=rainmeter&logoColor=white)](https://www.rainmeter.net)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Install](https://img.shields.io/badge/install-double%20click-brightgreen)](#installation)
[![Last commit](https://img.shields.io/github/last-commit/Dasge97/claude-monitoring-rainmeter)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)

<img src="docs/img/portada.png" alt="Desktop with three VS Code windows running Claude Code. Top right, the panel with five sessions: one red waiting for permission, two yellow working, one green finished and one grey paused. Bottom right, a notification saying web-tienda has finished." width="100%">

[![Install](https://img.shields.io/badge/Install-2ea44f?style=for-the-badge)](#installation)
&nbsp;
[![How it works](https://img.shields.io/badge/How%20it%20works-555?style=for-the-badge)](docs/how-it-works.md)

</div>

## Why

If you run Claude Code in several VS Code windows at once, you end up switching between them to check
which one has finished, which one is waiting for a permission and which one is still working.
This panel puts that information in one place, on top of your other windows.

## Features

- One row per session: a status colour, the project folder and what it is doing right now
  (the command it runs, the file it edits, the question it asks).
- Sessions that need you are listed first and blink.
- A Windows notification when a session finishes or needs you, with a different sound for each case.
  No notification if you are already looking at that window.
- Click a row or a notification to bring that session's VS Code window to the front.
- Semi-transparent and always on top; opaque when the mouse is over it. A compact mode shows only the dots.
- Sessions disappear from the panel when you close their VS Code window.
- Works for every session in every project once installed. Nothing to set up per session.

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/img/panel-completo.png" alt="Panel with five Claude Code sessions in different states" width="380"><br><sub>Full mode</sub></td>
<td align="center"><img src="docs/img/notificacion.png" alt="Windows notification: web-tienda has finished" width="370"><br><sub>Notification with Claude's last message</sub></td>
<td align="center"><img src="docs/img/panel-minimo.png" alt="Compact mode: a row of coloured dots" width="124"><br><sub>Compact mode</sub></td>
</tr>
</table>
</div>

## Status colours

| | Status | When |
|:-:|---|---|
| 🔴 | Needs you | It asks for permission to use a tool, asks you a question or has a plan for you to review. Blinks. |
| 🟡 | Working | It is thinking or using a tool. |
| 🟢 | Finished | It has just replied. Stays green for 10 minutes. |
| ⚪ | Paused | No recent activity: it finished more than 10 minutes ago, or it is open and has not been used yet. |

## Installation

```powershell
git clone https://github.com/Dasge97/claude-monitoring-rainmeter.git
```

Then double-click `Instalar.cmd`. You can also use **Code → Download ZIP**, unzip it and double-click `Instalar.cmd`.

If [Rainmeter](https://www.rainmeter.net), [Node.js](https://nodejs.org) or [Git for Windows](https://git-scm.com/download/win)
is missing, the installer installs it with `winget`, or with the official installer if `winget` is not available.
Windows asks for administrator permission for each one. Git for Windows is needed because Claude Code runs hooks in Git Bash.

To update: `git pull` and double-click `Instalar.cmd` again. Your sounds and panel settings are kept.

> **Language.** The panel and the notifications are currently in Spanish.

## Customisation

**Sounds.** Put two `.wav` files in `%USERPROFILE%\.claude\panel-sesiones\sonidos\`:
`terminado.wav` (finished) and `necesita.wav` (needs you). Without them, the default Windows sound plays.
Short sounds with no silence at the start work best.

**Full or compact mode.** Click the panel title, or right-click → *Cambiar modo*.

**Position.** Drag the panel anywhere on the screen. It stays there.

## FAQ

<details>
<summary><b>Does it slow down Claude Code?</b></summary>

Each event starts a short Node.js process, about 50-60 ms.
Notifications take a couple of seconds longer while the sound plays; at that point Claude has finished or is waiting for you anyway.
</details>

<details>
<summary><b>Does it work with Claude Code in the terminal?</b></summary>

Yes. The panel and the notifications work with any Claude Code session.
Only the click that brings the window to the front is specific to VS Code.
</details>

<details>
<summary><b>What does it change on my system?</b></summary>

- It adds hooks to `%USERPROFILE%\.claude\settings.json` without touching the ones you already have. It saves a backup first.
- It copies its files to `%USERPROFILE%\.claude\panel-sesiones`.
- It creates the `PanelClaude` skin in Rainmeter.
- It registers the `panelclaude://` link for your user, so notifications can open the window.

Nothing is sent outside your PC.
</details>

<details>
<summary><b>How do I uninstall it?</b></summary>

See [How it works → Uninstall](docs/how-it-works.md#uninstall).
</details>

---

<div align="center">

[How it works](docs/how-it-works.md) · [Cómo funciona](docs/como-funciona.md) · [Español](README.es.md)

</div>

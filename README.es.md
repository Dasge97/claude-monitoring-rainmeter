<div align="center">

# Claude Monitoring para Rainmeter

Un panel de escritorio para Windows que muestra qué está haciendo cada sesión de Claude Code<br>
y te avisa cuando una termina o necesita que respondas.

[English](README.md) · **Español**

[![Versión](https://img.shields.io/badge/versi%C3%B3n-1.0.0-2ea44f)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)
[![Windows 10 | 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)](#instalación)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-hooks-D97757?logo=claude&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![Rainmeter](https://img.shields.io/badge/Rainmeter-skin-19A2E0?logo=rainmeter&logoColor=white)](https://www.rainmeter.net)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Instalación](https://img.shields.io/badge/instalaci%C3%B3n-doble%20clic-brightgreen)](#instalación)
[![Último cambio](https://img.shields.io/github/last-commit/Dasge97/claude-monitoring-rainmeter?label=%C3%BAltimo%20cambio)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)

<img src="docs/img/portada.png" alt="Escritorio con tres ventanas de VS Code con Claude Code. Arriba a la derecha, el panel con cinco sesiones: una en rojo esperando permiso, dos en amarillo trabajando, una en verde terminada y una en gris pausada. Abajo a la derecha, la notificación de que web-tienda ha terminado." width="100%">

[![Instalar](https://img.shields.io/badge/Instalar-2ea44f?style=for-the-badge)](#instalación)
&nbsp;
[![Cómo funciona](https://img.shields.io/badge/C%C3%B3mo%20funciona-555?style=for-the-badge)](docs/como-funciona.md)

</div>

## Para qué sirve

Si usas Claude Code en varias ventanas de VS Code a la vez, acabas saltando entre ellas para ver
cuál ha terminado, cuál está esperando un permiso y cuál sigue trabajando.
Este panel reúne esa información en un solo sitio, encima del resto de ventanas.

## Qué hace

- Una fila por sesión: un color de estado, la carpeta del proyecto y lo que está haciendo en ese momento
  (el comando que ejecuta, el fichero que edita, la pregunta que te hace).
- Las sesiones que te necesitan salen las primeras y parpadean.
- Una notificación de Windows cuando una sesión termina o te necesita, con un sonido distinto para cada caso.
  No avisa si ya estás mirando esa ventana.
- Un interruptor en el título del panel apaga las notificaciones, para cuando solo quieres ver el estado.
- Al pulsar una fila o una notificación, se pone delante la ventana de VS Code de esa sesión.
- Semitransparente y siempre encima; opaco al pasar el ratón. Tiene un modo mínimo que solo muestra los puntos.
- Al cerrar una ventana de VS Code, sus sesiones desaparecen del panel.
- Funciona con todas las sesiones de todos los proyectos desde que se instala. No hay que configurar nada en cada sesión.

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/img/panel-completo.png" alt="Panel con cinco sesiones de Claude Code en distintos estados, dos de ellas en el mismo proyecto" width="440"><br><sub>Modo completo</sub></td>
<td align="center"><img src="docs/img/notificacion.png" alt="Notificación de Windows: web-tienda ha terminado" width="370"><br><sub>Notificación con el último mensaje de Claude</sub></td>
<td align="center"><img src="docs/img/panel-minimo.png" alt="Modo mínimo: una fila de puntos de colores" width="124"><br><sub>Modo mínimo</sub></td>
</tr>
</table>
</div>

## Colores

| | Estado | Cuándo |
|:-:|---|---|
| 🔴 | Te necesita | Pide permiso para usar una herramienta, te hace una pregunta o tiene un plan para que lo revises. Parpadea. |
| 🟡 | Trabajando | Está pensando o usando una herramienta. |
| 🟢 | Terminado | Acaba de responder. Se queda en verde 10 minutos. |
| ⚪ | Pausado | Sin actividad reciente: terminó hace más de 10 minutos, o está abierta y aún no se ha usado. |

## Instalación

```powershell
git clone https://github.com/Dasge97/claude-monitoring-rainmeter.git
```

Después, doble clic en `Instalar.cmd`. También puedes usar **Code → Download ZIP**, descomprimirlo y hacer doble clic en `Instalar.cmd`.

Si falta [Rainmeter](https://www.rainmeter.net), [Node.js](https://nodejs.org) o [Git para Windows](https://git-scm.com/download/win),
el instalador lo instala con `winget`, o con el instalador oficial si no hay `winget`.
Windows pide permiso de administrador para cada uno. Git para Windows hace falta porque Claude Code ejecuta los hooks en Git Bash.

Para actualizar: `git pull` y otra vez doble clic en `Instalar.cmd`. Se conservan tus sonidos y los ajustes del panel.

## Personalizar

**Sonidos.** Pon dos ficheros `.wav` en `%USERPROFILE%\.claude\panel-sesiones\sonidos\`:
`terminado.wav` y `necesita.wav`. Sin ellos suena el aviso normal de Windows.
Funcionan mejor los sonidos cortos y sin silencio al principio.

**Solo monitorizar.** Pulsa el interruptor *Avisos*, arriba a la derecha del panel. Verde: avisos activados.
Gris: el panel se sigue actualizando, sin notificaciones ni sonidos. Se conserva al reiniciar.

**Modo completo o mínimo.** Clic en el título del panel, o botón derecho → *Cambiar modo*.

**Posición.** Arrastra el panel a cualquier sitio de la pantalla. Se queda ahí.

## Preguntas frecuentes

<details>
<summary><b>¿Ralentiza a Claude Code?</b></summary>

Cada evento lanza un proceso corto de Node.js, de unos 50-60 ms.
Los avisos tardan un par de segundos más mientras suena el sonido; en ese momento Claude ya ha terminado o está esperando tu respuesta.
</details>

<details>
<summary><b>¿Funciona con Claude Code en la terminal?</b></summary>

Sí. El panel y las notificaciones funcionan con cualquier sesión de Claude Code.
Lo único propio de VS Code es el clic que pone su ventana delante.
</details>

<details>
<summary><b>¿Qué cambia en mi sistema?</b></summary>

- Añade hooks a `%USERPROFILE%\.claude\settings.json` sin tocar los que ya tengas. Antes guarda una copia.
- Copia sus ficheros en `%USERPROFILE%\.claude\panel-sesiones`.
- Crea la skin `PanelClaude` en Rainmeter.
- Registra el enlace `panelclaude://` para tu usuario, para que las notificaciones puedan abrir la ventana.

No envía nada fuera de tu PC.
</details>

<details>
<summary><b>¿Cómo lo desinstalo?</b></summary>

Ver [Cómo funciona → Desinstalar](docs/como-funciona.md#desinstalar).
</details>

---

<div align="center">

[Cómo funciona](docs/como-funciona.md) · [How it works](docs/how-it-works.md) · [English](README.md)

</div>

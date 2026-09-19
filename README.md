<div align="center">

# Claude Monitoring para Rainmeter

**Todas tus sesiones de Claude Code, en un vistazo.**<br>
Un panel discreto en el escritorio que te dice qué agente está trabajando, cuál ha terminado y cuál te está esperando.

[![Versión](https://img.shields.io/badge/versi%C3%B3n-1.0.0-2ea44f)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)
[![Windows 10 | 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)](#instalación)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-hooks-D97757?logo=claude&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![Rainmeter](https://img.shields.io/badge/Rainmeter-skin-19A2E0?logo=rainmeter&logoColor=white)](https://www.rainmeter.net)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Instalación](https://img.shields.io/badge/instalaci%C3%B3n-doble%20clic-brightgreen)](#instalación)
[![Último commit](https://img.shields.io/github/last-commit/Dasge97/claude-monitoring-rainmeter?label=%C3%BAltimo%20cambio)](https://github.com/Dasge97/claude-monitoring-rainmeter/commits/main)

<img src="docs/img/portada.png" alt="Escritorio con tres ventanas de VS Code con Claude Code. Arriba a la derecha, el panel con cinco sesiones: una en rojo esperando permiso, dos en amarillo trabajando, una en verde terminada y una en gris. Abajo a la derecha, la notificación de que web-tienda ha terminado." width="100%">

[![Instalar](https://img.shields.io/badge/Instalar-en%201%20minuto-2ea44f?style=for-the-badge)](#instalación)
&nbsp;
[![Cómo funciona por dentro](https://img.shields.io/badge/C%C3%B3mo%20funciona-por%20dentro-555?style=for-the-badge)](docs/como-funciona.md)

</div>

---

## ¿Trabajas con varios agentes a la vez?

Tienes tres o cuatro ventanas de VS Code abiertas, cada una con Claude Code haciendo algo.
Y te pasas el día saltando entre ellas para ver cuál ha terminado, cuál se ha quedado esperando
un permiso desde hace diez minutos y cuál sigue trabajando.

**Claude Monitoring te lo dice sin que tengas que mirar.**

## Lo que hace

🚦 **Un semáforo por sesión.** Amarillo si está trabajando, rojo si te necesita, verde si ha terminado.

👀 **Qué está haciendo, en directo.** El comando que ejecuta, el fichero que edita o la pregunta que te hace.

🔴 **Lo urgente, arriba.** Las sesiones que te esperan suben las primeras y parpadean hasta que las atiendes.

🔔 **Te avisa cuando acaba o te necesita.** Notificación de Windows con tu propio sonido, uno distinto para cada caso.
Y no te molesta si ya estás mirando esa ventana.

🖱️ **Un clic y estás allí.** Pulsa una fila o una notificación y se pone delante la ventana de VS Code de esa sesión.

🪶 **Discreto.** Semitransparente, siempre encima y opaco solo cuando pasas el ratón.
Con un modo mínimo que se queda en una fila de puntos.

🧹 **Se limpia solo.** Cierras una ventana de VS Code y sus sesiones desaparecen del panel.

⚙️ **Sin configurar nada en cada sesión.** Funciona con todas tus sesiones, en todos tus proyectos, desde que lo instalas.

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/img/panel-completo.png" alt="Panel con cinco sesiones de Claude Code en distintos estados" width="380"><br><sub>Modo completo</sub></td>
<td align="center"><img src="docs/img/notificacion.png" alt="Notificación de Windows: web-tienda ha terminado" width="370"><br><sub>Aviso al terminar, con el último mensaje de Claude</sub></td>
<td align="center"><img src="docs/img/panel-minimo.png" alt="Modo mínimo: una fila de puntos de colores" width="124"><br><sub>Modo mínimo</sub></td>
</tr>
</table>
</div>

## El semáforo

| | Estado | Cuándo |
|:-:|---|---|
| 🔴 | **Te necesita** | Pide permiso para una herramienta, te hace una pregunta o tiene un plan para que lo revises. Parpadea. |
| 🟡 | **Trabajando** | Está pensando o usando una herramienta. |
| 🟢 | **Ha terminado** | Acaba de responder. Se queda en verde 10 minutos. |
| ⚪ | **En espera** | Sesión abierta sin actividad reciente. |

## Instalación

```powershell
git clone https://github.com/Dasge97/claude-monitoring-rainmeter.git
```

Y **doble clic en `Instalar.cmd`**. Eso es todo.

También vale descargar el repositorio con **Code → Download ZIP**, descomprimirlo y hacer doble clic en `Instalar.cmd`.

> Si te falta [Rainmeter](https://www.rainmeter.net), [Node.js](https://nodejs.org) o
> [Git para Windows](https://git-scm.com/download/win), el instalador los instala por ti.
> Windows te pedirá permiso de administrador para cada uno.

Para actualizar, `git pull` y otra vez doble clic en `Instalar.cmd`. Tus sonidos y tus ajustes se conservan.

## Hazlo tuyo

**🔊 Tus sonidos.** Pon dos ficheros `.wav` en `%USERPROFILE%\.claude\panel-sesiones\sonidos\`:
`terminado.wav` y `necesita.wav`. Sin ellos suena el aviso normal de Windows.
Ideas en [Myinstants](https://www.myinstants.com), [Mixkit](https://mixkit.co/free-sound-effects/) o [Pixabay](https://pixabay.com/sound-effects/).

**📐 Modo completo o mínimo.** Clic en el título del panel, o botón derecho → *Cambiar modo*.

**📍 Donde quieras.** Arrastra el panel a cualquier sitio de la pantalla. Se queda ahí.

## Preguntas frecuentes

<details>
<summary><b>¿Ralentiza a Claude Code?</b></summary>

No se nota. Cada evento lanza un proceso muy corto, de unos 50-60 ms.
Solo los avisos esperan un par de segundos más, mientras suena el sonido.
En ese momento Claude está parado igualmente: ha terminado o está esperando tu permiso.
</details>

<details>
<summary><b>¿Funciona con Claude Code en la terminal?</b></summary>

Sí. El panel y las notificaciones funcionan con cualquier sesión de Claude Code.
Lo único exclusivo de VS Code es el clic para traer su ventana al frente.
</details>

<details>
<summary><b>¿Qué toca de mi sistema?</b></summary>

- Añade unos hooks a `%USERPROFILE%\.claude\settings.json`, sin tocar los que ya tengas. Antes guarda una copia.
- Copia sus ficheros en `%USERPROFILE%\.claude\panel-sesiones`.
- Crea la skin `PanelClaude` en Rainmeter.
- Registra el enlace `panelclaude://` para tu usuario, para que las notificaciones abran la ventana.

Nada se envía fuera de tu PC.
</details>

<details>
<summary><b>¿Cómo lo desinstalo?</b></summary>

Los pasos están en [Cómo funciona por dentro → Desinstalar](docs/como-funciona.md#desinstalar).
</details>

---

<div align="center">

**¿Quieres saber cómo está hecho?**

[![Cómo funciona por dentro](https://img.shields.io/badge/Leer-C%C3%B3mo%20funciona%20por%20dentro-555?style=for-the-badge)](docs/como-funciona.md)

<sub>Hecho para trabajar con varios agentes de Claude Code a la vez sin perder el hilo.</sub>

</div>

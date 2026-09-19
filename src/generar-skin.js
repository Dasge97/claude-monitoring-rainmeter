// Genera la skin de Rainmeter PanelClaude.ini con las filas repetidas y copia panel.lua a la skin en UTF-16 LE.
// Rainmeter solo lee bien los acentos en los .ini y .lua si están en UTF-16 LE.
// Uso: node generar-skin.js   (lo ejecuta instalar.ps1; después, en Rainmeter: Refresh de la skin PanelClaude)
// Se ejecuta desde la carpeta de instalación (%USERPROFILE%\.claude\panel-sesiones).
// Las posiciones de cada fila las pone panel.lua en cada actualización.
const fs = require('fs');
const os = require('os');
const path = require('path');

// Carpeta de skins de Rainmeter: la que calcula instalar.ps1 (PANEL_SKINS), la de Rainmeter.ini (SkinPath=)
// o la de por defecto en Documentos.
function carpetaSkins() {
  if (process.env.PANEL_SKINS) return process.env.PANEL_SKINS;
  try {
    const ini = fs.readFileSync(path.join(process.env.APPDATA, 'Rainmeter', 'Rainmeter.ini'), 'utf8');
    const m = ini.replace(/\0/g, '').match(/^SkinPath=(.+)$/m);
    if (m) return m[1].trim();
  } catch {}
  return path.join(os.homedir(), 'Documents', 'Rainmeter', 'Skins');
}

const SKIN = path.join(carpetaSkins(), 'PanelClaude');
const INSTALACION = __dirname;
const MAX = 8;
fs.mkdirSync(SKIN, { recursive: true });

// Conserva el modo elegido (completo / minimo) si la skin ya existía.
let modo = 'completo';
try {
  const previo = fs.readFileSync(path.join(SKIN, 'PanelClaude.ini'), 'utf16le');
  const m = previo.match(/^Modo=(\w+)/m);
  if (m) modo = m[1];
} catch {}

let ini = `[Rainmeter]
Update=500
AccurateText=1
DynamicWindowSize=1
MouseOverAction=[!CommandMeasure MeasureLua "Expandir(true)"]
MouseLeaveAction=[!CommandMeasure MeasureLua "Expandir(false)"]
ContextTitle=Cambiar modo completo / mínimo
ContextAction=[!CommandMeasure MeasureLua "CambiarModo()"]

[Metadata]
Name=PanelClaude
Information=Estado de las sesiones de Claude Code. Lo alimenta ${INSTALACION}\\hook.js y se genera con generar-skin.js

[Variables]
Archivo=${INSTALACION}\\panel.txt
Enfocar=${INSTALACION}\\enfocar-vscode.exe
Util=${INSTALACION}\\panel-util.exe
Modo=${modo}
MaxFilas=${MAX}
AltoFila=26
AltoTitulo=24
Margen=8
Ancho=380
AnchoMaxNombre=150
Fuente=Segoe UI

; Devuelve los PID de los claude.exe vivos (",12,34,"). panel.lua lo lanza cada 10 s.
[MeasurePids]
Measure=Plugin
Plugin=RunCommand
Program=#Util#
Parameter=pids
State=Hide
OutputType=ANSI

[MeasureLua]
Measure=Script
ScriptFile=#CURRENTPATH#panel.lua

[Fondo]
Meter=Shape
Shape=Rectangle 0,0,#Ancho#,40,8 | Fill Color 18,18,22,200 | StrokeWidth 0

[Titulo]
Meter=String
X=(#Margen# + 4)
Y=(#Margen# - 2)
FontFace=#Fuente#
FontSize=8
StringStyle=Bold
StringCase=Upper
FontColor=255,255,255,110
AntiAlias=1
SolidColor=0,0,0,1
Text=Sesiones de Claude
ToolTipText=Clic: cambiar a modo mínimo
LeftMouseUpAction=[!CommandMeasure MeasureLua "CambiarModo()"]

[SinSesiones]
Meter=String
X=(#Margen# + 4)
Y=(#Margen# + #AltoTitulo# + 3)
FontFace=#Fuente#
FontSize=9
FontColor=255,255,255,140
AntiAlias=1
Text=Sin sesiones de Claude abiertas

`;
for (let i = 1; i <= MAX; i++) {
  ini += `[FondoFila${i}]
Meter=Shape
X=#Margen#
Y=0
Shape=Rectangle 0,0,10,10 | Fill Color 0,0,0,0 | StrokeWidth 0
Group=Fila${i}
Hidden=1

[Punto${i}]
Meter=Shape
X=0
Y=0
Shape=Ellipse 6,6,5 | Fill Color 150,150,150,255 | StrokeWidth 0
Group=Fila${i}
Hidden=1

[Nombre${i}]
Meter=String
X=(#Margen# + 26)
Y=0
ClipString=2
ClipStringW=#AnchoMaxNombre#
FontFace=#Fuente#
FontSize=10
StringStyle=Bold
FontColor=255,255,255,235
AntiAlias=1
SolidColor=0,0,0,1
MouseOverAction=[!SetOption Nombre${i} FontColor "130,180,255,255"][!UpdateMeter Nombre${i}][!Redraw]
MouseLeaveAction=[!SetOption Nombre${i} FontColor "255,255,255,235"][!UpdateMeter Nombre${i}][!Redraw]
Group=Fila${i}
Hidden=1

[Detalle${i}]
Meter=String
X=8R
Y=0
W=(#Ancho# - [Nombre${i}:XW] - #Margen# - 56)
ClipString=1
FontFace=#Fuente#
FontSize=9
FontColor=255,255,255,150
AntiAlias=1
SolidColor=0,0,0,1
DynamicVariables=1
Group=Fila${i}
Hidden=1

[Hace${i}]
Meter=String
X=(#Ancho# - #Margen# - 6)
Y=0
StringAlign=Right
FontFace=#Fuente#
FontSize=8
FontColor=255,255,255,120
AntiAlias=1
Group=Fila${i}
Hidden=1

`;
}

function utf16(fichero, texto) {
  fs.writeFileSync(fichero, '\ufeff' + texto.replace(/\r?\n/g, '\r\n'), 'utf16le');
}

utf16(path.join(SKIN, 'PanelClaude.ini'), ini);

// El original de panel.lua est\u00e1 en UTF-8 junto a este script; la skin recibe una copia en UTF-16 LE.
const lua = fs.readFileSync(path.join(__dirname, 'panel.lua'), 'utf8').replace(/^\ufeff/, '');
utf16(path.join(SKIN, 'panel.lua'), lua.replace(/\r\n/g, '\n'));
console.log('Skin generada en', SKIN, '(modo ' + modo + ')');

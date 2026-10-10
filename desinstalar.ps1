# Desinstala el panel de sesiones de Claude Code.
# Quita solo los hooks del panel de settings.json (los demás se quedan), desactiva y borra la skin PanelClaude,
# quita el enlace panelclaude:// y borra %USERPROFILE%\.claude\panel-sesiones. No desinstala Rainmeter ni Node.js.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File desinstalar.ps1 [-EnSeco] [-Settings <ruta>]
#   -EnSeco    dice lo que haría, sin cambiar nada.
#   -Settings  otro settings.json (para probar con una copia).

param(
    [switch]$EnSeco,
    [string]$Settings = (Join-Path $env:USERPROFILE '.claude\settings.json')
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$destino = Join-Path $env:USERPROFILE '.claude\panel-sesiones'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
$clave = 'HKCU:\Software\Classes\panelclaude'

function Paso([string]$texto) { Write-Host "-> $texto" -ForegroundColor Cyan }
if ($EnSeco) { Write-Host 'EN SECO: no se cambia nada.' -ForegroundColor Yellow }

function Buscar-Node {
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $tipica = Join-Path $env:ProgramFiles 'nodejs\node.exe'
    if (Test-Path $tipica) { return $tipica }
    return $null
}

# 1. Hooks. Va primero: si fallara, no se borra nada más y los hooks siguen funcionando.
Paso "Quitando los hooks del panel de $Settings"
$node = Buscar-Node
if (-not $node) { throw 'No se encuentra Node.js, que hace falta para editar settings.json sin estropearlo.' }
$argumentos = @((Join-Path $repo 'src\quitar-hooks.js'), $Settings)
if ($EnSeco) { $argumentos += '--en-seco' }
& $node @argumentos
if ($LASTEXITCODE -ne 0) { throw 'Error al quitar los hooks. No se ha borrado nada más.' }

# 2. Skin de Rainmeter
$configRainmeter = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
if (Test-Path $configRainmeter) {
    $linea = Select-String -Path $configRainmeter -Pattern '^SkinPath=(.+)$' | Select-Object -First 1
    if ($linea) { $skins = $linea.Matches[0].Groups[1].Value.Trim() }
}
$skin = Join-Path $skins 'PanelClaude'
Paso 'Desactivando la skin PanelClaude'
if (-not $EnSeco -and (Test-Path $rainmeter) -and (Get-Process Rainmeter -ErrorAction SilentlyContinue)) {
    & $rainmeter '!DeactivateConfig' 'PanelClaude'
    Start-Sleep 2
}
if (Test-Path $skin) {
    Paso "Borrando $skin"
    if (-not $EnSeco) { Remove-Item $skin -Recurse -Force -ErrorAction Continue }
}

# 3. Enlace panelclaude://
if (Test-Path $clave) {
    Paso "Quitando el enlace panelclaude://"
    if (-not $EnSeco) { Remove-Item $clave -Recurse -Force -ErrorAction Continue }
}

# 4. Carpeta instalada
if (Test-Path $destino) {
    Paso "Borrando $destino"
    if (-not $EnSeco) { Remove-Item $destino -Recurse -Force -ErrorAction Continue }
}

Write-Host ''
if ($EnSeco) { Write-Host 'En seco: no se ha cambiado nada.' -ForegroundColor Yellow }
else { Write-Host 'Desinstalado. Las sesiones de Claude Code abiertas pueden necesitar reiniciarse.' -ForegroundColor Green }

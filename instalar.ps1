# Instala (o actualiza) el panel de sesiones de Claude Code para Rainmeter.
# Uso: powershell -ExecutionPolicy Bypass -File instalar.ps1
# Se puede ejecutar tantas veces como haga falta: sobrescribe el código, conserva sonidos y ajustes.

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$destino = Join-Path $env:USERPROFILE '.claude\panel-sesiones'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

function Paso([string]$texto) { Write-Host "-> $texto" -ForegroundColor Cyan }

# 1. Requisitos
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Falta Node.js (https://nodejs.org).' }
if (-not (Test-Path $rainmeter)) { throw "Falta Rainmeter (https://www.rainmeter.net). No está en $rainmeter" }
if (-not (Test-Path $csc)) { throw "Falta el compilador de C# de .NET Framework 4 ($csc)." }

# 2. Copiar ficheros
Paso "Copiando ficheros a $destino"
New-Item -ItemType Directory -Force (Join-Path $destino 'sonidos') | Out-Null
Copy-Item (Join-Path $repo 'src\*') $destino -Force
Get-ChildItem (Join-Path $repo 'sonidos') -Filter *.wav -ErrorAction SilentlyContinue |
    Copy-Item -Destination (Join-Path $destino 'sonidos') -Force

# 3. Compilar los dos programas en C#
Paso 'Compilando panel-util.exe y enfocar-vscode.exe'
& $csc /nologo /target:exe /out:"$destino\panel-util.exe" "$destino\panel-util.cs"
if ($LASTEXITCODE -ne 0) { throw 'Error al compilar panel-util.cs' }
& $csc /nologo /target:winexe /out:"$destino\enfocar-vscode.exe" "$destino\enfocar-vscode.cs"
if ($LASTEXITCODE -ne 0) { throw 'Error al compilar enfocar-vscode.cs' }

# 4. Enlace panelclaude:// (al pulsar una notificación se trae al frente la ventana de VS Code)
Paso 'Registrando el enlace panelclaude://'
$clave = 'HKCU:\Software\Classes\panelclaude'
New-Item "$clave\shell\open\command" -Force | Out-Null
Set-ItemProperty $clave -Name '(default)' -Value 'URL:Panel de sesiones de Claude'
Set-ItemProperty $clave -Name 'URL Protocol' -Value ''
Set-ItemProperty "$clave\shell\open\command" -Name '(default)' -Value "`"$destino\enfocar-vscode.exe`" `"%1`""

# 5. Hooks de Claude Code
Paso 'Registrando los hooks en la configuración global de Claude Code'
node (Join-Path $destino 'instalar-hooks.js')

# 6. Skin de Rainmeter
Paso 'Generando la skin de Rainmeter'
node (Join-Path $destino 'generar-skin.js')

$configRainmeter = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
$yaActiva = (Test-Path $configRainmeter) -and (Select-String -Path $configRainmeter -Pattern '^\[PanelClaude\]' -Quiet)
if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) { Start-Process $rainmeter; Start-Sleep 3 }
if ($yaActiva) {
    & $rainmeter '!Refresh' 'PanelClaude'
} else {
    Paso 'Activando la skin por primera vez'
    & $rainmeter '!ActivateConfig' 'PanelClaude' 'PanelClaude.ini'
    Start-Sleep 2
    # Semitransparente; se vuelve opaca al pasar el ratón. Siempre encima. Arriba a la derecha.
    $ajustes = [ordered]@{ AlphaValue = '160'; OnHover = '2'; AlwaysOnTop = '2'; Draggable = '1'; SnapEdges = '1';
                           KeepOnScreen = '1'; WindowX = '(#SCREENAREAWIDTH#-400)'; WindowY = '80' }
    foreach ($k in $ajustes.Keys) { & $rainmeter '!WriteKeyValue' 'PanelClaude' $k $ajustes[$k] $configRainmeter; Start-Sleep -Milliseconds 200 }
    Start-Sleep 1
    & $rainmeter '!RefreshApp'
}

Write-Host ''
Write-Host 'Instalado.' -ForegroundColor Green
if (-not (Get-ChildItem (Join-Path $destino 'sonidos') -Filter *.wav -ErrorAction SilentlyContinue)) {
    Write-Host "Sin sonidos: pon terminado.wav y necesita.wav en $destino\sonidos (ver README)." -ForegroundColor Yellow
}
Write-Host 'Las sesiones de Claude Code abiertas antes de instalar pueden necesitar reiniciarse para leer los hooks.'

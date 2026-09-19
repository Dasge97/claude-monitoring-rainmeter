# Instala (o actualiza) el panel de sesiones de Claude Code para Rainmeter.
# Uso normal: doble clic en Instalar.cmd.
# Se puede ejecutar tantas veces como haga falta: sobrescribe el código, conserva sonidos y ajustes.
# Si falta Rainmeter, Node.js o Git para Windows, los instala con winget
# o, si este Windows no tiene winget, con el instalador oficial de cada uno.

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$destino = Join-Path $env:USERPROFILE '.claude\panel-sesiones'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

function Paso([string]$texto) { Write-Host "-> $texto" -ForegroundColor Cyan }

# Después de instalar algo con winget, esta ventana no ve el PATH nuevo hasta que se relee.
function Releer-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Buscar-Winget {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $directa = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $directa) { return $directa }
    return $null
}

# Sin winget: se descarga el instalador oficial y se ejecuta en modo silencioso (pide permiso de administrador).
function Descargar-E-Instalar([string]$nombre, [string]$url, [string]$argumentos) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $fichero = Join-Path $env:TEMP ([IO.Path]::GetFileName(([Uri]$url).AbsolutePath))
    Write-Host "   Descargando $url"
    Invoke-WebRequest $url -OutFile $fichero -UseBasicParsing
    if ($fichero.EndsWith('.msi')) {
        Start-Process msiexec.exe -ArgumentList "/i `"$fichero`" $argumentos" -Verb RunAs -Wait
    } else {
        Start-Process $fichero -ArgumentList $argumentos -Verb RunAs -Wait
    }
    Remove-Item $fichero -Force -ErrorAction SilentlyContinue
}

function Ultimo-De-GitHub([string]$repositorio, [string]$patron) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $version = Invoke-RestMethod "https://api.github.com/repos/$repositorio/releases/latest" -UseBasicParsing
    ($version.assets | Where-Object { $_.name -match $patron } | Select-Object -First 1).browser_download_url
}

function Instalar-Programa([string]$id, [string]$nombre, [string]$web) {
    Paso "Instalando $nombre (puede pedir permiso de administrador)"
    $winget = Buscar-Winget
    if ($winget) {
        & $winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host '   Este Windows no tiene winget: se descarga el instalador oficial.'
        try {
            switch ($id) {
                'Rainmeter.Rainmeter' { Descargar-E-Instalar $nombre (Ultimo-De-GitHub 'rainmeter/rainmeter' '^Rainmeter-[\d.]+\.exe$') '/S' }
                'Git.Git' { Descargar-E-Instalar $nombre (Ultimo-De-GitHub 'git-for-windows/git' '^Git-[\d.]+-64-bit\.exe$') '/VERYSILENT /NORESTART /SP-' }
                'OpenJS.NodeJS.LTS' {
                    $lts = (Invoke-RestMethod 'https://nodejs.org/dist/index.json' -UseBasicParsing | Where-Object { $_.lts } | Select-Object -First 1).version
                    Descargar-E-Instalar $nombre "https://nodejs.org/dist/$lts/node-$lts-x64.msi" '/qn'
                }
            }
        } catch {
            Write-Host "   No se ha podido descargar: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Releer-Path
}

function Buscar-Node {
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $tipica = Join-Path $env:ProgramFiles 'nodejs\node.exe'
    if (Test-Path $tipica) { return $tipica }
    return $null
}

function Buscar-Bash {
    if (Get-Command bash -ErrorAction SilentlyContinue) { return $true }
    return (Test-Path (Join-Path $env:ProgramFiles 'Git\bin\bash.exe'))
}

# Los ficheros descargados de internet llevan una marca que puede bloquear los scripts.
Get-ChildItem $repo -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

# 1. Requisitos
Paso 'Comprobando requisitos'
if (-not (Test-Path (Join-Path $env:USERPROFILE '.claude'))) {
    Write-Host '   Aviso: no se encuentra la carpeta .claude. ¿Está instalado Claude Code? Se sigue igualmente.' -ForegroundColor Yellow
}
if (-not (Test-Path $csc)) { throw "Falta el compilador de C# de .NET Framework 4 ($csc). Viene con Windows 10 y 11." }
if (-not (Test-Path $rainmeter)) { Instalar-Programa 'Rainmeter.Rainmeter' 'Rainmeter' 'https://www.rainmeter.net' }
if (-not (Test-Path $rainmeter)) { throw "No se ha podido instalar Rainmeter. Instálalo desde https://www.rainmeter.net y vuelve a ejecutar el instalador." }
$node = Buscar-Node
if (-not $node) { Instalar-Programa 'OpenJS.NodeJS.LTS' 'Node.js' 'https://nodejs.org'; $node = Buscar-Node }
if (-not $node) { throw 'No se ha podido instalar Node.js. Instálalo desde https://nodejs.org y vuelve a ejecutar el instalador.' }
if (-not (Buscar-Bash)) { Instalar-Programa 'Git.Git' 'Git para Windows (Git Bash)' 'https://git-scm.com/download/win' }
if (-not (Buscar-Bash)) { throw 'No se ha podido instalar Git para Windows. Instálalo desde https://git-scm.com/download/win y vuelve a ejecutar el instalador.' }
Write-Host "   Rainmeter, Node.js ($node) y Git Bash: correctos"

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

# 5. Hooks de Claude Code (con la ruta completa de node.exe, por si Claude Code no lo tiene en su PATH)
Paso 'Registrando los hooks en la configuración global de Claude Code'
& $node (Join-Path $destino 'instalar-hooks.js')
if ($LASTEXITCODE -ne 0) { throw 'Error al registrar los hooks' }

# 6. Skin de Rainmeter
$configRainmeter = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
if (Test-Path $configRainmeter) {
    $linea = Select-String -Path $configRainmeter -Pattern '^SkinPath=(.+)$' | Select-Object -First 1
    if ($linea) { $skins = $linea.Matches[0].Groups[1].Value.Trim() }
}
Paso "Generando la skin de Rainmeter en $skins"
$env:PANEL_SKINS = $skins
& $node (Join-Path $destino 'generar-skin.js')
if ($LASTEXITCODE -ne 0) { throw 'Error al generar la skin' }

$yaActiva = (Test-Path $configRainmeter) -and (Select-String -Path $configRainmeter -Pattern '^\[PanelClaude\]' -Quiet)
if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) {
    Paso 'Arrancando Rainmeter'
    Start-Process $rainmeter
    Start-Sleep 4
}
if ($yaActiva) {
    & $rainmeter '!Refresh' 'PanelClaude'
} else {
    Paso 'Activando la skin'
    & $rainmeter '!RefreshApp'
    Start-Sleep 3
    & $rainmeter '!ActivateConfig' 'PanelClaude' 'PanelClaude.ini'
    Start-Sleep 2
    # Semitransparente; se vuelve opaca al pasar el ratón. Siempre encima. Arriba a la derecha.
    $ajustes = [ordered]@{ AlphaValue = '160'; OnHover = '2'; AlwaysOnTop = '2'; Draggable = '1'; SnapEdges = '1';
                           KeepOnScreen = '1'; WindowX = '(#SCREENAREAWIDTH#-400)'; WindowY = '80' }
    foreach ($k in $ajustes.Keys) { & $rainmeter '!WriteKeyValue' 'PanelClaude' $k $ajustes[$k] $configRainmeter; Start-Sleep -Milliseconds 200 }
    Start-Sleep 1
    & $rainmeter '!RefreshApp'
}

# 7. Que Rainmeter arranque con Windows (su instalador suele hacerlo, pero no siempre)
$inicio = [Environment]::GetFolderPath('Startup')
$enInicio = (Get-ChildItem $inicio -Filter 'Rainmeter*.lnk' -ErrorAction SilentlyContinue) -or
            (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains 'Rainmeter'
if (-not $enInicio) {
    Paso 'Haciendo que Rainmeter arranque con Windows'
    $acceso = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $inicio 'Rainmeter.lnk'))
    $acceso.TargetPath = $rainmeter
    $acceso.Save()
}

Write-Host ''
Write-Host 'Instalado.' -ForegroundColor Green
if (-not (Get-ChildItem (Join-Path $destino 'sonidos') -Filter *.wav -ErrorAction SilentlyContinue)) {
    Write-Host "Las notificaciones usarán el sonido de Windows. Para poner los tuyos: terminado.wav y necesita.wav en $destino\sonidos"
}
Write-Host 'Las sesiones de Claude Code que ya estaban abiertas pueden necesitar reiniciarse para leer los hooks.'

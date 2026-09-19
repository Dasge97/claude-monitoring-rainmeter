# Genera el ZIP que se publica en GitHub Releases: dist\claude-monitoring-rainmeter-<version>.zip
# Uso: powershell -ExecutionPolicy Bypass -File empaquetar.ps1 -Version 1.0.0
param([Parameter(Mandatory = $true)][string]$Version)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$nombre = "claude-monitoring-rainmeter-$Version"
$temporal = Join-Path $env:TEMP $nombre
$dist = Join-Path $repo 'dist'
$zip = Join-Path $dist "$nombre.zip"

if (Test-Path $temporal) { Remove-Item $temporal -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $temporal 'src'), (Join-Path $temporal 'sonidos'), $dist | Out-Null

# Solo lo que necesita quien instala. Los sonidos no se incluyen (ver README).
Copy-Item (Join-Path $repo 'Instalar.cmd'), (Join-Path $repo 'instalar.ps1'), (Join-Path $repo 'README.md') $temporal
Copy-Item (Join-Path $repo 'src\*') (Join-Path $temporal 'src')
New-Item -ItemType File (Join-Path $temporal 'sonidos\pon-aqui-terminado.wav-y-necesita.wav.txt') -Force | Out-Null

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $temporal -DestinationPath $zip
Remove-Item $temporal -Recurse -Force
Write-Host "Generado $zip"

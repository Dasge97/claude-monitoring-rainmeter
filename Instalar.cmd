@echo off
rem Doble clic para instalar o actualizar el panel de sesiones de Claude Code.
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1"
echo.
pause

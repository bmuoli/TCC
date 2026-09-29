@echo off
setlocal
title TCC Lab Notebook - GitHub Sync
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0TCC_GitHub_Sync.ps1"
if errorlevel 1 (
  echo.
  echo O auxiliar foi encerrado com erro. Leia a mensagem acima.
  pause
)
endlocal

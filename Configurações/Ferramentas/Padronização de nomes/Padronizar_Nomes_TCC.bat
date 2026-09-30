@echo off
setlocal
chcp 65001 >nul
title Padronizacao de imagens do TCC
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Padronizar_Nomes_TCC.ps1"
set "RETURN_CODE=%ERRORLEVEL%"
echo.
pause
exit /b %RETURN_CODE%

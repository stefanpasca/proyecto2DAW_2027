@echo off
chcp 65001 >nul
REM Aplica las migraciones pendientes en tu BD local (no borra datos)
cd /d "%~dp0.."
C:\xampp\php\php.exe database\migrar.php
echo.
pause

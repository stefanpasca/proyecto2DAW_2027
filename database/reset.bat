@echo off
chcp 65001 >nul
REM Reinicia la BD local desde cero: educate.sql + migraciones + usuario educate_app
cd /d "%~dp0.."
echo Esto BORRA tu base de datos local "educate" y la crea de nuevo con los datos de prueba.
set /p RESP=Escribe SI para continuar: 
if /I not "%RESP%"=="SI" (
  echo Cancelado.
  pause
  exit /b 0
)
C:\xampp\php\php.exe database\reset.php --si
echo.
pause

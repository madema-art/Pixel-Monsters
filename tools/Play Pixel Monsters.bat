@echo off
setlocal
set "GAME=%~dp0Pixel Monsters.exe"

if not exist "%GAME%" (
    echo Pixel Monsters.exe was not found in this game folder.
    pause
    exit /b 1
)

start "" /D "%~dp0" "%GAME%"
exit /b 0

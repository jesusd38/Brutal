@setlocal enableextensions
@cd /d "%~dp0"
powershell.exe -NonInteractive -NoProfile -ExecutionPolicy ByPass -Command "& .\Install.ps1"
pause
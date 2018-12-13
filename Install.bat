@setlocal enableextensions
@cd /d "%~dp0"
powershell.exe -NonInteractive -NoProfile -ExecutionPolicy ByPass -Command "& .\cid\scripts\Install.ps1"
pause
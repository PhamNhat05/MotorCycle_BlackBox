@echo off
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
 echo Open INSTALL_WINDOWS.bat first.
 pause
 exit /b 1
)
".venv\Scripts\python.exe" -m unittest discover -s tests -v
pause

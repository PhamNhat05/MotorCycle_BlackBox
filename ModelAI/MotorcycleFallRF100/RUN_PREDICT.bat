@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
 echo Open INSTALL_WINDOWS.bat first.
 pause
 exit /b 1
)
set "INPUT_CSV="
set /p "INPUT_CSV=Path to one measured IMU CSV (no surrounding quotes): "
".venv\Scripts\python.exe" -u predict.py --csv "%INPUT_CSV%"
pause

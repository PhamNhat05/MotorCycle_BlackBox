@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
 echo Open INSTALL_WINDOWS.bat first.
 pause
 exit /b 1
)
set "AUGMENT_DIR="
echo Enter the MotorcycleIMULab project directory or AUGMENTED result directory.
echo Press Enter for measured-only training.
set /p "AUGMENT_DIR=Augmentation path: "
if "%AUGMENT_DIR%"=="" (
 ".venv\Scripts\python.exe" -u train.py
) else (
 ".venv\Scripts\python.exe" -u train.py --augmentation-dir "%AUGMENT_DIR%"
)
if errorlevel 1 echo Training failed. Read the error above; no success result is claimed.
pause

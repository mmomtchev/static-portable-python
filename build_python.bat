set mypath=%~dp0
cd %mypath:~0,-1%

set PYTHONHOME=
set PYTHONPATH=

if not exist %PYTHON_DIST% mkdir %PYTHON_DIST%
if not exist %PYTHON_BUILD% mkdir %PYTHON_BUILD%
if not exist %1 mkdir %1
if not exist %PYTHON_DIST%\Python-%PYTHON_VERSION%.tgz (
  curl https://www.python.org/ftp/python/%PYTHON_VERSION%/Python-%PYTHON_VERSION%.tgz --output %PYTHON_DIST%\Python-%PYTHON_VERSION%.tgz
)

echo "Windows CPU Architecture : %PROCESSOR_ARCHITECTURE% / %PROCESSOR_ARCHITEW6432%"

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set ARCH=x64
  set ARCH_DIR=amd64
) else if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
  set ARCH=x64
  set ARCH_DIR=amd64
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
  set ARCH=ARM64
  set ARCH_DIR=arm64
) else (
  echo %PROCESSOR_ARCHITECTURE% not supported, only AMD64 and ARM64
  exit 1
)

if not exist "%1\python3*.lib" (
  echo building in %1
  rd /q /s %PYTHON_BUILD%\Python-%PYTHON_VERSION%

  tar -C %PYTHON_BUILD% -zxf %PYTHON_DIST%\Python-%PYTHON_VERSION%.tgz
  %PYTHON_BUILD%\Python-%PYTHON_VERSION%\PCBuild\build.bat -p %ARCH%
  if not exist %1\DLLs mkdir %1\DLLs
  (robocopy %PYTHON_BUILD%\Python-%PYTHON_VERSION%\PCBuild\%ARCH_DIR% %1\DLLs /MIR) ^& if %ERRORLEVEL% leq 1 set ERRORLEVEL = 0
  (robocopy %PYTHON_BUILD%\Python-%PYTHON_VERSION%\Lib %1\lib /MIR) ^& if %ERRORLEVEL% leq 1 set ERRORLEVEL = 0
  (robocopy %PYTHON_BUILD%\Python-%PYTHON_VERSION%\Include %1\include /MIR) ^& if %ERRORLEVEL% leq 1 set ERRORLEVEL = 0
  copy %PYTHON_BUILD%\Python-%PYTHON_VERSION%\PC\pyconfig.h %1\include
  move "%1\DLLs\python.exe" %1
  move "%1\DLLs\python3*.*" %1
  set PYTHONHOME=%~1
  %1\python -m ensurepip
)

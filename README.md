# This repository contains a static portable Python build

It does not make any assumptions about any installed libraries on the host system nor the directory where it is installed and it supports installing additional modules via `pip`.

It has been tested on the following platforms:
 * Windows 2022 x64
 * Windows 2025 x64
 * Windows 11 arm64
 * Ubuntu 22.04 and 24.04 x64
 * Ubuntu 22.04 arm64
 * macOS 13 x64
 * macOS 14 Apple Silicon

It has been tested on the following Python versions:
 * Python 3.12
 * Python 3.13 (Python 3.13.4 has a Windows build problem: https://github.com/python/cpython/issues/135151)

It is used by:
 * [`pymport`](https://github.com/mmomtchev/pymport) which builds an embeddable shared library
 * [`@mmomtchev/python-xpack`](https://github.com/mmomtchev/python-xpack) which builds a standalone executable


# Usage

## Linux/macOS

If building a standalone executable:
```shell
PYTHON_DIST=$(pwd)/dist   \
PYTHON_BUILD=$(pwd)/build \
PYTHON_VERSION=3.12.8     \
bash build_python.sh $(pwd)/output
```

If building a shared library:
```shell
PYTHON_DIST=$(pwd)/dist   \
PYTHON_BUILD=$(pwd)/build \
PYTHON_VERSION=3.12.8     \
bash build_python.sh $(pwd)/output --enable-shared
```


## Windows

On Windows, the shared library is always built:
```cmd
set PYTHON_DIST=%cd%\dist
set PYTHON_BUILD=%cd%\build
set PYTHON_VERSION=3.12.8
build_python.bat %cd%\output
```

This will produce a moveable Python installation in `output`.

On Windows, the fully integrated Python build is used.

On macOS and Linux, static versions of the needed libraries are retrieved from `conan`.

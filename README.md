# This repository contains a static portable Python build

It does not make any assumptions about any installed libraries on the host system nor the directory where it is installed and it supports installing additional modules via `pip`.

It supports the following platforms
 * Windows x64
 * Linux x64
 * macOS x64
 * macOS Apple Silicon

It supports the following Python versions
 * Python 3.10
 * Python 3.11
 * Python 3.12

It is used by
 * `pymport` which builds an embeddable shared library
 * `@mmomtchev/python-xpack` which builds a standalone executable


# Usage

## Linux/macOS

If building a standalone executable:
```shell
PYTHON_DIST=$(pwd)/dist   \
PYTHON_BUILD=$(pwd)/build \
PYTHON_VERSION=3.12.3     \
bash build_python.sh $(pwd)/output
```

If building a shared library:
```shell
PYTHON_DIST=$(pwd)/dist   \
PYTHON_BUILD=$(pwd)/build \
PYTHON_VERSION=3.12.3     \
bash build_python.sh $(pwd)/output --enable-shared
```


## Windows

On Windows, the shared library is always built:
```cmd
set PYTHON_DIST=%cd%\dist
set PYTHON_BUILD=%cd%\build
set PYTHON_VERSION=3.12.3
build_python.bat %cd%\output
```

This will produce a moveable Python installation in `output`.

Currently, the build is not fully reproducible as it will include the static versions of the system libraries.

A future version might use `conan` for a fully reproducible build.

#!/bin/bash

set -x
unset MAKEFLAGS

cd `dirname $0`
ROOT=`pwd`

mkdir -p ${PYTHON_DIST}
if [ ! -r ${PYTHON_DIST}/Python-${PYTHON_VERSION}.tgz ]; then
  curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz --output ${PYTHON_DIST}/Python-${PYTHON_VERSION}.tgz
fi

SHORT_VERSION=`echo ${PYTHON_VERSION} | cut -f 1,2 -d "."`

case `uname` in
  'Linux') LIBNAME="$1/lib/libpython${SHORT_VERSION}.so" ;;
  'Darwin') LIBNAME="$1/lib/libpython${SHORT_VERSION}.dylib" ;;
  *) echo 'Unsupported platform for the builtin Python interpreter'
     exit 1
     ;;
esac

if [ ! -d "$1" ] || [ ! -r "${LIBNAME}" ]; then
  echo building in $1
  rm -rf ${PYTHON_BUILD}/Python-${PYTHON_VERSION}
  rm -rf ${PYTHON_BUILD}/openssl

  mkdir -p ${PYTHON_BUILD}
  tar -C ${PYTHON_BUILD} -zxf ${PYTHON_DIST}/Python-${PYTHON_VERSION}.tgz
  (
    cd ${PYTHON_BUILD}/Python-${PYTHON_VERSION}
    patch < ${ROOT}/patches/python-${SHORT_VERSION}-configure.patch

    export PY_UNSUPPORTED_OPENSSL_BUILD=static
    case `uname` in
      'Linux')
        export LDFLAGS="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib'"
        export CFLAGS=""
        export ZLIB_LIBS="-lz -ldl"
        export LIBFFI_LIBS="-l:libffi_pic.a -Wl,--exclude-libs,libffi_pic.a"
        ;;
      'Darwin')
        mkdir -p ${PYTHON_BUILD}/openssl/lib
        mkdir -p ${PYTHON_BUILD}/openssl/include
        cp $(brew --prefix openssl@1.1)/lib/*.a ${PYTHON_BUILD}/openssl/lib
        cp -r $(brew --prefix openssl@1.1)/include/openssl ${PYTHON_BUILD}/openssl/include
        mkdir -p ${PYTHON_BUILD}/gettext/lib
        cp $(brew --prefix gettext)/lib/*.a ${PYTHON_BUILD}/gettext/lib
        export SSL="--with-openssl=${PYTHON_BUILD}/openssl"
        export LDFLAGS="-Wl,-search_paths_first -L${PYTHON_BUILD}/gettext/lib  -Wl,-rpath,@loader_path/../lib"
        export LIBS="-liconv -framework CoreFoundation"
        ;;
    esac

    ./configure --prefix $1 $2 --enable-optimizations ${SSL}
    make -j4 build_all
    make install
  )
  rm -f $1/python
  [ ! -r $1/bin/python3 ] && ln -s python${SHORT_VERSION} $1/bin/python3
  ln -s bin/python3 $1/python
fi

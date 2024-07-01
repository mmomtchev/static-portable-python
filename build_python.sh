#!/bin/bash

SEP="============================================="
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
  echo ${SEP}
  echo Getting conan dependencies
  echo ${SEP}
  conan profile detect --exist-ok
  conan install . -of conan --build=missing
  source conan/conanbuild.sh

  echo ${SEP}
  for pkg in zlib bzip2 liblzma; do
    CFLAGS="${CFLAGS} `pkg-config --cflags ${pkg}`"
    LDFLAGS="${LDFLAGS} `pkg-config --libs ${pkg}`"
  done
  echo "conan CFLAGS=${CFLAGS}"
  echo "conan LDFLAGS=${LDFLAGS}"
  echo ${SEP}

  echo ${SEP}
  echo "Building in $1"
  echo ${SEP}

  rm -rf ${PYTHON_BUILD}/Python-${PYTHON_VERSION}
  rm -rf ${PYTHON_BUILD}/openssl

  mkdir -p ${PYTHON_BUILD}
  tar -C ${PYTHON_BUILD} -zxf ${PYTHON_DIST}/Python-${PYTHON_VERSION}.tgz
  (
    cd ${PYTHON_BUILD}/Python-${PYTHON_VERSION}
    for PATCH in ${ROOT}/patches/python-${SHORT_VERSION}-*.patch; do
      patch < ${PATCH}
    done

    export PY_UNSUPPORTED_OPENSSL_BUILD=static
    case `uname` in
      'Linux')
        export LDFLAGS="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,-Bstatic ${LDFLAGS} -Wl,-Bdynamic"
        export CFLAGS
        export ZLIB_LIBS="-Wl,-Bstatic `pkg-config --libs zlib` -Wl,-Bdynamic -ldl"
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
        export LDFLAGS="-Wl,-search_paths_first -L${PYTHON_BUILD}/gettext/lib -Wl,-rpath,@loader_path/../lib"
        export LIBS="-liconv -framework CoreFoundation ${LDFLAGS}"
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

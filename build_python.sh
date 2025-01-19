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
  PKGS="zlib bzip2 liblzma gettext openssl"
  echo "conan CFLAGS=${CFLAGS}"
  echo "conan LDFLAGS=${LDFLAGS}"
  echo ${SEP}

  echo ${SEP}
  echo "Building in $1"
  echo ${SEP}

  rm -rf ${PYTHON_BUILD}/Python-${PYTHON_VERSION}

  mkdir -p ${PYTHON_BUILD}
  tar -C ${PYTHON_BUILD} -zxf ${PYTHON_DIST}/Python-${PYTHON_VERSION}.tgz
  (
    cd ${PYTHON_BUILD}/Python-${PYTHON_VERSION}
    for PATCH in ${ROOT}/patches/python-${SHORT_VERSION}-*.patch; do
      patch < ${PATCH}
    done

    case `uname` in
      'Linux')
        LDFLAGS="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,-Bstatic ${LDFLAGS} `pkg-config --static --libs sqlite3` -Wl,-Bdynamic"
        PKGS="${PKGS} sqlite3 readline"
        export ZLIB_LIBS="-Wl,-Bstatic `pkg-config --static --libs zlib` -Wl,-Bdynamic -ldl"
        export LIBFFI_LIBS="-l:libffi_pic.a -Wl,--exclude-libs,libffi_pic.a"
        ;;
      'Darwin')
        LDFLAGS="-Wl,-search_paths_first -Wl,-rpath,@loader_path/../lib"
        export LIBS="-liconv -framework CoreFoundation ${LDFLAGS}"
        ;;
    esac
    export CFLAGS="`pkg-config --static --cflags ${PKGS}` ${CFLAGS}"
    export LDFLAGS="`pkg-config --static --libs ${PKGS}` ${LDFLAGS}"

    ./configure --prefix $1 $2 --enable-optimizations
    make -j4 build_all
    make install
  )
  rm -f $1/python
  [ ! -r $1/bin/python3 ] && ln -s python${SHORT_VERSION} $1/bin/python3
  ln -s bin/python3 $1/python

  # Get the curl certificates
  curl https://curl.se/ca/cacert.pem --output $1/cacert.pem
  mkdir -p $1/cert
  csplit -k -f $1/cert/root- $1/cacert.pem '/END CERTIFICATE/+1' {500}
  for CERT in $1/cert/root-*; do
      mv ${CERT} ${CERT}.pem
  done
  `pkg-config --variable=bindir openssl`/c_rehash $1/cert
  echo SSL_CERT_DIR=$1/cert
fi

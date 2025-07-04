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
  PKGS="openssl ncurses zlib bzip2 liblzma libgettext"
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

    export LIBUUID_CFLAGS="`pkg-config --cflags uuid`"
    export LIBUUID_LIBS="`pkg-config --libs uuid`"

    export GDBM_CFLAGS="`pkg-config --cflags gdbm`"
    export GDBM_LIBS="`pkg-config --libs gdbm`"

    case `uname` in
      'Linux')
        LDFLAGS="-Wl,-z,origin -Wl,-rpath,'\$\$ORIGIN/../lib' ${LDFLAGS} -Wl,--exclude-libs,ALL"
        PKGS="${PKGS} sqlite3 readline"
        export ZLIB_LIBS="-Wl,-Bstatic `pkg-config --static --libs zlib` -Wl,-Bdynamic -ldl"
        export LIBFFI_LIBS="-l:libffi_pic.a -Wl,--exclude-libs,libffi_pic.a"
        export POSIXSHMEM_LIBS="-lrt"
        export LIBS="`pkg-config --static --libs ${PKGS}` ${LIBS}"
        ;;
      'Darwin')
        PKGS="${PKGS} mpdecimal-libmpdecimal"
        export LIBMPDEC_CFLAGS="pkg-config --cflags mpdecimal-libmpdecimal"
        export LIBMPDEC_LIBS="pkg-config --libs mpdecimal-libmpdecimal"
        # Avoid homebrew in /usr/local/lib
        # Careful to avoid the Apple mess with the shared cache
        # (Recent versions of macOS contain hidden libraries in /usr/lib
        #  that are actually in the shared cache and the Apple iconv is
        #  one of them, that's why -L/usr/lib should come after conan)
        LDFLAGS="-Wl,-search_paths_first -Wl,-rpath,@loader_path/../lib"
        MACOS_LIBS="-L/usr/lib -F/Library/Frameworks -F/System/Library/Frameworks -framework CoreFoundation"
        export LIBS="-Wl,-Z `pkg-config --static --libs ${PKGS}` ${MACOS_LIBS}"
        export GDBM_LIBS="-Wl,-Z ${GDBM_LIBS} ${MACOS_LIBS}"
        export LIBUUID_LIBS="-Wl,-Z ${LIBUUID_LIBS} ${MACOS_LIBS}"
        ;;
    esac

    export CFLAGS="`pkg-config --static --cflags ${PKGS}` ${CFLAGS}"
    export LDFLAGS="${LDFLAGS}"

    case `uname` in
      'Darwin')
        LIBS=`echo $LIBS | sed -e 's/-l/-Wl,-hidden-l/g'`
        ;;
    esac

    echo "Building with CFLAGS=${CFLAGS}"
    echo "Building with LIBS=${LIBS}"
    echo "Building with LDFLAGS=${LDFLAGS}"

    ./configure --prefix $1 $2 --enable-optimizations
    make -j4 build_all
    make install
  )
  rm -f $1/python
  [ ! -r $1/bin/python3 ] && ln -s python${SHORT_VERSION} $1/bin/python3
  ln -s bin/python3 $1/python

  # Get the curl certificates
  curl https://curl.se/ca/cacert.pem --output $1/cacert.pem
  echo SSL_CERT_FILE=$1/cacert.pem
fi

#!/bin/sh

PYTHON_DIR=`dirname $0`
export SSL_CERT_FILE=${PYTHON_DIR}/cacert.pem

exec ${PYTHON_DIR}/bin/python3 "$@"

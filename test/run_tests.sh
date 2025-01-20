#!/bin/bash
# From https://medium.matcha.fyi/build-a-simple-testing-framework-with-bash-bcb59aaa6a57
          
test_numpy() {
  ${PYTHON} -E -s -m pip install numpy
}

test_lzma() {
  ${PYTHON} -E -s -c "import lzma; assert(type(lzma.compress) == type(lambda x: x))"
}

test_sqlite3() {
  ${PYTHON} -E -s -c "import sqlite3; assert(type(sqlite3.apilevel) == str)"
}

test_ssl() {
  ${PYTHON} -E -s -c 'import urllib.request; contents = urllib.request.urlopen("https://www.duckduckgo.com").read()'
}

run_test() {
    local test_name=$1
    echo "Testing $test_name"
    if ! $test_name > test_output.log 2>&1; then
        echo "--- Failed: $test_name"
        cat test_output.log
        return 1
    fi
    echo "- Passed"
    rm test_output.log
    return 0
}

run_all_local_tests() {
    local error_count=0
    for test_name in $(declare -F | grep test_ | cut -d " " -f 3); do
        run_test $test_name
        error_count=$((error_count + $?))
    done
    return $error_count
}

main() {
    if [ -z "${PYTHON}" ]; then
      PYTHON=`which python`
    fi
    export SSL_CERT_FILE=`dirname ${PYTHON}`/cacert.pem
    echo "Testing using ${PYTHON}, SSL_CERT_FILE=${SSL_CERT_FILE}"
    ${PYTHON} -E -s -c "from pprint import pp; import sys; pp(sys.path)"
    echo "============"
    local error_count=0
    run_all_local_tests
    error_count=$?
    if [ $error_count -eq 0 ]; then
        echo "All tests passed"
    else
        echo "$error_count tests failed"
    fi
    return $error_count
}

main
exit $?

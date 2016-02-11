#!/bin/bash
set -e

readonly MBEDTLS_2_2="mbedtls-2.2.1"
readonly MBEDTLS_2_0="mbedtls-2.0.0"
readonly MBEDTLS_1_3="mbedtls-1.3.12"
readonly MBEDTLS_1_2="polarssl-1.2.15"
readonly NO_TIME=1

main() {
    # sudo apt-get install build-essential automake wget

    wget -nc https://tls.mbed.org/download/mbedtls-2.2.1-apache.tgz
    wget -nc https://tls.mbed.org/download/mbedtls-2.0.0-gpl.tgz
    wget -nc https://tls.mbed.org/download/mbedtls-1.3.12-gpl.tgz
    #wget -nc https://tls.mbed.org/download/polarssl-1.2.15-gpl.tgz

    tar xzf "$MBEDTLS_2_2"-apache.tgz
    tar xzf "$MBEDTLS_2_0"-gpl.tgz
    tar xzf "$MBEDTLS_1_3"-gpl.tgz
    #tar xzf "$MBEDTLS_1_2"-gpl.tgz

    # validate the checksum of the code archives
    local CHECKSUM_2_2=$(shasum "${MBEDTLS_2_2}-apache.tgz")
    local CHECKSUM_2_0=$(shasum "${MBEDTLS_2_0}-gpl.tgz")
    local CHECKSUM_1_3=$(shasum "${MBEDTLS_1_3}-gpl.tgz")
    #local CHECKSUM_1_2=$(shasum "${MBEDTLS_1_2}-gpl.tgz")

    if [ "$CHECKSUM_2_2" != "d2ff60fad7191dbb5b81ff6c22769964e5a7d53d  ${MBEDTLS_2_2}-apache.tgz" ]; then
        echo "Error: 2.2 checksum check failed!"
        exit 1
    fi

    if [ "$CHECKSUM_2_0" != "a456be169003b4644931a90613fdaa0429af06a7  ${MBEDTLS_2_0}-gpl.tgz" ]; then
        echo "Error: 2.0 checksum check failed!"
        exit 1
    fi

    if [ "$CHECKSUM_1_3" != "8d47de89f3e9cd54c099a9ecea32321a9b81ad66  ${MBEDTLS_1_3}-gpl.tgz" ]; then
        echo "Error: 1.3 checksum check failed!"
        exit 1
    fi

    #if [ "$CHECKSUM_1_2" != "b1da505ce79637a49e29d12a6beb2c1f74d84a72  polarssl-1.2.15-gpl.tgz" ]; then
        #echo "Error: 1.2 checksum check failed!"
        #exit 1
    #fi

    cp -R fuzz "${MBEDTLS_2_2}"
    cp -R fuzz "${MBEDTLS_2_0}"
    cp -R fuzz "${MBEDTLS_1_3}"

    cp selftls-2.0.c "${MBEDTLS_2_2}/fuzz/selftls.c"
    cp selftls-2.0.c "${MBEDTLS_2_0}/fuzz/selftls.c"
    cp selftls-1.3.c "${MBEDTLS_1_3}/fuzz/selftls.c"

    pushd "$MBEDTLS_2_2" && patch -p1 < ../CMakeLists-2.0.patch
    popd && pushd "$MBEDTLS_2_0" && patch -p1 < ../CMakeLists-2.0.patch
    popd && pushd "$MBEDTLS_1_3" && patch -p1 < ../CMakeLists-1.3.patch && popd

    if [[ "$NO_TIME" = "1" ]]; then
        patch "${MBEDTLS_1_3}/include/polarssl/config.h" config-1.3.patch
        patch "${MBEDTLS_2_0}/include/mbedtls/config.h" config-2.0.patch
        patch "${MBEDTLS_2_2}/include/mbedtls/config.h" config-2.2.patch
    else
        pushd "$MBEDTLS_2_2" && patch -p1 < ../time-2.0.patch
        popd && pushd "$MBEDTLS_2_0" && patch -p1 < ../time-2.0.patch
        popd && pushd "$MBEDTLS_1_3" && patch -p1 < ../time-1.3.patch && popd
    fi

    pushd "${MBEDTLS_2_2}/fuzz" && ./compile.sh
    popd && pushd "${MBEDTLS_2_0}/fuzz" && ./compile.sh
    popd && pushd "${MBEDTLS_1_3}/fuzz" && ./compile.sh
}

main "$@"


#!/bin/bash
set -ex

mbedtls=mbedtls-2.2.1
target="$(pwd)"/${mbedtls}
stat $target
mkdir -p afl-multicore
cd afl-multicore

for i in {1..14}
do

mkdir -p packet-${i}-in
cp ${target}/fuzz/packet-$i packet-${i}-in

cat <<EOF > mbedtls-packet${i}.conf
[afl.dirs]
input = ./packet-${i}-in
output = ./packet-${i}-out

[target]
target = ${target}/fuzz/selftls
cmdline = $i @@

[afl.ctrl]
mem_limit = 300000000

[job]
session = mbedtls-packet${i}_

;afl-fuzz -i fin -o sync -m 300000000 -M packet-$i--fuzzer-${i} ../selftls $i @@
EOF

done
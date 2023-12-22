#!/usr/bin/env bash

MATRIX_FILE="build-matrix.json"

echo -n -e "{ \"versions\": [ " > $MATRIX_FILE

# Get the list of kernels to build
COUNT=0
for i in $(docker run --rm quay.io/centos/centos:stream9 dnf repoquery kernel | cut -d ':' -f 2); do
    if [ $COUNT -gt 0 ]; then
        echo -n -e ", " >> $MATRIX_FILE
    fi
    echo -n -e "\"$i\"" >> $MATRIX_FILE
    COUNT=$((COUNT+1))
done

echo -n -e " ] }" >> $MATRIX_FILE
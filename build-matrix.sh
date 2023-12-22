#!/usr/bin/env bash

MATRIX_FILE="build-matrix.json"

echo -n -e "{ \"version\": [ " > $MATRIX_FILE

TOKEN=$(curl -sSL "https://ghcr.io/token?service=ghcr.io&scope=repository:fabiendupont/driver-toolkit:pull" | jq -r '.token')

# Get the list of kernels to build
COUNT=0
for i in $(docker run --rm quay.io/centos/centos:stream9 dnf repoquery --qf "%{VERSION}-%{RELEASE}" kernel | cut -d ':' -f 2); do
    curl --fail -L -H "Authorization: Bearer ${TOKEN}" \
        -H "Accept:application/vnd.docker.distribution.manifest.v2+json" \
        -H "Accept:application/vnd.docker.distribution.manifest.list.v2+json" \
        -H "Accept:application/vnd.oci.image.manifest.v1+json" \
        -H "Accept:application/vnd.oci.image.index.v1+json" \
        https://ghcr.io/v2/fabiendupont/driver-toolkit/manifests/$i > /dev/null 2>&1
    [[ $? -eq 0 ]] && echo "Version $i already exists in the registry" && continue
    if [ $COUNT -gt 0 ]; then
        echo -n -e ", " >> $MATRIX_FILE
    fi
    echo -n -e "\"$i\"" >> $MATRIX_FILE
    COUNT=$((COUNT+1))
done

echo -n -e " ] }" >> $MATRIX_FILE
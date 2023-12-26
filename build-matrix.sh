#!/usr/bin/env bash

MATRIX_FILE="build-matrix.json"


TOKEN=$(curl -sSL "https://ghcr.io/token?service=ghcr.io&scope=repository:fabiendupont/driver-toolkit:pull" | jq -r '.token')

# Get the list of kernels to build
ALL_KERNELS=$(docker run --rm quay.io/centos/centos:stream9 dnf repoquery --disablerepo='*' --enablerepo=baseos --qf "%{VERSION}-%{RELEASE}" kernel | cut -d ':' -f 2)
echo "CentOS kernels: ${ALL_KERNELS}"

# Filter out kernels for which a Driver Toolkit image already exists
NEEDED_KERNELS=()
for KERNEL in ${ALL_KERNELS} ; do
    curl --fail -L -H "Authorization: Bearer ${TOKEN}" \
        -H "Accept:application/vnd.docker.distribution.manifest.v2+json" \
        -H "Accept:application/vnd.docker.distribution.manifest.list.v2+json" \
        -H "Accept:application/vnd.oci.image.manifest.v1+json" \
        -H "Accept:application/vnd.oci.image.index.v1+json" \
        https://ghcr.io/v2/fabiendupont/driver-toolkit/manifests/$i > /dev/null 2>&1
    [[ $? -ne 0 ]] && echo "Version ${KERNEL} already exists in the registry" && continue
    NEEDED_KERNELS+=("${KERNEL}")
done

# Exit if no Driver Toolkit image is needed
[ ${#NEEDED_KERNELS[@]} == 0 ] && echo "No Driver Toolkit image to build." && touch ${MATRIX_FILE} && exit 0

# Generate the matrix of kernels for which a Driver Toolkit image is needed
echo -n -e "{ \"version\": [ " > $MATRIX_FILE

COUNT=0
for KERNEL in ${NEEDED_KERNELS[@]} ; do
    if [ $COUNT -gt 0 ]; then
        echo -n -e ", " >> $MATRIX_FILE
    fi
    echo "Adding ${KERNEL} to the build matrix."
    echo -n -e "\"${KERNEL}\"" >> $MATRIX_FILE
    COUNT=$((COUNT+1))
done

echo -n -e " ] }" >> $MATRIX_FILE

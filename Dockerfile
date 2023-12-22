FROM quay.io/centos/centos:stream9

ARG KERNEL_VERSION=''

USER root

RUN dnf -y install dnf-plugin-config-manager \
    && dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save \
    && dnf -y install \
        kernel-devel-${KERNEL_VERSION} \
        kernel-modules-${KERNEL_VERSION} \
        kernel-modules-extra-${KERNEL_VERSION} \
    && if [ $(arch) == "x86_64" ]; then \
        dnf -y --enablerepo=rt install \
            kernel-rt-devel-${KERNEL_VERSION} \
            kernel-rt-modules-${KERNEL_VERSION} \
            kernel-rt-modules-extra-${KERNEL_VERSION}; \
    fi \
    && export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core) \
    && export GCC_VERSION=$(cat /lib/modules/${INSTALLED_KERNEL}/config | grep -Eo "CONFIG_CC_VERSION_TEXT=\"gcc \(GCC\) ([0-9\.]+)" | grep -Eo "([0-9\.]+)") \
    && dnf -y install \
        binutils \
        diffutils \
        elfutils-libelf-devel \
        jq \
        kabi-dw kernel-abi-stablelists \
        keyutils \
        kmod \
        gcc${GCC_VERSION:+-}${GCC_VERSION} \
        git \
        make \
        mokutil \
        openssl \
        pinentry \
        rpm-build \
        xz \
    && dnf clean all \
    && useradd -u 1001 -m -s /bin/bash builder

LABEL io.k8s.description="Driver Toolkit provides the packages required to build driver containers for a specific version of CentOS kernel" \
      io.k8s.display-name="Driver Toolkit" \
      org.opencontainers.image.base.name="quay.io/centos/centos:stream9" \
      org.opencontainers.image.source="https://github.com/fabiendupont/driver-toolkit" \
      org.opencontainers.image.vendor="Fabien Dupont" \
      org.opencontainers.image.title="Driver Toolkit" \
      org.opencontainers.image.description="Driver Toolkit provides the packages required to build driver containers for a specific version of CentOS kernel" \
      name="driver-toolkit" \
      vendor="Fabien Dupont" \
      version="${KERNEL_VERSION}"

# Last layer for metadata for mapping the driver-toolkit to a specific kernel version
RUN export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core); \
    echo "{ \"KERNEL_VERSION\": \"${INSTALLED_KERNEL}\" }" > /etc/driver-toolkit-release.json ; \
    echo -e "KERNEL_VERSION=\"${INSTALLED_KERNEL}\"" > /etc/driver-toolkit-release.sh

USER builder
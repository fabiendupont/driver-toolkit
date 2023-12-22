# Driver Toolkit

The Driver Toolkit is a container image meant to be used as a base image on
which to build driver containers. The Driver Toolkit image contains the kernel
packages commonly required as dependencies to build or install kernel modules
as well as a few tools needed in driver containers. The version of these
packages will match the kernel version of CentOS Stream.

Driver containers are container images used for building and deploying
out-of-tree kernel modules and drivers. Kernel modules and drivers are software
libraries running with a high level of privilege in the operating system kernel.
They extend the kernel functionalities or provide the hardware-specific code
required to control new devices. Examples include hardware devices like FPGAs
or GPUs, and software defined storage (SDS) solutions like Lustre parallel
filesystem, which all require kernel modules on client machines. Driver
containers are the first layer of the software stack used to enable these
technologies.

The list of kernel packages in the Driver Toolkit includes the following and
their dependencies:

* `kernel-core`
* `kernel-devel`
* `kernel-headers`
* `kernel-modules`
* `kernel-modules-extra`

In addition, the Driver Toolkit also includes the corresponding real-time
kernel packages:

* `kernel-rt-core`
* `kernel-rt-devel`
* `kernel-rt-modules`
* `kernel-rt-modules-extra`

The Driver Toolkit also has several tools which are commonly needed to build
and install kernel modules, including:

* `elfutils-libelf-devel`
* ` kmod`
* `binutils`
* `kabi-dw`
* `kernel-abi-stablelists`
* an the dependencies for the above

## Purpose

Prior to the Driver Toolkit's existence, you could install kernel packages in a
pod or build config on OpenShift using entitled builds or by installing from
the kernel RPMs in the hosts machine-os-content. The Driver Toolkit simplifies
the process by removing the entitlement step, and avoids the privileged
operation of accessing the machine-os-content in a pod. The Driver Toolkit can
also be used by partners who have access to pre-released OpenShift versions to
prebuild driver-containers for their hardware devices for future OpenShift
releases.

## How to build a driver toolkit image from CentOS Stream 9

### Manual build of the container image

Below is an example for building a driver toolkit image for the version
`5.14.0-391.el9` of the kernel.

```shell
export KERNEL_VERSION=4.18.0-305.40.1.el8_4
podman build \
    --build-arg KERNEL_VERSION=${KERNEL_VERSION} \
    --tag ghcr.io/fabiendupont/driver-toolkit:${KERNEL_VERSION} \
    --file Dockerfile .
```

The resulting container image is fairly big at 660 MB, due to all the
dependencies pulled during the build. When building driver containers, we
recommend using `driver-toolkit` as a builder image in a multi-stage build and
to copy only the required files to the final image, in order to save storage.

For that image to be usable for further builds, we simply push it to Quay.io.
1
```shell
podman login ghrc.io
podman push ghcr.io/fabiendupont/driver-toolkit:${KERNEL_VERSION}
```

## Maintain a library of driver toolkit images

Now that we know how to build a single `driver-toolkit` container image for a
specific kernel version, having a pipeline to build and maintain a library of
images for a variety of kernel versions is sensible. Our library is available
at [ghcr.io/fabiendupont/driver-toolkit](https://github.com/fabiendupont/driver-toolkit).

### Github Actions and build matrix

So, we said that we want to automate the build of driver-toolkit images. A good
option is to use Github Actions to define the pipeline and run it on a daily
schedule. One of the key features of Github Actions is the ability to use a
matrix to run the same job with different parameters, such as the kernel
version.

We have created a script that implements the logic defined earlier to decide
which kernel versions to target: [build-matrix.sh](build-matrix.sh). It will
get all the kernel versions for all z-stream releases since 4.8.0 and
deduplicate the list. For each kernel version, it creates an entry in an
array named `versions` with the RHEL version, the kernel version and the
architectures, which are the build arguments of the Dockerfile. The resulting
matrix is stored in a JSON file. Here is a minimal matrix example:

```json
{
    "versions": [
        "5.14.0-383.el9.x86_64",
        "5.14.0-386.el9.x86_64",
        "5.14.0-388.el9.x86_64",
        "5.14.0-390.el9.x86_64",
        "5.14.0-391.el9.x86_64"
    ]
}
```

The script is used in an initialization job to build the matrix that is used
by the main job responsible for building the images. With the matrix strategy,
the jobs will run in parallel for each kernel version, saving time.

***Note***: To import the matrix, we use the `fromJson` function that can read
only a single line JSON string. So, the script doesn't write any new line in
its output. Don't be surprised when you run it locally.

In order to avoid building the same images every day, hence wasting compute
resources, the build job checks whether the target image tag exist in the
repository. It fetches the manifest of the image with `curl --fail`, so that
the return code is not zero when the manifest doesn't exist, in which case, the
next steps are performed.
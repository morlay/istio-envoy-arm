#!/bin/bash

set -eux;

export ARCH=aarch64;
export TARGETARCH=arm64;

sudo echo "deb-src http://ports.ubuntu.com/ubuntu-ports/ bionic-security main restricted" >> /etc/apt/sources.list;

apt-get update;

apt-get install -y \
    build-essential \
    apt-utils \
    unzip \
    git \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    virtualenv \
    python \
    vim \
    g++ \
    wget \
    ninja-build \
    curl \
    lsb-core \
    openjdk-11-jdk \
    software-properties-common;

# install gn

wget -O /usr/local/bin/gn https://github.com/Jingzhao123/google-gn/releases/download/gn-arm64/gn;
chmod +x /usr/local/bin/gn;


# build hsdis-<arch>.so
mkdir -p /usr/lib/jvm/java-11-openjdk-${TARGETARCH}/lib;
mkdir -p /tmp/jdk && cd /tmp/jdk;
apt source openjdk-11-jdk-headless;
cd $(ls -b | head -1)/src/utils/hsdis;
wget https://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.gz;
tar -xzf binutils-2.32.tar.gz;
export BINUTILS=binutils-2.32;
sed -i -e 's/app_data->dfn = disassembler(native_bfd)/app_data->dfn = disassembler(bfd_get_arch(native_bfd),bfd_big_endian(native_bfd),bfd_get_mach(native_bfd),native_bfd)/g' hsdis.c;
make all64;
cp build/linux-${ARCH}/hsdis-${ARCH}.so /usr/lib/jvm/java-11-openjdk-${TARGETARCH}/lib/;
cp build/linux-${ARCH}/hsdis-${ARCH}.so /usr/lib/jvm/java-11-openjdk-${TARGETARCH}/lib/server/;
rm -rf /tmp/jdk;

export BAZELISK_URL=https://github.com/Tick-Tocker/bazelisk-arm64/releases/download/arm64/bazelisk-linux-arm64;

wget -O /usr/local/bin/bazel ${BAZELISK_URL};
chmod +x /usr/local/bin/bazel


# setup golang

export GOVERSION=1.14.4;

curl -LO https://dl.google.com/go/go${GOVERSION}.linux-${TARGETARCH}.tar.gz;
tar -C /usr/local -xzf go${GOVERSION}.linux-${TARGETARCH}.tar.gz;
rm go${GOVERSION}.linux-${TARGETARCH}.tar.gz;
export PATH=$PATH:/usr/local/go/bin;
export PATH=$PATH:/root/go/bin;
export GOPATH=$HOME/go;
go get -u github.com/bazelbuild/buildtools/buildifier;
export BUILDIFIER_BIN=$GOPATH/bin/buildifier;
go get -u github.com/bazelbuild/buildtools/buildozer;
export BUILDOZER_BIN=$GOPATH/bin/buildozer;

# setup llvm

export LLVM_VERSION=9.0.0;
export LLVM_PATH=/usr/lib/llvm-9;
export LLVM_RELEASE=clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu;

curl -LO  "https://releases.llvm.org/${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz";
tar Jxf "${LLVM_RELEASE}.tar.xz";
mv "./${LLVM_RELEASE}" ${LLVM_PATH};
chown -R root:root ${LLVM_PATH};
rm "./${LLVM_RELEASE}.tar.xz";
echo "${LLVM_PATH}/lib" > /etc/ld.so.conf.d/llvm.conf;
ldconfig;
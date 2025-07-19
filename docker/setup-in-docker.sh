#!/bin/bash

apt-get update

apt-get install -y        \
    build-essential            \
    ca-certificates            \
    clang                      \
    clang-18                   \
    cmake                      \
    crossbuild-essential-arm64 \
    curl                       \
    g++-aarch64-linux-gnu      \
    gcc-aarch64-linux-gnu      \
    git                        \
    gosu                       \
    libc++-18-dev              \
    libc++abi-18-dev           \
    liblzma-dev                \
    libssl-dev                 \
    libxml2-dev                \
    lld                        \
    llvm                       \
    mingw-w64                  \
    ninja-build                \
    patch                      \
    pkg-config                 \
    python3                    \
    python3-pip                \
    wget                       \
    zlib1g-dev

apt-get clean
rm -rf  /var/lib/apt/lists/*

gosu nobody true

update-alternatives --install /usr/bin/clang   clang   /usr/bin/clang-18   100
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100

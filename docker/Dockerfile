FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    llvm \
    lld \
    cmake \
    ninja-build \
    git \
    curl \
    wget \
    pkg-config \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Clang (latest version for C++23 support)
RUN apt-get update && apt-get install -y \
    clang-18 \
    libc++-18-dev \
    libc++abi-18-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100

# Install cross-compilation tools for ARM64
RUN apt-get update && apt-get install -y \
    crossbuild-essential-arm64 \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]

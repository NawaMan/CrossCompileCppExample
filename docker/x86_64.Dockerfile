FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    lsb-release \
    software-properties-common \
    gnupg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install LLVM and Clang 16 (which supports C++23)
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-16 main" && \
    apt-get update && \
    apt-get install -y \
    clang-16 \
    lldb-16 \
    lld-16 \
    libc++-16-dev \
    libc++abi-16-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Clang 16 as the default compiler
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-16 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-16 100 && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang-16 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-16 100

# Create a working directory
WORKDIR /app

# Copy the source code
COPY . .

# Default command
CMD ["/bin/bash"]

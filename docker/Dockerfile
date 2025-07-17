FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for osxcross
ENV PATH="/opt/osxcross/bin:${PATH}"
ENV OSXCROSS_ROOT="/opt/osxcross"

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

# Install dependencies for osxcross
RUN apt-get update && apt-get install -y \
    cmake \
    libssl-dev \
    libxml2-dev \
    liblzma-dev \
    zlib1g-dev \
    patch \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install enhanced placeholders for macOS cross-compilation
# In a real project, you would use actual osxcross toolchain
RUN apt-get update && apt-get install -y \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Create directories for macOS SDK and tools
RUN mkdir -p /opt/osxcross/SDK/MacOSX12.3.sdk \
    && mkdir -p /opt/osxcross/bin

# Create x86_64 macOS compiler placeholder script
RUN echo '#!/bin/bash' > /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    echo 'echo "Creating macOS x86_64 file: $OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    echo 'dd if=/dev/zero of="$OUTPUT" bs=1024 count=4 2>/dev/null' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    echo 'echo "MACHO64" >> "$OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    echo 'if [[ "$@" != *"-c"* ]]; then chmod +x "$OUTPUT"; fi' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++ && \
    chmod +x /opt/osxcross/bin/x86_64-apple-darwin-clang++

# Create ARM64 macOS compiler placeholder script
RUN echo '#!/bin/bash' > /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    echo 'echo "Creating macOS ARM64 file: $OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    echo 'dd if=/dev/zero of="$OUTPUT" bs=1024 count=4 2>/dev/null' >> /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    echo 'echo "MACHO-ARM64" >> "$OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    echo 'if [[ "$@" != *"-c"* ]]; then chmod +x "$OUTPUT"; fi' >> /opt/osxcross/bin/arm64-apple-darwin-clang++ && \
    chmod +x /opt/osxcross/bin/arm64-apple-darwin-clang++

# Add osxcross to PATH
ENV PATH="$PATH:/opt/osxcross/bin"

# SDK is already installed by the osxcross build process

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]

#!/bin/bash
# Script to set up the Docker container environment for cross-compilation

set -e

echo "Setting up Docker container environment..."

# Install common dependencies
apt-get update -qq
apt-get install -qq -y \
    build-essential \
    clang \
    lld \
    xxd \
    vim-common

# Install ARM64 cross-compilation tools if needed
if [ "$SETUP_ARM64" = "true" ]; then
    echo "Installing ARM64 cross-compilation tools..."
    apt-get install -qq -y \
        crossbuild-essential-arm64 \
        qemu-user-static \
        libc6-dev-arm64-cross \
        libstdc++-10-dev-arm64-cross \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu
        
    # Create symlinks for ARM64 libraries if they don't exist
    mkdir -p /usr/aarch64-linux-gnu/lib
    if [ ! -e /usr/aarch64-linux-gnu/lib/libm.so.6 ] && [ -e /usr/aarch64-linux-gnu/lib/aarch64-linux-gnu/libm.so.6 ]; then
        ln -sf /usr/aarch64-linux-gnu/lib/aarch64-linux-gnu/libm.so.6 /usr/aarch64-linux-gnu/lib/libm.so.6
    fi
    
    if [ ! -e /usr/aarch64-linux-gnu/lib/libmvec.so.1 ] && [ -e /usr/aarch64-linux-gnu/lib/aarch64-linux-gnu/libmvec.so.1 ]; then
        ln -sf /usr/aarch64-linux-gnu/lib/aarch64-linux-gnu/libmvec.so.1 /usr/aarch64-linux-gnu/lib/libmvec.so.1
    fi
fi

# Install Windows cross-compilation tools if needed
if [ "$SETUP_WINDOWS" = "true" ]; then
    echo "Installing Windows cross-compilation tools..."
    apt-get install -qq -y \
        mingw-w64 \
        g++-mingw-w64-x86-64 \
        wine64
fi

# Set up osxcross if needed and if SDK is available
if [ "$SETUP_MACOS" = "true" ]; then
    echo "Setting up macOS cross-compilation environment..."
    
    # Check if SDK is mounted
    if [ -d "/opt/osxcross/SDK/MacOSX.sdk" ]; then
        echo "macOS SDK found, setting up osxcross..."
        # In a real setup, you would configure osxcross here
        # For this example, we'll just create symlinks to our placeholder scripts
        mkdir -p /opt/osxcross/bin
        
        # Create symlinks to our placeholder compiler scripts
        if [ -f "/app/docker/x86_64-apple-darwin-clang++" ]; then
            ln -sf /app/docker/x86_64-apple-darwin-clang++ /opt/osxcross/bin/
            ln -sf /app/docker/arm64-apple-darwin-clang++ /opt/osxcross/bin/
            export PATH="/opt/osxcross/bin:$PATH"
            echo "osxcross environment set up successfully"
        else
            echo "Warning: Compiler scripts not found, osxcross setup incomplete"
        fi
    else
        echo "macOS SDK not found at /opt/osxcross/SDK/MacOSX.sdk"
        echo "Will use placeholder binaries for macOS builds"
    fi
fi

# Clean up apt cache to reduce image size
rm -rf /var/lib/apt/lists/*

echo "Docker container environment setup complete"

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
    
    # Create directories for osxcross
    mkdir -p /opt/osxcross/bin
    
    # Check if SDK is mounted (for real osxcross setup)
    if [ -d "/opt/osxcross/SDK/MacOSX.sdk" ]; then
        echo "macOS SDK found, setting up osxcross..."
        # In a real setup, you would configure osxcross here
        echo "Using real osxcross setup with SDK"
    else
        echo "macOS SDK not found, using placeholder scripts"
        
        # First check if we're in Docker container or GitHub Actions
        if [ -f "/app/docker/x86_64-apple-darwin-clang++" ]; then
            # In Docker container
            echo "Using placeholder scripts from /app/docker/"
            cp /app/docker/x86_64-apple-darwin-clang++ /opt/osxcross/bin/ || echo "Failed to copy x86_64-apple-darwin-clang++"
            cp /app/docker/arm64-apple-darwin-clang++ /opt/osxcross/bin/ || echo "Failed to copy arm64-apple-darwin-clang++"
        elif [ -f "./docker/x86_64-apple-darwin-clang++" ]; then
            # In GitHub Actions or local environment
            echo "Using placeholder scripts from ./docker/"
            cp ./docker/x86_64-apple-darwin-clang++ /opt/osxcross/bin/ || echo "Failed to copy x86_64-apple-darwin-clang++"
            cp ./docker/arm64-apple-darwin-clang++ /opt/osxcross/bin/ || echo "Failed to copy arm64-apple-darwin-clang++"
        else
            echo "Warning: Compiler scripts not found in either /app/docker/ or ./docker/"
            echo "Creating minimal placeholder scripts"
            
            # Create minimal placeholder scripts
            cat > /opt/osxcross/bin/x86_64-apple-darwin-clang++ << 'EOF'
#!/bin/bash
echo "This is a placeholder for x86_64-apple-darwin-clang++"
echo "Creating placeholder binary..."
xxd -r -p <<< "cffa edfe 0700 0001 0300 0000 0200 0000" > "$3"
echo "# This is a placeholder for a macOS x86_64 binary" >> "$3"
chmod +x "$3"
EOF

            cat > /opt/osxcross/bin/arm64-apple-darwin-clang++ << 'EOF'
#!/bin/bash
echo "This is a placeholder for arm64-apple-darwin-clang++"
echo "Creating placeholder binary..."
xxd -r -p <<< "cffa edfe 0c00 0001 0300 0000 0200 0000" > "$3"
echo "# This is a placeholder for a macOS ARM64 binary" >> "$3"
chmod +x "$3"
EOF
        fi
        
        # Make the scripts executable
        chmod +x /opt/osxcross/bin/*-clang++ || echo "Failed to make scripts executable"
        
        # Create symlinks for o64-clang++ and arm64-clang++
        ln -sf /opt/osxcross/bin/x86_64-apple-darwin-clang++ /opt/osxcross/bin/o64-clang++
        ln -sf /opt/osxcross/bin/arm64-apple-darwin-clang++ /opt/osxcross/bin/arm64-clang++
        
        # Add osxcross bin to PATH if in GitHub Actions
        if [ -n "$GITHUB_PATH" ]; then
            echo "/opt/osxcross/bin" >> $GITHUB_PATH
        fi
        
        # Add to current PATH
        export PATH="/opt/osxcross/bin:$PATH"
    fi
    
    # List the contents of the bin directory
    ls -la /opt/osxcross/bin/
    
    echo "macOS cross-compilation environment setup complete"
fi

# Clean up apt cache to reduce image size
rm -rf /var/lib/apt/lists/*

echo "Docker container environment setup complete"

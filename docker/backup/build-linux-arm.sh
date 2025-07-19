#!/bin/bash
# Script to build Linux ARM64 binaries inside Docker

set -e

echo "Building for Linux ARM64 architecture inside Docker..."

# Parse arguments
CLEAN_MODE=${1:-false}

# Define paths inside container
SRC_DIR="/app/src"
INCLUDE_DIR="/app/include"
BUILD_DIR="/app/build/linux-arm"
BIN_DIR="/app/build/linux-arm/bin"

# Clean if requested
if [ "$CLEAN_MODE" = "true" ]; then
  echo "Cleaning build directory for linux-arm..."
  rm -rf "$BUILD_DIR"
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$BIN_DIR"

# Check if ARM64 cross-compilation tools are installed
if ! dpkg -l | grep -q crossbuild-essential-arm64; then
  echo "Installing ARM64 cross-compilation tools..."
  apt-get update -qq
  apt-get install -qq -y crossbuild-essential-arm64 libc6-dev-arm64-cross libstdc++-10-dev-arm64-cross gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
fi

# Use the GCC cross-compiler directly instead of Clang
if command -v aarch64-linux-gnu-g++ &> /dev/null; then
  echo "Using aarch64-linux-gnu-g++ compiler"
  COMPILER="aarch64-linux-gnu-g++"
  COMPILER_FLAGS="-std=c++2b"
  # No need for additional flags when using the cross-compiler directly
  ARCH_FLAGS=""
  SYSROOT_FLAGS=""
else
  echo "Error: aarch64-linux-gnu-g++ not found"
  exit 1
fi

# Compile the source files
echo "Compiling $SRC_DIR/main.cpp -> $BUILD_DIR/main.o"
$COMPILER $COMPILER_FLAGS $ARCH_FLAGS $SYSROOT_FLAGS -c "$SRC_DIR/main.cpp" -I"$INCLUDE_DIR" -o "$BUILD_DIR/main.o"

# Link the object files
echo "Linking $BIN_DIR/app"
$COMPILER $COMPILER_FLAGS $ARCH_FLAGS $SYSROOT_FLAGS "$BUILD_DIR/main.o" -o "$BIN_DIR/app"

echo "Linux ARM64 build completed successfully!"
echo "Executable location: $BIN_DIR/app"

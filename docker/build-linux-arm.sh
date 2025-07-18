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

# Set compiler and flags
COMPILER="clang++"
COMPILER_FLAGS="-std=c++2b"
ARCH_FLAGS="--target=aarch64-linux-gnu -march=armv8-a"

# Compile the source files
echo "Compiling $SRC_DIR/main.cpp -> $BUILD_DIR/main.o"
$COMPILER $COMPILER_FLAGS $ARCH_FLAGS -c "$SRC_DIR/main.cpp" -I"$INCLUDE_DIR" -o "$BUILD_DIR/main.o"

# Link the object files
echo "Linking $BIN_DIR/app"
$COMPILER $COMPILER_FLAGS $ARCH_FLAGS "$BUILD_DIR/main.o" -o "$BIN_DIR/app"

echo "Linux ARM64 build completed successfully!"
echo "Executable location: $BIN_DIR/app"

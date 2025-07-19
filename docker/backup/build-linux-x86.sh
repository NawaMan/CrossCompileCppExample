#!/bin/bash
# Script to build Linux x86_64 binaries inside Docker

set -e

echo "Building for Linux x86_64 architecture inside Docker..."

# Parse arguments
CLEAN_MODE=${1:-false}

# Define paths inside container
SRC_DIR="/app/src"
INCLUDE_DIR="/app/include"
BUILD_DIR="/app/build/linux-x86"
BIN_DIR="/app/build/linux-x86/bin"

# Clean if requested
if [ "$CLEAN_MODE" = "true" ]; then
  echo "Cleaning build directory for linux-x86..."
  rm -rf "$BUILD_DIR"
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$BIN_DIR"

# Set compiler and flags
COMPILER="clang++"
COMPILER_FLAGS="-std=c++2b"

# Compile the source files
echo "Compiling $SRC_DIR/main.cpp -> $BUILD_DIR/main.o"
$COMPILER $COMPILER_FLAGS -c "$SRC_DIR/main.cpp" -I"$INCLUDE_DIR" -o "$BUILD_DIR/main.o"

# Link the object files
echo "Linking $BIN_DIR/app"
$COMPILER $COMPILER_FLAGS "$BUILD_DIR/main.o" -o "$BIN_DIR/app"

echo "Linux x86_64 build completed successfully!"
echo "Executable location: $BIN_DIR/app"

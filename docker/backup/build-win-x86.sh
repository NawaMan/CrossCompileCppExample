#!/bin/bash
# Script to build Windows x86_64 binaries inside Docker

set -e

echo "Building for Windows x86_64 architecture inside Docker..."

# Parse arguments
CLEAN_MODE=${1:-false}

# Define paths inside container
SRC_DIR="/app/src"
INCLUDE_DIR="/app/include"
BUILD_DIR="/app/build/win-x86"
BIN_DIR="/app/build/win-x86/bin"

# Clean if requested
if [ "$CLEAN_MODE" = "true" ]; then
  echo "Cleaning build directory for win-x86..."
  rm -rf "$BUILD_DIR"
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$BIN_DIR"

# Set compiler and flags
COMPILER="x86_64-w64-mingw32-g++"
COMPILER_FLAGS="-std=c++2b"

# Check if compiler is available
if ! command -v $COMPILER &> /dev/null; then
  echo "Error: Windows cross-compiler ($COMPILER) not found"
  echo "Installing Windows cross-compilation tools..."
  apt-get update -qq && apt-get install -qq -y mingw-w64 g++-mingw-w64-x86-64
  
  if ! command -v $COMPILER &> /dev/null; then
    echo "Error: Failed to install Windows cross-compiler"
    exit 1
  fi
fi

# Compile the source files
echo "Compiling $SRC_DIR/main.cpp -> $BUILD_DIR/main.o"
$COMPILER $COMPILER_FLAGS -c "$SRC_DIR/main.cpp" -I"$INCLUDE_DIR" -o "$BUILD_DIR/main.o"

# Link the object files
echo "Linking $BIN_DIR/app.exe"
$COMPILER $COMPILER_FLAGS "$BUILD_DIR/main.o" -o "$BIN_DIR/app.exe"

echo "Windows x86_64 build completed successfully!"
echo "Executable location: $BIN_DIR/app.exe"

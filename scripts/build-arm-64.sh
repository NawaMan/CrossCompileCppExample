#!/bin/bash
set -e

# Build script for ARM64 architecture
# This script cross-compiles the C++ project for ARM64 using Clang with C++23 support

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src"
INCLUDE_DIR="${PROJECT_ROOT}/include"
BUILD_DIR="${PROJECT_ROOT}/build/arm64"
BIN_DIR="${BUILD_DIR}/bin"

# Cross-compilation settings
CROSS_TRIPLE="aarch64-linux-gnu"
CXX="clang++"
CXXFLAGS="-std=c++2b -Wall -Wextra -pedantic -O2 -I${INCLUDE_DIR} --target=${CROSS_TRIPLE}"
LDFLAGS="--target=${CROSS_TRIPLE}"

# Print build information
echo "Cross-compiling for ARM64 architecture"
echo "Using compiler: ${CXX} with target ${CROSS_TRIPLE}"
echo "C++ standard: C++23 (via -std=c++2b flag)"
echo "Source directory: ${SRC_DIR}"
echo "Include directory: ${INCLUDE_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Binary directory: ${BIN_DIR}"

# Create build directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${BIN_DIR}"

# Find all .cpp files in the source directory
CPP_FILES=$(find "${SRC_DIR}" -name "*.cpp")

# Compile each source file
for cpp_file in ${CPP_FILES}; do
    filename=$(basename "${cpp_file}")
    object_name="${filename%.cpp}.o"
    object_file="${BUILD_DIR}/${object_name}"
    
    echo "Compiling ${cpp_file} -> ${object_file}"
    ${CXX} ${CXXFLAGS} -c "${cpp_file}" -o "${object_file}"
done

# Link all object files into the final executable
OBJECT_FILES=$(find "${BUILD_DIR}" -name "*.o" -maxdepth 1)
EXECUTABLE="${BIN_DIR}/app"

echo "Linking ${EXECUTABLE}"
${CXX} ${LDFLAGS} ${OBJECT_FILES} -o "${EXECUTABLE}"

echo "Cross-compilation completed successfully!"
echo "Executable location: ${EXECUTABLE}"
echo "Note: This executable is built for ARM64 and cannot be run on x86_64 without emulation."

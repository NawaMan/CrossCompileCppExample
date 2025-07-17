#!/bin/bash
set -e

# Build script for x86_64 architecture
# This script builds the C++ project for x86_64 architecture

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src"
INCLUDE_DIR="${PROJECT_ROOT}/include"
BUILD_DIR="${PROJECT_ROOT}/build/x86_64"
BIN_DIR="${BUILD_DIR}/bin"
COMPILER="clang++"
CPP_STANDARD="-std=c++2b"  # C++23

# Display build information
echo "Building for x86_64 architecture"
echo "Using compiler: ${COMPILER}"
echo "C++ standard: C++23 (via ${CPP_STANDARD} flag)"
echo "Source directory: ${SRC_DIR}"
echo "Include directory: ${INCLUDE_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Binary directory: ${BIN_DIR}"

# Create build directories if they don't exist
mkdir -p "${BIN_DIR}"

# Find all .cpp files in the source directory
CPP_FILES=$(find "${SRC_DIR}" -name "*.cpp" -maxdepth 1)

# Compile each source file
for cpp_file in ${CPP_FILES}; do
    filename=$(basename "${cpp_file}")
    object_file="${BUILD_DIR}/${filename%.cpp}.o"
    
    echo "Compiling ${cpp_file} -> ${object_file}"
    
    ${COMPILER} ${CPP_STANDARD} -c "${cpp_file}" -I"${INCLUDE_DIR}" -o "${object_file}"
done

# Link all object files
OBJECT_FILES=$(find "${BUILD_DIR}" -name "*.o")
OUTPUT_BINARY="${BIN_DIR}/app"

echo "Linking ${OUTPUT_BINARY}"
${COMPILER} ${CPP_STANDARD} ${OBJECT_FILES} -o "${OUTPUT_BINARY}"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build completed successfully!"
    echo "Executable location: ${OUTPUT_BINARY}"
else
    echo "Build failed!"
    exit 1
fi

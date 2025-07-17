#!/bin/bash
set -e

# Build script for x86_64 architecture
# This script compiles the C++ project using Clang with C++23 support

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src"
INCLUDE_DIR="${PROJECT_ROOT}/include"
BUILD_DIR="${PROJECT_ROOT}/build/x86_64"
BIN_DIR="${BUILD_DIR}/bin"

# Compiler settings
CXX="clang++"
CXXFLAGS="-std=c++2b -Wall -Wextra -pedantic -O2 -I${INCLUDE_DIR}"
LDFLAGS=""

# Print build information
echo "Building for x86_64 architecture"
echo "Using compiler: ${CXX}"
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

echo "Build completed successfully!"
echo "Executable location: ${EXECUTABLE}"

# Run the executable if requested
if [ "$1" == "run" ]; then
    echo "Running the executable..."
    "${EXECUTABLE}"
fi

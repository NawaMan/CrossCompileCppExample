#!/bin/bash
set -e

# Build script for C++ cross-compilation
# This script builds the project using Docker for consistent environment

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# No default architecture - must be explicitly specified
ARCH=""
CLEAN_MODE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    linux-x86)
      ARCH="linux-x86"
      shift
      ;;
    linux-arm)
      ARCH="linux-arm"
      shift
      ;;
    --clean)
      CLEAN_MODE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options] <architecture>"
      echo "Architectures:"
      echo "  linux-x86    Build for Linux x86_64 architecture"
      echo "  linux-arm    Build for Linux ARM64 architecture"
      echo "Options:"
      echo "  --clean      Clean build directories before building"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 <architecture>"
      echo "Run '$0 --help' for more information."
      exit 1
      ;;
  esac
done

# If clean mode is enabled without an architecture, clean all build directories
if [ "${CLEAN_MODE}" = true ] && [ -z "$ARCH" ]; then
  echo "Cleaning all build directories..."
  docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm dev bash -c "
    rm -rf /app/build
    echo 'All build directories have been cleaned.'
  "
  exit 0
fi

# Check if architecture is specified, show help if not
if [ -z "$ARCH" ]; then
  echo "Usage: $0 [options] <architecture>"
  echo "Architectures:"
  echo "  linux-x86    Build for Linux x86_64 architecture"
  echo "  linux-arm    Build for Linux ARM64 architecture"
  echo "Options:"
  echo "  --clean      Clean build directories before building"
  echo "  -h, --help   Show this help message"
  exit 0
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "Error: Docker Compose is not installed or not in PATH"
    exit 1
fi

# Build the Docker image if needed
echo "Building or updating Docker image..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" build

# Set up build directories and variables based on architecture
SRC_DIR="/app/src"
INCLUDE_DIR="/app/include"
BUILD_DIR="/app/build/${ARCH}"
BIN_DIR="${BUILD_DIR}/bin"

# Determine compiler flags based on architecture
if [ "${ARCH}" = "linux-arm" ]; then
    CROSS_TRIPLE="aarch64-linux-gnu"
    COMPILER_FLAGS="-std=c++2b -Wall -Wextra -pedantic -O2 -I${INCLUDE_DIR} --target=${CROSS_TRIPLE}"
    LINKER_FLAGS="--target=${CROSS_TRIPLE}"
    echo "Building for Linux ARM64 architecture"
elif [ "${ARCH}" = "linux-x86" ]; then
    COMPILER_FLAGS="-std=c++2b -Wall -Wextra -pedantic -O2 -I${INCLUDE_DIR}"
    LINKER_FLAGS=""
    echo "Building for Linux x86_64 architecture"
else
    echo "Error: Unsupported architecture: ${ARCH}"
    exit 1
fi

# Run the build inside the Docker container
echo "Running build in Docker container..."

# Set clean command if clean mode is enabled
CLEAN_CMD=""
if [ "${CLEAN_MODE}" = true ]; then
  echo "Cleaning build directory for ${ARCH}..."
  CLEAN_CMD="rm -rf \"${BUILD_DIR}\" && "
fi

docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm dev bash -c "${CLEAN_CMD}
    set -e
    
    # Print build information
    echo \"Using compiler: clang++\"
    echo \"C++ standard: C++23 (via -std=c++2b flag)\"
    echo \"Source directory: ${SRC_DIR}\"
    echo \"Include directory: ${INCLUDE_DIR}\"
    echo \"Build directory: ${BUILD_DIR}\"
    echo \"Binary directory: ${BIN_DIR}\"
    
    # Create build directories
    mkdir -p \"${BIN_DIR}\"
    
    # Find all .cpp files in the source directory
    CPP_FILES=\$(find \"${SRC_DIR}\" -maxdepth 1 -name \"*.cpp\")
    
    # Compile each source file
    for cpp_file in \${CPP_FILES}; do
        filename=\$(basename \"\${cpp_file}\")
        object_name=\"\${filename%.cpp}.o\"
        object_file=\"${BUILD_DIR}/\${object_name}\"
        
        echo \"Compiling \${cpp_file} -> \${object_file}\"
        clang++ ${COMPILER_FLAGS} -c \"\${cpp_file}\" -o \"\${object_file}\"
    done
    
    # Link all object files into the final executable
    OBJECT_FILES=\$(find \"${BUILD_DIR}\" -maxdepth 1 -name \"*.o\")
    EXECUTABLE=\"${BIN_DIR}/app\"
    
    echo \"Linking \${EXECUTABLE}\"
    clang++ ${LINKER_FLAGS} \${OBJECT_FILES} -o \"\${EXECUTABLE}\"
    
    if [ \"${ARCH}\" = \"linux-arm\" ]; then
        echo \"Cross-compilation completed successfully!\"
        echo \"Executable location: \${EXECUTABLE}\"
        echo \"Note: This executable is built for ARM64 and cannot be run on x86_64 without emulation.\"
    else
        echo \"Build completed successfully!\"
        echo \"Executable location: \${EXECUTABLE}\"
    fi
"

echo "${ARCH} build completed!"

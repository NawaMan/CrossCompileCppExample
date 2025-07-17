#!/bin/bash
set -e

# Build script for C++ cross-compilation
# This script builds the project using Docker for consistent environment locally
# or directly on the host when running in CI environments

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Detect if running in GitHub Actions
IN_GITHUB_ACTIONS=false
if [ -n "$GITHUB_ACTIONS" ]; then
  IN_GITHUB_ACTIONS=true
  echo "Running in GitHub Actions environment - will build directly on runner"
fi

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
    mac-x86)
      ARCH="mac-x86"
      shift
      ;;
    mac-arm)
      ARCH="mac-arm"
      shift
      ;;
    win-x86)
      ARCH="win-x86"
      shift
      ;;
    win-arm)
      ARCH="win-arm"
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
      echo "  mac-x86      Build for macOS x86_64 architecture"
      echo "  mac-arm      Build for macOS ARM64 architecture"
      echo "  win-x86      Build for Windows x86_64 architecture"
      echo "  win-arm      Build for Windows ARM64 architecture"
      echo "Options:"
      echo "  --clean      Clean build directories before building"
      echo "  -h, --help   Show this help message"
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
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    rm -rf "${PROJECT_ROOT}/build"
    echo 'All build directories have been cleaned.'
  else
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm dev bash -c "
      rm -rf /app/build
      echo 'All build directories have been cleaned.'
    "
  fi
  exit 0
fi

# Check if architecture is specified, show help if not
if [ -z "$ARCH" ]; then
  echo "Usage: $0 [options] <architecture>"
  echo "Architectures:"
  echo "  linux-x86    Build for Linux x86_64 architecture"
  echo "  linux-arm    Build for Linux ARM64 architecture"
  echo "  mac-x86      Build for macOS x86_64 architecture"
  echo "  mac-arm      Build for macOS ARM64 architecture"
  echo "  win-x86      Build for Windows x86_64 architecture"
  echo "  win-arm      Build for Windows ARM64 architecture"
  echo "Options:"
  echo "  --clean      Clean build directories before building"
  echo "  -h, --help   Show this help message"
  exit 0
fi

# Check if Docker is needed and available when not in GitHub Actions
if [ "$IN_GITHUB_ACTIONS" = false ]; then
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
fi

# Set up build directories and variables based on architecture
if [ "$IN_GITHUB_ACTIONS" = true ]; then
  # Use local paths when in GitHub Actions
  SRC_DIR="${PROJECT_ROOT}/src"
  INCLUDE_DIR="${PROJECT_ROOT}/include"
  BUILD_DIR="${PROJECT_ROOT}/build/${ARCH}"
  BIN_DIR="${BUILD_DIR}/bin"
else
  # Use Docker container paths
  SRC_DIR="/app/src"
  INCLUDE_DIR="/app/include"
  BUILD_DIR="/app/build/${ARCH}"
  BIN_DIR="${BUILD_DIR}/bin"
fi

# Determine compiler flags based on architecture
if [ "$ARCH" = "linux-x86" ]; then
  echo "Building for Linux x86_64 architecture"
  COMPILER="clang++"
  ARCH_FLAGS=""
  SYSROOT_FLAGS=""
elif [ "$ARCH" = "linux-arm" ]; then
  echo "Building for Linux ARM64 architecture"
  COMPILER="clang++"
  ARCH_FLAGS="--target=aarch64-linux-gnu -march=armv8-a"
  SYSROOT_FLAGS=""
elif [ "$ARCH" = "mac-x86" ]; then
  echo "Building for macOS x86_64 architecture"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    # Use native clang on macOS runner
    COMPILER="clang++"
    ARCH_FLAGS="-target x86_64-apple-macos11"
    SYSROOT_FLAGS=""
  else
    # Use cross-compiler in Docker
    COMPILER="x86_64-apple-darwin-clang++"
    ARCH_FLAGS=""
    SYSROOT_FLAGS="-isysroot /opt/osxcross/SDK/MacOSX12.3.sdk"
  fi
elif [ "$ARCH" = "mac-arm" ]; then
  echo "Building for macOS ARM64 architecture"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    # Use native clang on macOS runner
    COMPILER="clang++"
    ARCH_FLAGS="-target arm64-apple-macos11"
    SYSROOT_FLAGS=""
  else
    # Use cross-compiler in Docker
    COMPILER="arm64-apple-darwin-clang++"
    ARCH_FLAGS=""
    SYSROOT_FLAGS="-isysroot /opt/osxcross/SDK/MacOSX12.3.sdk"
  fi
elif [ "$ARCH" = "win-x86" ]; then
  echo "Building for Windows x86_64 architecture"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    # Use direct MinGW compiler on GitHub Actions
    COMPILER="x86_64-w64-mingw32-g++"
  else
    COMPILER="x86_64-w64-mingw32-clang++"
  fi
  ARCH_FLAGS=""
  SYSROOT_FLAGS=""
  EXTENSION=".exe"
elif [ "$ARCH" = "win-arm" ]; then
  echo "Building for Windows ARM64 architecture"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    # Check if aarch64-w64-mingw32-g++ is available
    if command -v aarch64-w64-mingw32-g++ &> /dev/null; then
      COMPILER="aarch64-w64-mingw32-g++"
    else
      echo "Warning: aarch64-w64-mingw32-g++ not found. Using Docker for Windows ARM64 build."
      USE_DOCKER=true
      COMPILER="aarch64-w64-mingw32-clang++"
    fi
  else
    COMPILER="aarch64-w64-mingw32-clang++"
  fi
  ARCH_FLAGS=""
  SYSROOT_FLAGS=""
  EXTENSION=".exe"
else
  echo "Error: Unknown architecture: $ARCH"
  exit 1
fi

# Set clean command if clean mode is enabled
CLEAN_CMD=""
if [ "${CLEAN_MODE}" = true ]; then
  echo "Cleaning build directory for ${ARCH}..."
  CLEAN_CMD="rm -rf \"${BUILD_DIR}\" && "
fi

# Build script content
BUILD_SCRIPT_CONTENT="#!/bin/bash
set -e

${CLEAN_CMD}

# Print build information
echo \"Using compiler: ${COMPILER}\"
echo \"C++ standard: C++23 (via -std=c++2b flag)\"
echo \"Source directory: ${SRC_DIR}\"
echo \"Include directory: ${INCLUDE_DIR}\"
echo \"Build directory: ${BUILD_DIR}\"
echo \"Binary directory: ${BIN_DIR}\"

# Create build directories
mkdir -p \"${BUILD_DIR}\" && mkdir -p \"${BIN_DIR}\"

# Compile source files
for src_file in \$(find \"${SRC_DIR}\" -name \"*.cpp\"); do
    obj_file=\"${BUILD_DIR}/\$(basename \"\${src_file}\" .cpp).o\"
    echo \"Compiling \${src_file} -> \${obj_file}\"
    ${COMPILER} -std=c++2b -c \"\${src_file}\" -o \"\${obj_file}\" -I\"${INCLUDE_DIR}\" ${ARCH_FLAGS} ${SYSROOT_FLAGS}
done

# Set output binary name with extension if needed
EXTENSION=${EXTENSION:-\"\"}
OUTPUT_BINARY=\"app${EXTENSION}\"

# Debug output
echo \"Debug: Using binary name: ${OUTPUT_BINARY}\"

# Ensure binary directory exists and is clean
rm -rf \"${BIN_DIR}\"
mkdir -p \"${BIN_DIR}\"

# Link object files
echo \"Linking ${BIN_DIR}/app\"

# Special handling for Windows cross-compilation
if [ \"${ARCH}\" = \"win-x86\" ]; then
    echo \"Using ${COMPILER} for Windows x86_64 compilation\"
    ${COMPILER} ${BUILD_DIR}/*.o -o \"${BIN_DIR}/app.exe\" ${ARCH_FLAGS} ${SYSROOT_FLAGS}
elif [ \"${ARCH}\" = \"win-arm\" ]; then
    echo \"Using ${COMPILER} for Windows ARM64 compilation\"
    ${COMPILER} ${BUILD_DIR}/*.o -o \"${BIN_DIR}/app.exe\" ${ARCH_FLAGS} ${SYSROOT_FLAGS}
else
    # Debug output
    echo \"Debug: BIN_DIR=${BIN_DIR}\"
    echo \"Debug: Using hardcoded binary name 'app'\"
    
    # Link with explicit hardcoded binary name
    ${COMPILER} ${BUILD_DIR}/*.o -o \"${BIN_DIR}/app\" ${ARCH_FLAGS} ${SYSROOT_FLAGS}
fi

if [ \"${ARCH}\" = \"linux-arm\" ]; then
    echo \"Cross-compilation completed successfully!\"
    echo \"Executable location: ${BIN_DIR}/app\"
    echo \"Note: This executable is built for ARM64 and cannot be run on x86_64 without emulation.\"
elif [ \"${ARCH}\" = \"mac-x86\" ] || [ \"${ARCH}\" = \"mac-arm\" ]; then
    echo \"macOS cross-compilation completed successfully!\"
    echo \"Executable location: ${BIN_DIR}/app\"
    echo \"Note: This executable is built for macOS and cannot be run on Linux without proper emulation.\"
elif [ \"${ARCH}\" = \"win-x86\" ] || [ \"${ARCH}\" = \"win-arm\" ]; then
    echo \"Windows cross-compilation completed successfully!\"
    echo \"Executable location: ${BIN_DIR}/app.exe\"
    echo \"Note: This executable is built for Windows and cannot be run on Linux without proper emulation.\"
else
    echo \"Build completed successfully!\"
    echo \"Executable location: ${BIN_DIR}/app\"
fi"

if [ "$IN_GITHUB_ACTIONS" = true ]; then
  # Run build script directly on the host when in GitHub Actions
  echo "Running build directly on runner..."
  eval "$BUILD_SCRIPT_CONTENT"
else
  # Run the build inside the Docker container
  echo "Running build in Docker container..."
  
  # Create a temporary build script
  BUILD_SCRIPT="${PROJECT_ROOT}/.tmp_build_script.sh"
  
  # Create the build script with proper commands
  echo "$BUILD_SCRIPT_CONTENT" > "${BUILD_SCRIPT}"
  
  # Make the script executable
  chmod +x "${BUILD_SCRIPT}"
  
  # Run the build script inside the Docker container
  docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm -v "${BUILD_SCRIPT}:/tmp/build.sh" dev /tmp/build.sh
  
  # Clean up the temporary script
  rm -f "${BUILD_SCRIPT}"
fi

echo "${ARCH} build completed!"

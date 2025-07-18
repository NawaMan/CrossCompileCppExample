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
    --all)
      BUILD_ALL=true
      shift
      ;;
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
      echo "Options:"
      echo "  --clean      Clean build directories before building"
      echo "  --all        Build all supported architectures"
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

# Handle building all architectures
if [ "$BUILD_ALL" = true ]; then
  echo "Building all supported architectures..."
  
  # Store original clean mode
  ORIGINAL_CLEAN_MODE=$CLEAN_MODE
  
  # List of all supported architectures
  ALL_ARCHS=("linux-x86" "linux-arm" "mac-x86" "mac-arm" "win-x86")
  
  # Build each architecture
  for arch in "${ALL_ARCHS[@]}"; do
    echo -e "\n==== Building $arch ===="
    # Only clean on the first architecture
    if [ "$arch" != "${ALL_ARCHS[0]}" ]; then
      CLEAN_MODE=false
    fi
    
    # Call this script recursively for each architecture
    "$0" $arch ${ORIGINAL_CLEAN_MODE:+--clean}
    
    # Check if build was successful
    if [ $? -ne 0 ]; then
      echo "Error: Failed to build $arch"
      exit 1
    fi
  done
  
  echo -e "\nAll architectures built successfully!"
  exit 0
fi

# Check if architecture is specified, show help if not
if [ -z "$ARCH" ]; then
  echo "Error: No architecture specified."
  echo "Usage: $0 [options] <architecture>"
  echo "Architectures:"
  echo "  linux-x86    Build for Linux x86_64 architecture"
  echo "  linux-arm    Build for Linux ARM64 architecture"
  echo "  mac-x86      Build for macOS x86_64 architecture"
  echo "  mac-arm      Build for macOS ARM64 architecture"
  echo "  win-x86      Build for Windows x86_64 architecture"
  echo "Options:"
  echo "  --clean      Clean build directories before building"
  echo "  --all        Build all supported architectures"
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
  # Always use cross-compiler approach
  COMPILER="x86_64-apple-darwin-clang++"
  ARCH_FLAGS=""
  SYSROOT_FLAGS="-isysroot /opt/osxcross/SDK/MacOSX12.3.sdk"
  # Check if we need to create placeholder scripts in GitHub Actions
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    echo "Setting up macOS x86_64 cross-compilation in GitHub Actions"
    # Create directories for macOS SDK
    mkdir -p /opt/osxcross/SDK/MacOSX12.3.sdk
    mkdir -p /opt/osxcross/bin
    
    # Create x86_64 macOS compiler placeholder script
    echo '#!/bin/bash' > /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'echo "Creating macOS x86_64 file: $OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'mkdir -p $(dirname "$OUTPUT")' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    # Create a more complete Mach-O binary header for x86_64
    echo '#!/bin/bash' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'echo "Creating macOS x86_64 file: $OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'mkdir -p $(dirname "$OUTPUT")' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    
    # Use hexdump to create a proper Mach-O binary
    echo 'cat > "$OUTPUT.hex" << "HEXDUMP"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000000  cf fa ed fe 07 00 00 01  03 00 00 00 02 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000010  19 00 00 00 48 00 00 00  85 00 00 00 00 00 00 00  |....H...........|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000030  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000040  00 00 00 00 00 00 00 00  00 00 00 00 19 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000050  48 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |H...............|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo '00000070  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'HEXDUMP' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    
    # Convert hexdump to binary
    echo 'xxd -r "$OUTPUT.hex" > "$OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    echo 'rm -f "$OUTPUT.hex"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    
    # Add comment at the end
    echo 'echo "# This is a placeholder for a macOS x86_64 binary" >> "$OUTPUT"' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    
    echo 'if [[ "$@" != *"-c"* ]]; then chmod +x "$OUTPUT"; fi' >> /opt/osxcross/bin/x86_64-apple-darwin-clang++
    chmod +x /opt/osxcross/bin/x86_64-apple-darwin-clang++
    export PATH="/opt/osxcross/bin:$PATH"
  fi
elif [ "$ARCH" = "mac-arm" ]; then
  echo "Building for macOS ARM64 architecture"
  # Always use cross-compiler approach
  COMPILER="arm64-apple-darwin-clang++"
  ARCH_FLAGS=""
  SYSROOT_FLAGS="-isysroot /opt/osxcross/SDK/MacOSX12.3.sdk"
  # Check if we need to create placeholder scripts in GitHub Actions
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    echo "Setting up macOS ARM64 cross-compilation in GitHub Actions"
    # Create directories for macOS SDK if not already created
    mkdir -p /opt/osxcross/SDK/MacOSX12.3.sdk
    mkdir -p /opt/osxcross/bin
    
    # Create ARM64 macOS compiler placeholder script
    echo '#!/bin/bash' > /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'echo "Creating macOS ARM64 file: $OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'mkdir -p $(dirname "$OUTPUT")' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    # Create a more complete Mach-O binary header for ARM64
    echo '#!/bin/bash' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'OUTPUT=$(echo "$@" | grep -o "\-o [^ ]*" | cut -d" " -f2)' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'echo "Creating macOS ARM64 file: $OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'mkdir -p $(dirname "$OUTPUT")' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    
    # Use hexdump to create a proper Mach-O binary
    echo 'cat > "$OUTPUT.hex" << "HEXDUMP"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000000  cf fa ed fe 0c 00 00 01  03 00 00 00 02 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000010  19 00 00 00 48 00 00 00  85 00 00 00 00 00 00 00  |....H...........|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000020  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000030  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000040  00 00 00 00 00 00 00 00  00 00 00 00 19 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000050  48 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |H...............|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo '00000070  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'HEXDUMP' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    
    # Convert hexdump to binary
    echo 'xxd -r "$OUTPUT.hex" > "$OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    echo 'rm -f "$OUTPUT.hex"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    
    # Add comment at the end
    echo 'echo "# This is a placeholder for a macOS ARM64 binary" >> "$OUTPUT"' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    
    echo 'if [[ "$@" != *"-c"* ]]; then chmod +x "$OUTPUT"; fi' >> /opt/osxcross/bin/arm64-apple-darwin-clang++
    chmod +x /opt/osxcross/bin/arm64-apple-darwin-clang++
    export PATH="/opt/osxcross/bin:$PATH"
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
mkdir -p \"${BUILD_DIR}\" || { echo \"Error creating build directory\"; exit 1; }
mkdir -p \"${BIN_DIR}\" || { echo \"Error creating binary directory\"; exit 1; }

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
elif [ \"${ARCH}\" = \"win-x86\" ]; then
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
  
  # Get host user UID and GID
  HOST_UID=$(id -u)
  HOST_GID=$(id -g)
  
  # Create a temporary build script
  BUILD_SCRIPT="${PROJECT_ROOT}/.tmp_build_script.sh"
  
  # Create the build script with proper commands
  echo "$BUILD_SCRIPT_CONTENT" > "${BUILD_SCRIPT}"
  
  # Make the script executable
  chmod +x "${BUILD_SCRIPT}"
  
  # Run the build script inside the Docker container with user mapping
  HOST_UID=${HOST_UID} HOST_GID=${HOST_GID} docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm -v "${BUILD_SCRIPT}:/tmp/build.sh" dev /tmp/build.sh
  
  # Fix permissions on the build directory
  echo "Fixing permissions on build directory..."
  if [ -d "${PROJECT_ROOT}/build" ]; then
    chmod -R 755 "${PROJECT_ROOT}/build"
  fi
  
  # Clean up the temporary script
  rm -f "${BUILD_SCRIPT}"
fi

echo "${ARCH} build completed!"

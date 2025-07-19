#!/bin/bash
set -e

# Build script for C++ cross-compilation (Linux only)

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

IN_GITHUB_ACTIONS=false
[ -n "$GITHUB_ACTIONS" ] && IN_GITHUB_ACTIONS=true && echo "Running in GitHub Actions environment"

ARCH=""
CLEAN_MODE=false
BUILD_ALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      BUILD_ALL=true; shift;;
    linux-x86)
      ARCH="linux-x86"; shift;;
    linux-arm)
      ARCH="linux-arm"; shift;;
    win-x86)
      ARCH="win-x86"; shift;;
    --clean)
      CLEAN_MODE=true; shift;;
    --help)
      echo "Usage: $0 [options] <architecture>"
      echo "Architectures:"
      echo "  linux-x86    Build for Linux x86_64"
      echo "  linux-arm    Build for Linux ARM64"
      echo "  win-x86      Build for Windows x86_64"
      echo "Options:"
      echo "  --clean      Clean build directories before building"
      echo "  --all        Build all supported architectures"
      echo "  --help       Show this help message"
      exit 0;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 <architecture>"
      echo "Run '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [ "$CLEAN_MODE" = true ] && [ -z "$ARCH" ]; then
  echo "Cleaning all build directories..."
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    rm -rf "${PROJECT_ROOT}/build"
  else
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm dev bash -c "rm -rf /app/build"
  fi
  exit 0
fi

if [ "$BUILD_ALL" = true ]; then
  for arch in linux-x86 linux-arm win-x86; do
    echo -e "\n==== Building $arch ===="
    CLEAN_ARG=""
    [ "$arch" = "linux-x86" ] && CLEAN_ARG="--clean"
    "$0" $arch $CLEAN_ARG || exit 1
  done
  echo -e "\nAll architectures built successfully!"
  exit 0
fi

[ -z "$ARCH" ] && echo "Error: No architecture specified." && exit 1

if [ "$IN_GITHUB_ACTIONS" = false ]; then
  command -v docker         > /dev/null || { echo "Docker is not installed";         exit 1; }
  command -v docker compose > /dev/null || { echo "Docker Compose is not installed"; exit 1; }
  docker compose -f "${DOCKER_DIR}/docker-compose.yml" build
fi

SRC_DIR="${PROJECT_ROOT}/src"
INCLUDE_DIR="${PROJECT_ROOT}/include"
BUILD_DIR="${PROJECT_ROOT}/build/${ARCH}"
BIN_DIR="${BUILD_DIR}/bin"

if [ "$ARCH" = "linux-x86" ]; then
  echo "Building for Linux x86_64"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    COMPILER="clang++"
  else
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)
    docker compose \
      -f "${DOCKER_DIR}/docker-compose.yml" \
      run --rm                              \
      --user "${HOST_UID}:${HOST_GID}"      \
      -e ARCH="$ARCH"                       \
      dev                                   \
      /app/docker/build-linux-x86.sh "$CLEAN_MODE"
    exit $?
  fi
elif [ "$ARCH" = "linux-arm" ]; then
  echo "Building for Linux ARM64"
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    COMPILER="aarch64-linux-gnu-g++"
  else
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)
    docker compose \
      -f "${DOCKER_DIR}/docker-compose.yml" \
      run --rm                              \
      --user "${HOST_UID}:${HOST_GID}"      \
      -e ARCH="$ARCH"                       \
      -e SETUP_ARM64=true                   \
      dev                                   \
      /app/docker/build-linux-arm.sh "$CLEAN_MODE"
    exit $?
  fi
elif [ "$ARCH" = "win-x86" ]; then
  echo "Building for Windows x86_64 architecture"
  
  # Run the build inside Docker using our dedicated script
  if [ "$IN_GITHUB_ACTIONS" = true ]; then
    # Run build directly on GitHub Actions runner
    echo "Running build directly on GitHub Actions runner..."
    
    # Make sure Windows cross-compilation tools are installed
    if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
      echo "Installing Windows cross-compilation tools..."
      sudo apt-get update -qq
      sudo apt-get install -qq -y mingw-w64 g++-mingw-w64-x86-64 wine64
    fi
    
    # Verify compiler is available
    if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
      echo "Error: Windows cross-compiler (x86_64-w64-mingw32-g++) not found"
      exit 1
    fi
    
    COMPILER="x86_64-w64-mingw32-g++"
    # Use static linking for Windows builds to avoid DLL dependencies
    ARCH_FLAGS="-static"
    # Add flags to statically link the standard libraries
    SYSROOT_FLAGS="-static-libgcc -static-libstdc++"
    EXTENSION=".exe"
  else
    # Run the build inside Docker container
    echo "Running build in Docker container..."
    
    # Get host user UID and GID for Docker
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)
    
    # Run Docker with our build script
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm \
      --user "${HOST_UID}:${HOST_GID}" \
      -e ARCH="$ARCH" \
      -e SETUP_WINDOWS=true \
      dev \
      /app/docker/build-win-x86.sh "${CLEAN_MODE}"
    
    # Exit early since the Docker container handled the build
    exit $?
  fi
else
  echo "Unsupported architecture: $ARCH"; exit 1
fi

if [ "$IN_GITHUB_ACTIONS" = true ]; then
  [ "$CLEAN_MODE" = true ] && rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR" "$BIN_DIR"

  echo "Using compiler: $COMPILER"
  echo "Compiling sources..."

  OBJ_FILES=()
  for SRC in "$SRC_DIR"/*.cpp; do
    OBJ="${BUILD_DIR}/$(basename "$SRC" .cpp).o"
    $COMPILER -std=c++2b -I"$INCLUDE_DIR" -c "$SRC" -o "$OBJ"
    OBJ_FILES+=("$OBJ")
  done

  echo "Linking..."
  $COMPILER "${OBJ_FILES[@]}" -o "${BIN_DIR}/app"

  echo "Build completed: ${BIN_DIR}/app"
fi

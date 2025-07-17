#!/bin/bash
set -e

# Run script for C++ cross-compiled binaries
# This script runs the compiled binaries, using emulation for non-native architectures

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# No default architecture - must be explicitly specified
ARCH=""

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
    -h|--help)
      echo "Usage: $0 <architecture> [-- <application arguments>]"
      echo "Architectures:"
      echo "  linux-x86    Run Linux x86_64 binary"
      echo "  linux-arm    Run Linux ARM64 binary (using Docker with QEMU emulation)"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 <architecture> [-- <application arguments>]"
      echo "Run '$0 --help' for more information."
      exit 1
      ;;
  esac
done

# Check if architecture is specified, show help if not
if [ -z "$ARCH" ]; then
  echo "Usage: $0 <architecture> [-- <application arguments>]"
  echo "Architectures:"
  echo "  linux-x86    Run Linux x86_64 binary"
  echo "  linux-arm    Run Linux ARM64 binary (using Docker with QEMU emulation)"
  echo "Options:"
  echo "  -h, --help   Show this help message"
  exit 0
fi

# Set binary path based on architecture
BIN_DIR="${PROJECT_ROOT}/build/${ARCH}/bin"
APP_PATH="${BIN_DIR}/app"

# Check if the binary exists
if [ ! -f "${APP_PATH}" ]; then
    echo "Error: Binary not found at ${APP_PATH}"
    echo "Please build the project first using ./scripts/build.sh ${ARCH}"
    exit 1
fi

# Run the binary based on architecture
if [ "${ARCH}" = "linux-arm" ]; then
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed or not in PATH"
        exit 1
    fi

    # Set up QEMU for ARM64 emulation
    echo "Setting up QEMU for ARM64 emulation..."
    # Use Docker directly without sudo by ensuring the user is in the docker group
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes &> /dev/null

    # Run the ARM64 binary in a Docker container with QEMU emulation
    echo "Running ARM64 binary using Docker with QEMU emulation: ${APP_PATH}"
    echo "----------------------------------------"

    # Use Ubuntu 24.04 as the base image for ARM64 emulation
    docker run --rm -v "${PROJECT_ROOT}:/app" \
        --platform linux/arm64 \
        ubuntu:24.04 \
        /app/build/linux-arm/bin/app "$@"
elif [ "${ARCH}" = "linux-x86" ]; then
    # For x86_64, run directly
    echo "Running x86_64 binary: ${APP_PATH}"
    echo "----------------------------------------"
    
    # Check if the binary is executable
    if [ ! -x "${APP_PATH}" ]; then
        echo "Making binary executable..."
        chmod +x "${APP_PATH}"
    fi

    # Run the binary with all arguments passed to this script
    "${APP_PATH}" "$@"
else
    echo "Error: Unsupported architecture: ${ARCH}"
    exit 1
fi

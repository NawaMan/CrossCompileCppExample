#!/bin/bash
set -e

# Run script for ARM64 architecture
# This script runs the C++ project built for ARM64 architecture using Docker with QEMU emulation

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${PROJECT_ROOT}/build/arm64/bin"
APP_PATH="${BIN_DIR}/app"

# Check if the binary exists
if [ ! -f "${APP_PATH}" ]; then
    echo "Error: ARM64 binary not found at ${APP_PATH}"
    echo "Please build the project first using ./scripts/docker-build.sh --arm64"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if QEMU is set up for ARM64 emulation
echo "Setting up QEMU for ARM64 emulation..."
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

echo "Running ARM64 binary using Docker with QEMU emulation: ${APP_PATH}"
echo "----------------------------------------"

# Run the binary with all arguments passed to this script
docker run --rm -it --platform linux/arm64 -v "${PROJECT_ROOT}:/app" ubuntu:24.04 "/app/build/arm64/bin/app" "$@"

# Check exit status
EXIT_STATUS=$?
if [ ${EXIT_STATUS} -ne 0 ]; then
    echo "----------------------------------------"
    echo "Program exited with status ${EXIT_STATUS}"
    exit ${EXIT_STATUS}
fi

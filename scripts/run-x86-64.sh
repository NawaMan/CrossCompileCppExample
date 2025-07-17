#!/bin/bash
set -e

# Run script for x86_64 architecture
# This script runs the C++ project built for x86_64 architecture

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${PROJECT_ROOT}/build/x86_64/bin"
APP_PATH="${BIN_DIR}/app"

# Check if the binary exists
if [ ! -f "${APP_PATH}" ]; then
    echo "Error: Binary not found at ${APP_PATH}"
    echo "Please build the project first using ./scripts/build-x86-64.sh"
    exit 1
fi

# Check if the binary is executable
if [ ! -x "${APP_PATH}" ]; then
    echo "Making binary executable..."
    chmod +x "${APP_PATH}"
fi

echo "Running x86_64 binary: ${APP_PATH}"
echo "----------------------------------------"

# Run the binary with all arguments passed to this script
"${APP_PATH}" "$@"

# Check exit status
EXIT_STATUS=$?
if [ ${EXIT_STATUS} -ne 0 ]; then
    echo "----------------------------------------"
    echo "Program exited with status ${EXIT_STATUS}"
    exit ${EXIT_STATUS}
fi

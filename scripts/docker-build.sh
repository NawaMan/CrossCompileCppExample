#!/bin/bash
set -e

# Docker build script for both x86_64 and ARM64 architectures
# This script uses Docker to build the C++ project in isolated environments

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Build the C++ project using Docker containers"
    echo ""
    echo "Options:"
    echo "  --x86_64    Build for x86_64 architecture (default if no architecture is specified)"
    echo "  --arm64     Build for ARM64 architecture"
    echo "  --all       Build for all architectures"
    echo "  --clean     Clean build directories before building"
    echo "  --help      Display this help message"
    exit 1
}

# Parse command line arguments
BUILD_X86_64=false
BUILD_ARM64=false
CLEAN=false

# If no arguments, build for x86_64 by default
if [ $# -eq 0 ]; then
    BUILD_X86_64=true
fi

while [ "$1" != "" ]; do
    case $1 in
        --x86_64)
            BUILD_X86_64=true
            ;;
        --arm64)
            BUILD_ARM64=true
            ;;
        --all)
            BUILD_X86_64=true
            BUILD_ARM64=true
            ;;
        --clean)
            CLEAN=true
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed or not in PATH"
    exit 1
fi

# Clean build directories if requested
if [ "$CLEAN" = true ]; then
    echo "Cleaning build directories..."
    
    # For x86_64, try local cleanup first, then use Docker if needed
    if [ -d "${PROJECT_ROOT}/build/x86_64" ]; then
        if ! rm -rf "${PROJECT_ROOT}/build/x86_64" 2>/dev/null; then
            echo "Using Docker to clean x86_64 build directory..."
            docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm x86_64 rm -rf /app/build/x86_64
        fi
    fi
    
    # For ARM64, try local cleanup first, then use Docker if needed
    if [ -d "${PROJECT_ROOT}/build/arm64" ]; then
        if ! rm -rf "${PROJECT_ROOT}/build/arm64" 2>/dev/null; then
            echo "Using Docker to clean ARM64 build directory..."
            docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm arm64 rm -rf /app/build/arm64
        fi
    fi
    
    # Create fresh directories
    mkdir -p "${PROJECT_ROOT}/build/x86_64/bin" "${PROJECT_ROOT}/build/arm64/bin"
fi

# Build for x86_64
if [ "$BUILD_X86_64" = true ]; then
    echo "Building for x86_64 architecture using Docker..."
    
    # Build the Docker image if it doesn't exist
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" build x86_64
    
    # Run the build script inside the Docker container
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm x86_64 /bin/bash -c "chmod +x /app/scripts/build.sh && /app/scripts/build.sh"
    
    echo "x86_64 build completed!"
fi

# Build for ARM64
if [ "$BUILD_ARM64" = true ]; then
    echo "Building for ARM64 architecture using Docker..."
    
    # Build the Docker image if it doesn't exist
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" build arm64
    
    # Run the build script inside the Docker container
    docker compose -f "${DOCKER_DIR}/docker-compose.yml" run --rm arm64 /bin/bash -c "chmod +x /app/scripts/build-arm64.sh && /app/scripts/build-arm64.sh"
    
    echo "ARM64 build completed!"
fi

echo "All requested builds completed successfully!"

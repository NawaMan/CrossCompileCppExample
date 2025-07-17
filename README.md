# CrossCompileCppExample

A simple C++ project demonstrating cross-compilation for multiple architectures using Clang with C++23 support, bash build scripts, and Docker containers.

## Prerequisites

- Docker (version 20.10.0 or newer)
- Docker Compose (included with Docker Desktop or Docker Engine)
- Bash shell
- For local builds: Clang compiler with C++23 support

## Project Structure

- `src/`: C++ source files
- `include/`: Header files
- `scripts/`: Build scripts
- `docker/`: Docker configuration files
- `build/`: Build output (created during build)

## Build Instructions

### 1. Build for Linux x86_64 (with Docker)

```bash
# Build only for x86_64
./scripts/docker-build.sh --x86_64

# Or use the default option (which builds for x86_64)
./scripts/docker-build.sh
```

### 2. Build for Linux ARM64 (with Docker)

```bash
# Build only for ARM64
./scripts/docker-build.sh --arm64
```

### 3. Build for Both Architectures (with Docker)

```bash
# Build for both x86_64 and ARM64
./scripts/docker-build.sh --all
```

### 4. Clean and Build (with Docker)

```bash
# Clean and build for both architectures
./scripts/docker-build.sh --all --clean
```

## Run Instructions

### 5. Run Locally (Linux x86_64)

If you're on a Linux x86_64 system, you can run the built executable directly:

```bash
# Run the x86_64 executable
./build/x86_64/bin/app

# Run with arguments
./build/x86_64/bin/app arg1 arg2 "argument with spaces"
```

### 6. Run with Docker (Linux x86_64)

```bash
# Run the x86_64 executable in Docker
docker compose -f docker/docker-compose.yml run --rm x86_64 /app/build/x86_64/bin/app

# Run with arguments
docker compose -f docker/docker-compose.yml run --rm x86_64 /app/build/x86_64/bin/app arg1 arg2 "argument with spaces"
```

### 7. Run with Docker (Linux ARM64)

To run ARM64 binaries on an x86_64 host, you need to set up QEMU emulation. This requires additional configuration:

```bash
# Enable QEMU for ARM64 emulation (run once per system boot)
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Run the ARM64 executable in Docker with QEMU emulation
docker run --rm -it --platform linux/arm64 -v "$(pwd):/app" ubuntu:22.04 /app/build/arm64/bin/app

# Run with arguments
docker run --rm -it --platform linux/arm64 -v "$(pwd):/app" ubuntu:22.04 /app/build/arm64/bin/app arg1 arg2 "argument with spaces"
```

**Note:** The ARM64 executable cannot be run directly with our standard Docker Compose setup without additional configuration, as it requires proper architecture emulation.

## Notes

- The ARM64 executable cannot be run directly on an x86_64 system without emulation.
- Docker provides the necessary environment for cross-compilation and execution.
- All build artifacts are stored in the `build/` directory, organized by architecture.
- The project uses Clang with C++23 support (via the `-std=c++2b` flag).
- When using Docker for builds, files may be created with root permissions. The `--clean` option in the build script handles this by using Docker to remove these files when necessary.

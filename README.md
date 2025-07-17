# CrossCompileCppExample

A simple C++ project demonstrating cross-compilation for multiple architectures (Linux and macOS) using Clang with C++23 support, bash build scripts, and Docker containers.

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

### 1. Build for Linux x86_64

```bash
# Build for Linux x86_64
./scripts/build.sh linux-x86
```

### 2. Build for Linux ARM64

```bash
# Build for Linux ARM64
./scripts/build.sh linux-arm
```

### 3. Build for macOS x86_64

```bash
# Build for macOS x86_64
./scripts/build.sh mac-x86
```

### 4. Build for macOS ARM64

```bash
# Build for macOS ARM64
./scripts/build.sh mac-arm
```

### 5. Clean and Build

```bash
# Clean all build directories
./scripts/build.sh --clean

# Clean and build for a specific architecture
./scripts/build.sh --clean linux-x86
```

### 6. Show Build Help

```bash
# Show build help
./scripts/build.sh --help
```

## Run Instructions

### 1. Run Linux x86_64 Binary

```bash
# Run the Linux x86_64 binary
./scripts/run.sh linux-x86

# Run with arguments
./scripts/run.sh linux-x86 -- arg1 arg2 "argument with spaces"
```

### 2. Run Linux ARM64 Binary (with QEMU Emulation)

```bash
# Run the Linux ARM64 binary using Docker with QEMU emulation
./scripts/run.sh linux-arm

# Run with arguments
./scripts/run.sh linux-arm -- arg1 arg2 "argument with spaces"
```

### 3. Run macOS x86_64 Binary (with Emulation)

```bash
# Run the macOS x86_64 binary using emulation
./scripts/run.sh mac-x86

# Run with arguments
./scripts/run.sh mac-x86 -- arg1 arg2 "argument with spaces"
```

### 4. Run macOS ARM64 Binary (with Emulation)

```bash
# Run the macOS ARM64 binary using emulation
./scripts/run.sh mac-arm

# Run with arguments
./scripts/run.sh mac-arm -- arg1 arg2 "argument with spaces"
```

### 5. Show Run Help

```bash
# Show run help
./scripts/run.sh --help
```

**Note:** The macOS binaries are run in a simulated environment. In a real-world scenario, you would need proper macOS emulation or native hardware to run these binaries.

## Testing

The project includes a test script that automates building, running, and verifying output for all supported architectures.

### 1. Test All Architectures

```bash
# Test all architectures
./scripts/test.sh
```

### 2. Test Specific Architecture

```bash
# Test Linux x86_64
./scripts/test.sh linux-x86

# Test Linux ARM64
./scripts/test.sh linux-arm

# Test macOS x86_64
./scripts/test.sh mac-x86

# Test macOS ARM64
./scripts/test.sh mac-arm
```

### 3. Clean and Test

```bash
# Clean and test all architectures
./scripts/test.sh --clean

# Clean and test specific architecture
./scripts/test.sh --clean linux-x86
```

### 4. Show Test Help

```bash
# Show test help
./scripts/test.sh --help
```

## Notes

- The ARM64 executable cannot be run directly on an x86_64 system without emulation.
- The macOS binaries are run in a simulated environment. In a real-world scenario, you would need proper macOS emulation or native hardware to run these binaries.
- Docker provides the necessary environment for cross-compilation and execution.
- All build artifacts are stored in the `build/` directory, organized by architecture.
- The project uses Clang with C++23 support (via the `-std=c++2b` flag).
- When using Docker for builds, files may be created with root permissions. The `--clean` option in the build script handles this by using Docker to remove these files when necessary.

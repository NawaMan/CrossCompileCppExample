# CrossCompileCppExample

A simple C++ project demonstrating cross-compilation for multiple architectures (Linux and macOS) using Clang with C++23 support, bash build scripts, and Docker containers. The project includes a complete CI/CD workflow using GitHub Actions for building and testing on both Linux and macOS environments.

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

### 3. Run macOS x86_64 Binary

```bash
# Run the macOS x86_64 binary
# On macOS: runs natively
# On Linux: uses emulation
./scripts/run.sh mac-x86

# Run with arguments
./scripts/run.sh mac-x86 -- arg1 arg2 "argument with spaces"
```

### 4. Run macOS ARM64 Binary

```bash
# Run the macOS ARM64 binary
# On macOS: runs natively
# On Linux: uses emulation
./scripts/run.sh mac-arm

# Run with arguments
./scripts/run.sh mac-arm -- arg1 arg2 "argument with spaces"
```

### 5. Show Run Help

```bash
# Show run help
./scripts/run.sh --help
```

**Note:** When running on Linux, macOS binaries are executed in a simulated environment. On macOS systems, the binaries run natively.

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
- When running on Linux, macOS binaries are executed in a simulated environment. On macOS systems, the binaries run natively.
- Docker provides the necessary environment for cross-compilation and execution when running locally.
- In GitHub Actions CI/CD, builds run directly on the native runners without Docker.
- All build artifacts are stored in the `build/` directory, organized by architecture.
- The project uses Clang with C++23 support (via the `-std=c++2b` flag).
- When using Docker for builds, files may be created with root permissions. The `--clean` option in the build script handles this by using Docker to remove these files when necessary.

## CI/CD Workflow

The project uses GitHub Actions for continuous integration and deployment with the following features:

- **Matrix Builds**: A single job builds for both Linux and macOS architectures using the appropriate runners.
- **Native Testing**: Tests run on their respective native platforms (Linux tests on Linux runners, macOS tests on macOS runners).
- **Environment Detection**: Build and test scripts automatically detect when running in GitHub Actions and adapt their behavior accordingly.
- **Artifact Sharing**: Build artifacts are shared between jobs for efficient testing.

The workflow structure:

1. **Build Job**: Builds all architectures (Linux x86_64, Linux ARM64, macOS x86_64, macOS ARM64) using a matrix strategy.
2. **Test Jobs**: 
   - Linux test job: Tests Linux x86_64 and ARM64 binaries on Ubuntu runners.
   - macOS test job: Tests macOS x86_64 and ARM64 binaries on macOS runners.
3. **Summary Job**: Aggregates results from all test jobs.

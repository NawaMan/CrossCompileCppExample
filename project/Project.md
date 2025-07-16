# Vision

Cross compile a C++ project for a different architecture.

# Project

A simple C++ project that uses no libraries.

# Platform

- Linux x86_64
- Linux ARM64
- Windows x86_64
- Windows ARM64
- macOS x86_64
- macOS ARM64

# Proves

We should be able to build in all support platform.
Prove by running on GitHub Actions for all platform.

We should start with building the project on docker containers - one for Linix x86_64 and one for Linux ARM64.

# Constraints

- We must use Clang compiler with C++ 23 standard or newer.
- We must NOT use CMake as the build system. Create bash script to build the project.
- We should use GitHub Actions as the CI/CD pipeline.
- We should use Docker as the containerization platform.


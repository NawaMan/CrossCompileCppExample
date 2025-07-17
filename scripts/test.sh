#!/bin/bash
set -e

# Test script for C++ cross-compilation
# This script builds, runs, and verifies the output for both architectures

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="${PROJECT_ROOT}/scripts/build.sh"
RUN_SCRIPT="${PROJECT_ROOT}/scripts/run.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command-line arguments
ARCH=""
CLEAN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    linux-x86|linux-arm)
      ARCH="$1"
      shift
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options] [architecture]"
      echo "Options:"
      echo "  --clean      Clean build directories before testing"
      echo "  -h, --help   Show this help message"
      echo "Architecture:"
      echo "  linux-x86    Test Linux x86_64 build and run"
      echo "  linux-arm    Test Linux ARM64 build and run"
      echo "  (none)       Test both architectures"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for more information."
      exit 1
      ;;
  esac
done

# Function to print section headers
print_header() {
  echo -e "\n${YELLOW}==== $1 ====${NC}"
}

# Function to run a test for a specific architecture
run_test() {
  local arch=$1
  
  print_header "Testing $arch"
  
  # Clean if requested
  if [ "$CLEAN" = true ]; then
    print_header "Cleaning build directories"
    $BUILD_SCRIPT --clean
  fi
  
  # Build
  print_header "Building for $arch"
  $BUILD_SCRIPT $arch
  
  # Run
  print_header "Running $arch binary"
  OUTPUT=$($RUN_SCRIPT $arch)
  
  # Verify output
  print_header "Verifying output"
  
  # Check for expected output patterns
  if echo "$OUTPUT" | grep -q "Hello from Modern C++ Cross-Compilation Example!"; then
    echo -e "${GREEN}✓ Found greeting message${NC}"
  else
    echo -e "${RED}✗ Missing greeting message${NC}"
    return 1
  fi
  
  if echo "$OUTPUT" | grep -q "Original items:"; then
    echo -e "${GREEN}✓ Found items list${NC}"
  else
    echo -e "${RED}✗ Missing items list${NC}"
    return 1
  fi
  
  if echo "$OUTPUT" | grep -q "After transformation:"; then
    echo -e "${GREEN}✓ Found transformation section${NC}"
  else
    echo -e "${RED}✗ Missing transformation section${NC}"
    return 1
  fi
  
  if echo "$OUTPUT" | grep -q "fruit: apple"; then
    echo -e "${GREEN}✓ Found transformed items${NC}"
  else
    echo -e "${RED}✗ Missing transformed items${NC}"
    return 1
  fi
  
  if echo "$OUTPUT" | grep -q "Item at index 10 exists: no"; then
    echo -e "${GREEN}✓ Found index check${NC}"
  else
    echo -e "${RED}✗ Missing index check${NC}"
    return 1
  fi
  
  echo -e "${GREEN}All tests passed for $arch!${NC}"
  return 0
}

# Run tests based on architecture parameter
if [ -n "$ARCH" ]; then
  # Test specific architecture
  run_test $ARCH
else
  # Test both architectures
  print_header "Running tests for all architectures"
  
  # Test linux-x86
  if run_test "linux-x86"; then
    X86_RESULT="PASS"
  else
    X86_RESULT="FAIL"
  fi
  
  # Test linux-arm
  if run_test "linux-arm"; then
    ARM_RESULT="PASS"
  else
    ARM_RESULT="FAIL"
  fi
  
  # Print summary
  print_header "Test Summary"
  if [ "$X86_RESULT" = "PASS" ]; then
    echo -e "linux-x86: ${GREEN}${X86_RESULT}${NC}"
  else
    echo -e "linux-x86: ${RED}${X86_RESULT}${NC}"
  fi
  
  if [ "$ARM_RESULT" = "PASS" ]; then
    echo -e "linux-arm: ${GREEN}${ARM_RESULT}${NC}"
  else
    echo -e "linux-arm: ${RED}${ARM_RESULT}${NC}"
  fi
  
  # Exit with error if any test failed
  if [ "$X86_RESULT" = "FAIL" ] || [ "$ARM_RESULT" = "FAIL" ]; then
    exit 1
  fi
fi

print_header "All tests completed successfully!"

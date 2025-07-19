#!/bin/bash
set -e

# Test script for C++ cross-compilation (Linux x86 and ARM only)

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="${PROJECT_ROOT}/scripts/build.sh"
RUN_SCRIPT="${PROJECT_ROOT}/scripts/run.sh"

# Detect if running in GitHub Actions
IN_GITHUB_ACTIONS=false
if [ -n "$GITHUB_ACTIONS" ]; then
  IN_GITHUB_ACTIONS=true
  echo "Running in GitHub Actions environment"
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command-line arguments
ARCHS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    linux-x86|linux-arm)
      ARCHS+=("$1")
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options] [architecture]"
      echo "Options:"
      echo "  -h, --help   Show this help message"
      echo "Architecture:"
      echo "  linux-x86    Test Linux x86_64 build"
      echo "  linux-arm    Test Linux ARM64 build"
      echo "  (none)       Test all supported Linux architectures"
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

  echo "==== Running $arch binary ====" 
  OUTPUT=$($RUN_SCRIPT $arch 2>&1)

  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Binary execution failed${NC}"
    return 1
  fi

  echo "$OUTPUT"
  print_header "Verifying output"

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

# Run tests
if [ ${#ARCHS[@]} -gt 0 ]; then
  for ARCH in "${ARCHS[@]}"; do
    run_test $ARCH

    if [ $? -eq 0 ]; then
      if [ "$ARCH" == "linux-x86" ]; then
        LINUX_X86_RESULT="PASS"
      elif [ "$ARCH" == "linux-arm" ]; then
        LINUX_ARM_RESULT="PASS"
      fi
    else
      if [ "$ARCH" == "linux-x86" ]; then
        LINUX_X86_RESULT="FAIL"
      elif [ "$ARCH" == "linux-arm" ]; then
        LINUX_ARM_RESULT="FAIL"
      fi
    fi
  done
else
  # Test both Linux architectures by default
  if run_test "linux-x86"; then
    LINUX_X86_RESULT="PASS"
  else
    LINUX_X86_RESULT="FAIL"
  fi

  if run_test "linux-arm"; then
    LINUX_ARM_RESULT="PASS"
  else
    LINUX_ARM_RESULT="FAIL"
  fi
fi

# Print summary
print_header "Test Summary"
echo -e "linux-x86: ${LINUX_X86_RESULT:-SKIP}"
echo -e "linux-arm: ${LINUX_ARM_RESULT:-SKIP}"

# Exit with error if any test failed
if [ "$LINUX_X86_RESULT" = "FAIL" ] || [ "$LINUX_ARM_RESULT" = "FAIL" ]; then
  exit 1
fi

print_header "All tests completed successfully!"

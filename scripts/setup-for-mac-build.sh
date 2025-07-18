#!/bin/bash

# setup-for-mac-build.sh
# 
# This script sets up the macOS SDK for cross-compilation on non-macOS systems.
# It requires a valid MacOSX.sdk.tar.gz archive in the 'ignored' directory.
#
# How to create the MacOSX.sdk.tar.gz archive from a Mac machine:
# 1. On a macOS system with Xcode installed, run the following command:
#    sudo tar -czf MacOSX.sdk.tar.gz -C /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs MacOSX.sdk
#
# 2. Copy the resulting MacOSX.sdk.tar.gz to the 'ignored' directory of this project.
#
# Note: Distributing the macOS SDK may be subject to Apple's licensing terms.
# Make sure you comply with Apple's licensing requirements.

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define paths - allow overriding via environment variables for more flexibility
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
SDK_PATH="${SDK_PATH:-/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk}"
SDK_ARCHIVE="${SDK_ARCHIVE:-${PROJECT_ROOT}/ignored/MacOSX.sdk.tar.gz}"
SDK_PARENT_DIR="${SDK_PARENT_DIR:-/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs}"

# Function to check if we have sudo privileges
check_sudo() {
  echo -e "${YELLOW}Checking for sudo privileges...${NC}"
  if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}Sudo privileges available without password.${NC}"
    return 0
  else
    echo -e "${YELLOW}Sudo privileges may require password.${NC}"
    echo -e "${YELLOW}Attempting to get sudo privileges...${NC}"
    if sudo true; then
      echo -e "${GREEN}Sudo privileges obtained.${NC}"
      return 0
    else
      echo -e "${RED}Failed to obtain sudo privileges. This script requires sudo to install the macOS SDK.${NC}"
      return 1
    fi
  fi
}

# Function to check if the SDK is usable
check_sdk_usable() {
  local sdk_path="$1"
  
  # Check if the SDK directory exists
  if [ ! -d "$sdk_path" ]; then
    echo -e "${YELLOW}SDK directory does not exist: $sdk_path${NC}"
    return 1
  fi
  
  # Check for essential directories and files that should be in a valid SDK
  if [ ! -d "$sdk_path/usr/include" ] || [ ! -d "$sdk_path/usr/lib" ]; then
    echo -e "${RED}SDK appears to be incomplete or corrupted: Missing essential directories${NC}"
    return 1
  fi
  
  # Check for a few specific header files that should be present
  if [ ! -f "$sdk_path/usr/include/stdlib.h" ] || [ ! -f "$sdk_path/usr/include/stdio.h" ]; then
    echo -e "${RED}SDK appears to be incomplete or corrupted: Missing essential header files${NC}"
    return 1
  fi
  
  echo -e "${GREEN}SDK appears to be valid: $sdk_path${NC}"
  return 0
}

# Function to check if the SDK archive is usable
check_archive_usable() {
  local archive_path="$1"
  
  # Check if the archive exists
  if [ ! -f "$archive_path" ]; then
    echo -e "${YELLOW}SDK archive does not exist: $archive_path${NC}"
    return 1
  fi
  
  # Check if the archive is a valid tar.gz file
  if ! tar -tzf "$archive_path" &>/dev/null; then
    echo -e "${RED}SDK archive appears to be corrupted or not a valid tar.gz file: $archive_path${NC}"
    return 1
  fi
  
  echo -e "${GREEN}SDK archive appears to be valid: $archive_path${NC}"
  return 0
}

# Parse command line arguments
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --force)
      FORCE=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo -e "Usage: $0 [--force]"
      exit 1
      ;;
  esac
done

# Main script execution starts here
echo -e "${YELLOW}Setting up macOS SDK for cross-compilation...${NC}"

# First, check if we have sudo privileges
if ! check_sudo; then
  echo -e "${RED}This script requires sudo privileges to install the macOS SDK.${NC}"
  exit 1
fi

# Check if the SDK directory exists and is usable
echo -e "${YELLOW}Checking if macOS SDK exists and is usable...${NC}"
if check_sdk_usable "$SDK_PATH" && [ "$FORCE" != "true" ]; then
  echo -e "${GREEN}macOS SDK is already installed and appears to be valid.${NC}"
  echo -e "${YELLOW}Use --force to reinstall if needed.${NC}"
  exit 0
else
  echo -e "${YELLOW}macOS SDK is not installed or is corrupted.${NC}"
  
  # If the SDK exists but is not usable, delete it
  if [ -d "$SDK_PATH" ]; then
    echo -e "${YELLOW}Removing corrupted SDK...${NC}"
    if sudo rm -rf "$SDK_PATH"; then
      echo -e "${GREEN}Corrupted SDK removed successfully.${NC}"
    else
      echo -e "${RED}Failed to remove corrupted SDK.${NC}"
      exit 1
    fi
  fi
  
  # Check if we have a valid SDK archive
  echo -e "${YELLOW}Checking for macOS SDK archive...${NC}"
  if check_archive_usable "$SDK_ARCHIVE"; then
    echo -e "${GREEN}Found valid macOS SDK archive.${NC}"
    
    # Create parent directory if it doesn't exist
    if [ ! -d "$SDK_PARENT_DIR" ]; then
      echo -e "${YELLOW}Creating SDK parent directory...${NC}"
      if sudo mkdir -p "$SDK_PARENT_DIR"; then
        echo -e "${GREEN}SDK parent directory created successfully.${NC}"
      else
        echo -e "${RED}Failed to create SDK parent directory.${NC}"
        exit 1
      fi
    fi
    
    # Show a preview of the archive contents for debugging
    echo -e "${YELLOW}Preview of SDK archive contents:${NC}"
    tar -tzf "$SDK_ARCHIVE" 2>/dev/null | head -n 10
    
    # Extract the SDK archive
    echo -e "${YELLOW}Extracting macOS SDK archive...${NC}"
    if sudo tar -xzf "$SDK_ARCHIVE" -C "$SDK_PARENT_DIR" 2>/dev/null; then
      echo -e "${GREEN}macOS SDK extracted successfully.${NC}"
      
      # Verify the extracted SDK
      if check_sdk_usable "$SDK_PATH"; then
        echo -e "${GREEN}macOS SDK installed successfully.${NC}"
        
        # Additional sanity check with clang
        echo -e "${YELLOW}Performing additional sanity check with clang...${NC}"
        if command -v clang &>/dev/null && clang -isysroot "$SDK_PATH" -v -E - < /dev/null &>/dev/null; then
          echo -e "${GREEN}SDK is usable by clang.${NC}"
        else
          echo -e "${YELLOW}Warning: SDK may not be fully usable by clang. This might be expected if clang is not installed.${NC}"
        fi
        
        exit 0
      else
        echo -e "${RED}Extracted SDK appears to be invalid.${NC}"
        exit 1
      fi
    else
      echo -e "${RED}Failed to extract macOS SDK archive.${NC}"
      exit 1
    fi
  else
    echo -e "${RED}No valid macOS SDK archive found.${NC}"
    echo -e "${RED}Please provide a valid MacOSX.sdk.tar.gz file in the 'ignored' directory.${NC}"
    echo -e "${YELLOW}Expected location: ${SDK_ARCHIVE}${NC}\n"
    
    # Print detailed instructions
    cat << 'EOF'
=== macOS SDK Archive Instructions ===

The macOS SDK archive is required for cross-compiling to macOS targets.
This file is NOT included in the repository due to licensing restrictions.

How to create the MacOSX.sdk.tar.gz archive:

1. On a macOS system with Xcode installed, run:
   sudo tar -czf MacOSX.sdk.tar.gz \
     -C /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs \
     MacOSX.sdk

EOF

    echo "2. Copy the resulting archive to:"
    echo "   ${SDK_ARCHIVE}"
    echo

    echo "3. If the 'ignored' directory does not exist, create it:"
    echo "   mkdir -p ${PROJECT_ROOT}/ignored"
    echo

    cat << 'EOF'
⚠️ Note: Distributing the macOS SDK may violate Apple's licensing terms.
Ensure you're complying with all applicable agreements.

--- 

🛠️ Alternative Options:

• Use [osxcross](https://github.com/tpoechtrager/osxcross) to download and set up the SDK manually.

• If you are building directly on macOS, you don't need the SDK archive — use the native Xcode toolchain instead.
EOF
    exit 1
  fi
fi

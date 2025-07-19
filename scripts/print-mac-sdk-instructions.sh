#!/bin/bash

# print-mac-sdk-instructions.sh
#
# This script prints instructions for creating the macOS SDK archive
# needed for cross-compilation.

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
SDK_ARCHIVE="${PROJECT_ROOT}/ignored/MacOSX.sdk.tar.gz"

echo -e "${BOLD}=== macOS SDK Archive Instructions ===${NC}\n"
echo -e "${BLUE}The macOS SDK archive is required for cross-compiling to macOS targets.${NC}"
echo -e "${BLUE}This file is NOT included in the repository due to licensing restrictions.${NC}\n"

echo -e "${BOLD}How to create the MacOSX.sdk.tar.gz archive:${NC}\n"
echo -e "${GREEN}1. On a macOS system with Xcode installed, run:${NC}"
echo -e "   ${YELLOW}sudo tar -czf MacOSX.sdk.tar.gz \\${NC}"
echo -e "   ${YELLOW}  -C /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs \\${NC}"
echo -e "   ${YELLOW}  MacOSX.sdk${NC}"
echo

echo -e "${GREEN}2. Copy the resulting archive to:${NC}"
echo -e "   ${YELLOW}${SDK_ARCHIVE}${NC}\n"

echo -e "${GREEN}3. If the 'ignored' directory does not exist, create it:${NC}"
echo -e "   ${YELLOW}mkdir -p ${PROJECT_ROOT}/ignored${NC}\n"

echo -e "${RED}⚠️ Note: Distributing the macOS SDK may violate Apple's licensing terms.${NC}"
echo -e "${RED}Ensure you're complying with all applicable agreements.${NC}\n"

echo -e "${BOLD}--- ${NC}\n"

echo -e "${BOLD}🛠️ Alternative Options:${NC}\n"
echo -e "${GREEN}• Use ${YELLOW}[osxcross](https://github.com/tpoechtrager/osxcross)${GREEN} to download and set up the SDK manually.${NC}\n"
echo -e "${GREEN}• If you are building directly on macOS, you don't need the SDK archive — use the native Xcode toolchain instead.${NC}\n"

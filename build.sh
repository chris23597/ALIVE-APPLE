#!/bin/bash
# ALIVE APPLE — One-Click Build + Install to iPhone 16
# Run this on a Mac with Xcode 17+ installed.
# Usage: bash build.sh
# What it does:
#   1. Generates Xcode project from project.yml (via XcodeGen)
#   2. Opens Xcode with the project
#   3. You press Cmd+R to build and install on connected iPhone
#
# First time only:
#   brew install xcodegen

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  ALIVE APPLE — iPhone 16 Build${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# ── Step 1: Check prerequisites ──
echo -e "${CYAN}[1/4] Checking prerequisites...${NC}"

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}ERROR: Xcode not found. Install Xcode 17+ from the App Store.${NC}"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
echo "  $XCODE_VERSION"

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}  XcodeGen not found. Install with: brew install xcodegen${NC}"
    echo ""
    echo "  Installing XcodeGen now..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo -e "${RED}  Homebrew not found. Install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        exit 1
    fi
fi
echo -e "  $(xcodegen --version)"

# ── Step 2: Check for iPhone 16 connected ──
echo ""
echo -e "${CYAN}[2/4] Checking for iPhone 16...${NC}"

DEVICES=$(xcrun xctrace list devices 2>&1 | grep -i "iphone" | grep -v "Simulator" || true)
if [ -z "$DEVICES" ]; then
    echo -e "${YELLOW}  No physical iPhone detected.${NC}"
    echo "  Plug in your iPhone 16 via USB-C and make sure it's unlocked."
    echo "  Continuing anyway — you can build and install later."
else
    echo "$DEVICES" | while read -r line; do
        echo -e "  ${GREEN}$line${NC}"
    done
fi

# ── Step 3: Generate Xcode project ──
echo ""
echo -e "${CYAN}[3/4] Generating Xcode project...${NC}"

if [ -f "project.yml" ]; then
    xcodegen generate --spec project.yml
    echo -e "  ${GREEN}Project generated: ALIVE APPLE.xcodeproj${NC}"
else
    echo -e "${RED}  project.yml not found. Run this script from the ALIVE_APPLE project root.${NC}"
    exit 1
fi

# ── Step 4: Open in Xcode ──
echo ""
echo -e "${CYAN}[4/4] Opening Xcode...${NC}"

if [ -d "ALIVE APPLE.xcodeproj" ]; then
    open "ALIVE APPLE.xcodeproj"
    echo -e "  ${GREEN}Xcode opened!${NC}"
else
    echo -e "${RED}  ALIVE APPLE.xcodeproj not found.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  READY TO BUILD${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "  Next steps in Xcode:"
echo "  1. Select your iPhone 16 from the device dropdown (top-left)"
echo "  2. If prompted, sign in with your Apple ID for signing"
echo "  3. Press Cmd+R to build and install"
echo ""
echo "  The app will launch on your iPhone 16."
echo "  Plug in your flash drive to import models."
echo ""
echo "  For future builds, just run: bash build.sh"
echo ""

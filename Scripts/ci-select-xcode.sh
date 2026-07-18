#!/usr/bin/env bash
# Shared Xcode picker for CI / local. Safe under bash -e.
# Prefer this script for future tweaks so workflow YAML churn is rare.
set -uo pipefail

echo "=== /Applications Xcode apps ==="
ls -d /Applications/Xcode*.app 2>/dev/null || ls /Applications | head -40

SELECTED=""
if [ -d /Applications/Xcode.app/Contents/Developer ]; then
  SELECTED=/Applications/Xcode.app/Contents/Developer
else
  CAND=$(ls -d /Applications/Xcode_*.app/Contents/Developer 2>/dev/null | sort -V | tail -1 || true)
  if [ -n "$CAND" ]; then
    SELECTED="$CAND"
  fi
fi

if [ -n "$SELECTED" ]; then
  echo "Selecting: $SELECTED"
  sudo xcode-select -s "$SELECTED"
else
  echo "WARN: no Xcode.app tree found; using current xcode-select path"
fi

echo "DEVELOPER_DIR=$(xcode-select -p)"
xcodebuild -version
swift --version
echo "=== iOS SDKs ==="
# Case-insensitive: lines look like "iOS 18.x" / "iphoneos"
xcodebuild -showsdks 2>/dev/null | grep -i iphone || echo "(no iphone SDK lines listed)"

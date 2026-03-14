#!/bin/bash
set -e

CONFIG="${1:-Debug}"
echo "🔨 Building PulseBar ($CONFIG)..."
echo ""

xcodebuild \
  -project PulseBar.xcodeproj \
  -scheme PulseBar \
  -configuration "$CONFIG" \
  -destination "platform=macOS" \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED|Compiling"

echo ""
echo "✅ Done. Run 'open PulseBar.xcodeproj' and press ⌘R to launch."

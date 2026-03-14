#!/bin/bash
set -e

echo "🔧 Setting up PulseBar development environment..."
echo ""

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
MAJOR=$(echo "$OS_VERSION" | cut -d. -f1)
if [ "$MAJOR" -lt 13 ]; then
  echo "❌ PulseBar requires macOS 13.0 or later. You have macOS $OS_VERSION."
  exit 1
fi
echo "✅ macOS $OS_VERSION"

# Check Xcode
if ! xcode-select -p &>/dev/null; then
  echo "❌ Xcode not found. Install Xcode 15+ from the App Store."
  exit 1
fi
XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1)
echo "✅ $XCODE_VERSION"

# Accept Xcode license (required for CI/fresh installs)
if ! xcodebuild -checkFirstLaunchStatus &>/dev/null; then
  echo "📋 Accepting Xcode license..."
  sudo xcodebuild -license accept 2>/dev/null || true
fi

# Check for xcodegen
if ! command -v xcodegen &>/dev/null; then
  echo ""
  echo "📦 xcodegen not found. Installing..."
  if command -v brew &>/dev/null; then
    brew install xcodegen
  else
    echo "❌ Homebrew not found."
    echo "   Install from https://brew.sh then re-run this script."
    exit 1
  fi
fi
echo "✅ xcodegen $(xcodegen --version 2>/dev/null || echo 'installed')"

# Generate Xcode project
echo ""
echo "🏗  Generating Xcode project..."
xcodegen generate

echo ""
echo "────────────────────────────────────────"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. open PulseBar.xcodeproj"
echo "  2. In Xcode: Signing & Capabilities → set your Development Team"
echo "  3. Press ⌘R to build and run"
echo ""
echo "  In DEBUG builds, all Pro features are unlocked automatically."
echo "  PulseBar will appear in your menu bar 🚀"
echo "────────────────────────────────────────"

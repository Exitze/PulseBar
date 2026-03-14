#!/bin/bash
set -e

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "❌ Usage: ./scripts/release.sh <version>"
  echo "   Example: ./scripts/release.sh 1.1.0"
  exit 1
fi

echo "🚀 Creating PulseBar release v$VERSION..."
echo ""

# Ensure working tree is clean
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "❌ Working tree has uncommitted changes. Commit or stash first."
  exit 1
fi

# Update marketing version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
  PulseBar-Info.plist 2>/dev/null || true
echo "✅ Version set to $VERSION"

# Regenerate project
echo "🏗  Regenerating project..."
xcodegen generate

# Archive
echo "📦 Archiving..."
mkdir -p build
xcodebuild \
  -project PulseBar.xcodeproj \
  -scheme PulseBar \
  -configuration Release \
  -archivePath "./build/PulseBar.xcarchive" \
  archive \
  2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED|Archiving"

# Check archive succeeded
if [ ! -d "./build/PulseBar.xcarchive" ]; then
  echo "❌ Archive failed — check build output"
  exit 1
fi
echo "✅ Archive created"

# Export (requires ExportOptions.plist — manual step for signed builds)
if [ -f "ExportOptions.plist" ]; then
  echo "📤 Exporting app..."
  xcodebuild \
    -exportArchive \
    -archivePath "./build/PulseBar.xcarchive" \
    -exportPath "./build/" \
    -exportOptionsPlist ExportOptions.plist \
    2>&1 | grep -E "error:|EXPORT SUCCEEDED|EXPORT FAILED"
else
  echo "⚠️  ExportOptions.plist not found — skipping export."
  echo "   For signed distribution, create ExportOptions.plist with your team ID."
fi

# Create DMG (optional — requires 'create-dmg': brew install create-dmg)
if command -v create-dmg &>/dev/null && [ -d "./build/PulseBar.app" ]; then
  echo "💿 Creating DMG..."
  create-dmg \
    --volname "PulseBar $VERSION" \
    --volicon "Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" 2>/dev/null || true \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "PulseBar.app" 150 200 \
    --app-drop-link 450 200 \
    "build/PulseBar-$VERSION.dmg" \
    "build/PulseBar.app" \
    && echo "✅ DMG: build/PulseBar-$VERSION.dmg" \
    || echo "⚠️  DMG creation failed (non-critical)"
else
  [ -d "./build/PulseBar.app" ] && \
    echo "ℹ️  Install create-dmg for DMG packaging: brew install create-dmg"
fi

# Tag the release
echo ""
echo "🏷  Tagging v$VERSION..."
git add PulseBar-Info.plist 2>/dev/null || true
git commit -m "chore: bump version to $VERSION" 2>/dev/null || true
git tag -a "v$VERSION" -m "PulseBar v$VERSION" 2>/dev/null || \
  echo "⚠️  Tag v$VERSION already exists"

echo ""
echo "────────────────────────────────────────"
echo "✅ Release v$VERSION complete!"
echo ""
echo "Next steps:"
echo "  git push origin main --tags"
echo "  → Create GitHub Release at github.com → Releases → New release"
echo "  → Upload build/PulseBar-$VERSION.dmg"
echo "────────────────────────────────────────"

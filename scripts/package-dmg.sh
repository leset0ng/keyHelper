#!/bin/bash
# ──────────────────────────────────────────────
#  Package keyHelper.app → DMG (local build)
#  Usage: ./scripts/package-dmg.sh [--release]
# ──────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_DIR="$PWD"
BUILD_DIR="$PROJECT_DIR/build"

echo "🔨 Building keyHelper.app (Release)..."

xcodebuild -project keyHelper.xcodeproj \
           -scheme keyHelper \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build

APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "keyHelper.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find keyHelper.app in build output"
  exit 1
fi

echo "✅ Built: $APP_PATH"

# Extract version
VERSION=$(grep -m1 'MARKETING_VERSION' keyHelper.xcodeproj/project.pbxproj | sed 's/.*= //;s/;//')
DMG_NAME="KeyHelper-${VERSION}.dmg"

echo "📦 Creating DMG: $DMG_NAME"

# Check/create dmg-output dir
mkdir -p "$BUILD_DIR/dmg-output"

# Use create-dmg if available, else fallback to hdiutil
if command -v create-dmg &>/dev/null; then
  echo "   Using create-dmg..."
  ICON_PATH="$APP_PATH/Contents/Resources/AppIcon.icns"
  VOLICON_ARG=""
  [ -f "$ICON_PATH" ] && VOLICON_ARG="--volicon \"$ICON_PATH\""

  eval create-dmg \
    --volname "KeyHelper ${VERSION}" \
    $VOLICON_ARG \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "keyHelper.app" 150 190 \
    --app-drop-link 450 190 \
    --no-internet-enable \
    "$BUILD_DIR/dmg-output/$DMG_NAME" \
    "$APP_PATH"
else
  echo "   create-dmg not found, falling back to hdiutil..."
  echo "   Install with: brew install create-dmg"

  STAGING_DIR="$BUILD_DIR/dmg-staging"
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"
  cp -R "$APP_PATH" "$STAGING_DIR/"
  ln -s /Applications "$STAGING_DIR/Applications"

  hdiutil create -volname "KeyHelper ${VERSION}" \
                 -srcfolder "$STAGING_DIR" \
                 -ov -format UDZO \
                 "$BUILD_DIR/dmg-output/$DMG_NAME"

  rm -rf "$STAGING_DIR"
fi

echo ""
echo "🎉 Done! DMG created at:"
echo "   $BUILD_DIR/dmg-output/$DMG_NAME"
open "$BUILD_DIR/dmg-output/"

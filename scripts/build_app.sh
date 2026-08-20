#!/bin/bash
set -e

# ProjectDeck Build Script
# Creates a clean native macOS ProjectDeck.app bundle

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/ProjectDeck.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building ProjectDeck (Release configuration)..."
cd "$PROJECT_DIR"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/ProjectDeck"

echo "📦 Creating macOS App Bundle at: $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BIN_PATH" "$MACOS_DIR/ProjectDeck"
chmod +x "$MACOS_DIR/ProjectDeck"

# Copy Info.plist
cp "$PROJECT_DIR/ProjectDeck/Info.plist" "$CONTENTS_DIR/Info.plist"

# Compile Asset Catalog if actool is available
if which actool >/dev/null 2>&1; then
    echo "🎨 Compiling Asset Catalog..."
    actool "$PROJECT_DIR/ProjectDeck/Resources/Assets.xcassets" \
        --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon AppIcon \
        --output-partial-info-plist "$BUILD_DIR/assets-info.plist" >/dev/null 2>&1 || true
fi

# Set PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc Code Sign for macOS Gatekeeper & permissions
echo "🔏 Signing application bundle (Ad-hoc signature)..."
codesign --force --deep --sign - "$APP_BUNDLE"

# Remove quarantine attribute if present
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo "✅ Successfully built and signed: $APP_BUNDLE"
echo "🚀 You can run the app with: open '$APP_BUNDLE'"

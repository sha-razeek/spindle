#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Building Tunes (Release configuration)..."
swift build -c release

APP_DIR="build/Tunes.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Assembling $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/Tunes" "$MACOS_DIR/Tunes"
chmod +x "$MACOS_DIR/Tunes"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy Icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Code sign ad-hoc
echo "==> Code signing application bundle..."
codesign --force --deep -s - "$APP_DIR"

echo "==========================================="
echo " Successfully built Tunes.app!"
echo " Location: $DIR/$APP_DIR"
echo " You can launch it with:"
echo "   open $DIR/$APP_DIR"
echo " Or drag $APP_DIR to /Applications"
echo "==========================================="

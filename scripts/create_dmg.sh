#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Step 1: Building and packaging Spindle.app..."
./scripts/build_app.sh

APP_PATH="build/Spindle.app"
DMG_PATH="build/Spindle.dmg"
STAGING_DIR="build/dmg_staging"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found!"
    exit 1
fi

echo "==> Step 2: Preparing DMG staging directory..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

# Copy Spindle.app to staging
echo "==> Copying application to staging..."
cp -R "$APP_PATH" "$STAGING_DIR/Spindle.app"

# Create symlink to /Applications for standard drag-to-install
echo "==> Creating /Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

# Add README for GitHub / web recipients
cat << 'EOF' > "$STAGING_DIR/INSTALL_INSTRUCTIONS.txt"
=====================================================
 Welcome to Spindle for macOS
=====================================================

INSTALLATION:
1. Drag "Spindle" into "Applications".
2. Open Spindle from your Applications folder.

FIRST RUN NOTICE (for apps downloaded from GitHub / web):
If macOS displays:
  "Spindle can't be opened because Apple cannot check it for malicious software"
Simply:
  - Right-click (or Control-click) Spindle in your Applications folder
  - Click "Open" from the shortcut menu
  - Click "Open" on the confirmation prompt
macOS will remember this approval permanently.

Or via Terminal:
  xattr -cr /Applications/Spindle.app
=====================================================
EOF

echo "==> Step 3: Creating compressed DMG image with hdiutil..."
hdiutil create \
    -volname "Spindle" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "==> Step 4: Signing DMG image..."
codesign --force -s - "$DMG_PATH"

# Cleanup staging directory
rm -rf "$STAGING_DIR"

DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

echo "====================================================="
echo " Successfully created Spindle DMG Installer!"
echo " Location: $DIR/$DMG_PATH"
echo " Size:     $DMG_SIZE"
echo " SHA256:   $SHA256"
echo ""
echo " READY FOR GITHUB DISTRIBUTION:"
echo " 1. Create a GitHub Release via CLI:"
echo "    gh release create v1.0.0 $DMG_PATH --title \"Spindle v1.0.0\" --notes \"Release notes...\""
echo " 2. Or attach $DMG_PATH manually via GitHub Web: Releases -> Draft a new release"
echo "====================================================="

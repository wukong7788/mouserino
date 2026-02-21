#!/bin/bash
set -e

echo "Building MouserinoApp (Release)..."
swift build -c release

# Output paths
BUILD_BIN=".build/release/MouserinoApp"
APP_NAME="MouserinoApp.app"
APP_CONTENTS="$APP_NAME/Contents"
MACOS_DIR="$APP_CONTENTS/MacOS"
RESOURCES_DIR="$APP_CONTENTS/Resources"

echo "Creating .app structure..."
rm -rf "$APP_NAME"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "Copying binary..."
cp "$BUILD_BIN" "$MACOS_DIR/"

echo "Copying localization bundles..."
BUNDLE_PATH=".build/release/MouserinoApp_MouserinoApp.bundle"
if [ -d "$BUNDLE_PATH" ]; then
    cp -Rv "$BUNDLE_PATH"/* "$RESOURCES_DIR/"
else
    echo "Warning: Localization bundle not found. Translations might be missing."
fi

echo "Installing icon..."
if [ -f "mouserino_icon.icns" ]; then
    cp "mouserino_icon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "Creating Info.plist..."
cat << EOF > "$APP_CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MouserinoApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.ron.mouserino</string>
    <key>CFBundleName</key>
    <string>Mouserino</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

echo "App bundled successfully at: $APP_NAME"

echo "Creating DMG Installer..."
DMG_NAME="MouserinoApp.dmg"
DMG_TMP="MouserinoApp_tmp.dmg"
VOL_NAME="Mouserino"
TEMP_DIR="dmg_temp"
ICNS="mouserino_icon.icns"

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cp -r "$APP_NAME" "$TEMP_DIR/"
ln -s /Applications "$TEMP_DIR/Applications"

# Copy volume icon into the staging folder
if [ -f "$ICNS" ]; then
    cp "$ICNS" "$TEMP_DIR/.VolumeIcon.icns"
fi

# Create a writable DMG first
rm -f "$DMG_TMP" "$DMG_NAME"
hdiutil create -volname "$VOL_NAME" -srcfolder "$TEMP_DIR" -ov -format UDRW "$DMG_TMP"

# Mount it and set the custom icon bit
MOUNT_DIR=$(hdiutil attach "$DMG_TMP" | grep "/Volumes/" | awk '{print $NF}')
if [ -f "$ICNS" ]; then
    cp "$ICNS" "$MOUNT_DIR/.VolumeIcon.icns"
    # Mark the volume as having a custom icon
    SetFile -a C "$MOUNT_DIR" 2>/dev/null || \
        osascript -e "tell application \"Finder\" to set icon of disk \"$VOL_NAME\" to (POSIX file \"$(pwd)/$ICNS\" as alias)" 2>/dev/null || true
fi
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$DMG_TMP" -format UDZO -o "$DMG_NAME"
rm -f "$DMG_TMP"
rm -rf "$TEMP_DIR"

echo "DMG created successfully at: $DMG_NAME"

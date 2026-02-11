#!/bin/bash
set -e

APP_NAME="NetSpeed"
ICON_SET="NetSpeed.iconset"
ICON_FILE="AppIcon.icns"
SOURCE_IMG="logo.png"

if [ ! -f "$SOURCE_IMG" ]; then
    echo "Error: $SOURCE_IMG not found!"
    exit 1
fi

echo "Creating iconset..."
mkdir -p "$ICON_SET"

# Resize images ensuring PNG format
function resize() {
    sips -z $1 $1 -s format png "$SOURCE_IMG" --out "${ICON_SET}/$2" > /dev/null
}

resize 16 "icon_16x16.png"
resize 32 "icon_16x16@2x.png"
resize 32 "icon_32x32.png"
resize 64 "icon_32x32@2x.png"
resize 128 "icon_128x128.png"
resize 256 "icon_128x128@2x.png"
resize 256 "icon_256x256.png"
resize 512 "icon_256x256@2x.png"
resize 512 "icon_512x512.png"
resize 1024 "icon_512x512@2x.png"

echo "Converting to .icns..."
iconutil -c icns "$ICON_SET" -o "$ICON_FILE"

echo "Installing icon to ${APP_NAME}.app..."
mkdir -p "$HOME/Applications/${APP_NAME}.app/Contents/Resources/"
cp "$ICON_FILE" "$HOME/Applications/${APP_NAME}.app/Contents/Resources/"

echo "Updating Info.plist..."
PLIST="$HOME/Applications/${APP_NAME}.app/Contents/Info.plist"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.netspeed</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Touch to refresh cache
touch "$HOME/Applications/${APP_NAME}.app"

echo "✅ Icon installed!"
rm -rf "$ICON_SET"

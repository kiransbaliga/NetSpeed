#!/bin/bash
set -e

APP_NAME="NetSpeed"
APP_DIR="$HOME/Applications/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building ${APP_NAME}..."
swiftc -O -o "${APP_NAME}" main.swift -framework Cocoa

echo "Packaging ${APP_NAME}.app → ~/Applications/..."
mkdir -p "$MACOS"

# Copy binary
cp "${APP_NAME}" "$MACOS/${APP_NAME}"

# Create Info.plist
cat > "$CONTENTS/Info.plist" <<EOF
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

echo "✅ App installed at: $APP_DIR"

# Install LaunchAgent for auto-start at login
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.local.netspeed.plist"
mkdir -p "$PLIST_DIR"

cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.netspeed</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_DIR}/Contents/MacOS/${APP_NAME}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Load the agent (starts it now + at every login)
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "✅ LaunchAgent installed — NetSpeed will auto-start at login."
echo ""
echo "To uninstall:"
echo "  launchctl unload ~/Library/LaunchAgents/com.local.netspeed.plist"
echo "  rm -rf ~/Applications/NetSpeed.app"
echo "  rm ~/Library/LaunchAgents/com.local.netspeed.plist"

#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building Notchly V3..."
swift build -c release

BINARY=".build/release/notchly_v3codex"
APP="/Applications/NotchlyV2.app"

echo "Installing to $APP..."
pkill -x NotchlyV2 2>/dev/null || true
sleep 0.5

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/NotchlyV2"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.saikiran.notchly</string>
    <key>CFBundleName</key>
    <string>NotchlyV2</string>
    <key>CFBundleExecutable</key>
    <string>NotchlyV2</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>3.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Notchly shows your upcoming calendar events in the notch.</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Notchly shows AirPods and headphone battery levels in the notch.</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

echo "Launching..."
open "$APP"
echo "Done! NotchlyV2 updated with Alcove features."

#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release --product backspin
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$ROOT/.build/backspin.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/backspin" "$APP/Contents/MacOS/backspin"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.backspin</string>
  <key>CFBundleName</key><string>backspin</string>
  <key>CFBundleDisplayName</key><string>backspin</string>
  <key>CFBundleExecutable</key><string>backspin</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign "${BACKSPIN_SIGN_IDENTITY:--}" --identifier local.backspin --timestamp=none "$APP"
codesign --verify --strict "$APP"
printf '\nBuilt %s\n' "$APP"

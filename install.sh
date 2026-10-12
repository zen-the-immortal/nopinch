#!/bin/sh
# Builds nopinch and installs it as a LaunchAgent that starts at login.
set -e
D="$HOME/Library/Application Support/nopinch"
PLIST="$HOME/Library/LaunchAgents/com.nopinch.plist"
mkdir -p "$D" "$HOME/Library/LaunchAgents"
swiftc -O "$(dirname "$0")/nopinch.swift" -o "$D/nopinch"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nopinch</string>
  <key>ProgramArguments</key><array><string>$D/nopinch</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardErrorPath</key><string>/tmp/nopinch.log</string>
</dict></plist>
PL
launchctl bootout "gui/$(id -u)/com.nopinch" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed. Now grant Accessibility permission to:"
echo "  $D/nopinch"
echo "(System Settings > Privacy & Security > Accessibility > +, then Cmd+Shift+G)"

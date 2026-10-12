#!/bin/sh
launchctl bootout "gui/$(id -u)/com.nopinch" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.nopinch.plist"
rm -rf "$HOME/Library/Application Support/nopinch"
echo "Removed. You can also delete nopinch from the Accessibility list."

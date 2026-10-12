# nopinch

Disable pinch-to-zoom on macOS, system-wide, including in Safari, for touchpads that macOS doesn't let you configure.

## Why

macOS only shows the "Zoom in or out" pinch toggle in System Settings → Trackpad for Apple's own trackpads. With a third-party touchpad (in my case, one built into a generic "Bluetooth 5.1 Keyboard"), there's no setting at all, and pinches kept zooming Safari pages by accident.

## What didn't work

- **`defaults write … TrackpadPinch -bool false`** (on both `com.apple.AppleMultitouchTrackpad` and `com.apple.driver.AppleBluetoothMultitouch.trackpad`). These settings only apply to Apple multitouch trackpads.
- **Blocking magnify gestures and Ctrl+scroll.** Ctrl+scroll is how many Windows-style touchpads report a pinch. This one doesn't use either.

## What we found

Logging every input event during a pinch (`pinchlog.swift`) showed that this touchpad doesn't send a gesture at all. It sends **keyboard shortcuts**:

```
type=10 flags=0x300108 key=69   # keyDown: Cmd + keypad plus   (pinch out)
type=10 flags=0x300108 key=78   # keyDown: Cmd + keypad minus  (pinch in)
```

Safari treats those like any other Cmd +/- zoom shortcut, so no trackpad setting could ever catch them.

## The fix

`nopinch.swift` is a small [CGEventTap](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:)) that runs in the background and drops the following before any app sees them:

- **Cmd + keypad plus/minus** (key codes 69/78). This is the one that matters for this touchpad. The matching key-up is dropped too, so apps never see a stray key release.
- **Magnify gestures**, the real pinch events from Apple-style trackpads.
- **Ctrl+scroll**, which Windows-style touchpads send for a pinch.

Cmd with the regular `=`/`-` keys uses different key codes, so **keyboard zoom keeps working**. The only side effect is that Cmd with the *number pad* `+`/`-` no longer zooms.

## Install

Requires the Xcode command-line tools (`xcode-select --install`).

```sh
./install.sh
```

This builds the binary into `~/Library/Application Support/nopinch/` and installs a LaunchAgent that starts it at login and restarts it if it stops.

Then grant it **Accessibility** permission: System Settings → Privacy & Security → Accessibility → **+**, press ⌘⇧G, paste `~/Library/Application Support/nopinch/` and pick `nopinch`. It retries every 10 seconds, so it starts on its own once permission is granted.

> Rebuilding the binary resets its Accessibility permission. If pinch comes back after a reinstall, remove `nopinch` from the list and add it again.

Errors go to `/tmp/nopinch.log`.

## Uninstall

```sh
./uninstall.sh
```

## Your touchpad sends something else?

Run the diagnostic and pinch a few times during the 20 seconds it records. It needs Accessibility permission too, either on the binary or on your terminal app.

```sh
swiftc -O pinchlog.swift -o pinchlog && ./pinchlog > pinch.log; sort pinch.log | uniq -c | sort -rn
```

Then add a matching rule to the callback in `nopinch.swift`. Event types: `10` keyDown, `11` keyUp, `12` flagsChanged, `22` scrollWheel, `29` gesture, `30` magnify.

Tested on macOS 26.

// Drops pinch-to-zoom system-wide: trackpad magnify gestures and
// Ctrl+scroll, and Cmd+keypad +/- (what this keyboard's touchpad sends).
import Cocoa

let magnify: UInt32 = 30   // NSEvent.EventType.magnify
let mask: CGEventMask = (1 << magnify) | (1 << CGEventType.scrollWheel.rawValue)
    | (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
let keypadPlus: Int64 = 69, keypadMinus: Int64 = 78
var swallowed = Set<Int64>()   // keypad keys whose keyDown we dropped

var tap: CFMachPort?
let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    if type.rawValue == magnify { return nil }
    if type == .scrollWheel && event.flags.contains(.maskControl) { return nil }
    if type == .keyDown || type == .keyUp {
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        if key == keypadPlus || key == keypadMinus {
            if type == .keyDown && event.flags.contains(.maskCommand) { swallowed.insert(key); return nil }
            if type == .keyUp && swallowed.remove(key) != nil { return nil }
        }
    }
    return Unmanaged.passUnretained(event)
}

guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                options: .defaultTap, eventsOfInterest: mask,
                                callback: callback, userInfo: nil) else {
    FileHandle.standardError.write("nopinch: no Accessibility permission\n".data(using: .utf8)!)
    exit(1)
}
tap = t
CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
CGEvent.tapEnable(tap: t, enable: true)
CFRunLoopRun()

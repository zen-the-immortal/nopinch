// Diagnostic: logs every input event for 20s so you can see what your
// touchpad actually sends when you pinch. Needs Accessibility permission.
import Cocoa
let cb: CGEventTapCallBack = { _, type, e, _ in
    var s = "type=\(type.rawValue) flags=0x\(String(e.flags.rawValue, radix: 16))"
    if type == .scrollWheel {
        s += " dy=\(e.getIntegerValueField(.scrollWheelEventDeltaAxis1)) dx=\(e.getIntegerValueField(.scrollWheelEventDeltaAxis2)) cont=\(e.getIntegerValueField(.scrollWheelEventIsContinuous))"
    }
    if type == .keyDown || type == .keyUp { s += " key=\(e.getIntegerValueField(.keyboardEventKeycode))" }
    print(s); fflush(stdout)
    return Unmanaged.passUnretained(e)
}
guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
        eventsOfInterest: ~0, callback: cb, userInfo: nil) else { print("NO PERMISSION"); exit(1) }
CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
CGEvent.tapEnable(tap: t, enable: true)
DispatchQueue.main.asyncAfter(deadline: .now() + 20) { exit(0) }
CFRunLoopRun()

import Cocoa

let gestureThreshold: CGFloat = 30
let scrollLines: Int32 = 3

var dragStartOrigin: CGPoint? = nil

enum Action: CGKeyCode {
  case showMissionControl = 126
  case switchLeft = 123
  case switchRight = 124

  static func find(origin: CGPoint, destination: CGPoint) -> Self? {
    let dx = destination.x - origin.x
    let dy = destination.y - origin.y
    let absDx = abs(dx)
    let absDy = abs(dy)

    guard absDx > gestureThreshold || absDy > gestureThreshold else {
      return nil
    }

    if absDy > absDx {
      if dy < 0 {
        return .showMissionControl
      } else {
        return nil
      }
    } else {
      if dx < 0 {
        return .switchLeft
      } else {
        return .switchRight
      }
    }
  }
}

func postKeyEvent(keyCode: CGKeyCode, flags: CGEventFlags) {
  let src = CGEventSource(stateID: .hidSystemState)
  let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
  let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
  down?.flags.formUnion(flags)
  up?.flags.formUnion(flags)
  down?.post(tap: .cghidEventTap)
  up?.post(tap: .cghidEventTap)
}

func triggerRightMouseDown(location: CGPoint) {
  let src = CGEventSource(stateID: .hidSystemState)
  let fakeDown = CGEvent(
    mouseEventSource: src,
    mouseType: .rightMouseDown,
    mouseCursorPosition: location,
    mouseButton: .right
  )
  fakeDown?.post(tap: .cgSessionEventTap)
}

let eventCallback: CGEventTapCallBack = { proxy, type, event, _ in
  switch type {
  case .scrollWheel:
    let axis1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    let axis2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)

    guard
      axis1 != 0 || axis2 != 0,
      let newEvent = CGEvent(
        scrollWheelEvent2Source: nil,
        units: .line,
        wheelCount: 2,
        wheel1: axis1 != 0 ? (axis1 > 0 ? -scrollLines : scrollLines) : 0,
        wheel2: axis2 != 0 ? (axis2 > 0 ? -scrollLines : scrollLines) : 0,
        wheel3: 0
      )
    else {
      return Unmanaged.passRetained(event)
    }

    return Unmanaged.passRetained(newEvent)

  case .rightMouseDown:
    dragStartOrigin = event.location
    return nil

  case .rightMouseUp:
    defer { dragStartOrigin = nil }

    guard
      let dragStartOrigin = dragStartOrigin,
      let action = Action.find(origin: dragStartOrigin, destination: event.location)
    else {
      triggerRightMouseDown(location: event.location)
      return Unmanaged.passRetained(event)
    }

    postKeyEvent(keyCode: action.rawValue, flags: .maskControl)
    return nil

  default:
    return Unmanaged.passRetained(event)
  }
}

func ensurePermission() {
  let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary

  guard AXIsProcessTrustedWithOptions(options) else {
    fputs(
      "error: accessibility permission denied. allow this app in System Settings > Privacy & Security > Accessibility.",
      stderr
    )
    exit(1)
  }
}

func createEventTap() -> CFMachPort {
  let mask: CGEventMask =
    (1 << CGEventType.rightMouseDown.rawValue)
    | (1 << CGEventType.rightMouseUp.rawValue)
    | (1 << CGEventType.scrollWheel.rawValue)
  let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: eventCallback,
    userInfo: nil
  )

  guard let tap = tap else {
    fputs("Error: Failed to create event tap.\n", stderr)
    exit(1)
  }

  return tap
}

func setupStatusBar() {
  let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  item.button?.image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)
  let menu = NSMenu()
  menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
  item.menu = menu
}

func runApp(tap: CFMachPort) {
  let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
  CGEvent.tapEnable(tap: tap, enable: true)
  NSApplication.shared.run()
}

ensurePermission()
NSApplication.shared.setActivationPolicy(.accessory)
setupStatusBar()
runApp(tap: createEventTap())

import Cocoa

private let gestureThreshold: CGFloat = 30
private let scrollLines: Int32 = 3

private var dragStartOrigin: CGPoint?
private var eventTap: CFMachPort!

private let eventCallback: CGEventTapCallBack = { proxy, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return nil
    }

    switch type {
    case .scrollWheel:
        guard
            event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
            event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0
        else {
            return Unmanaged.passRetained(event)
        }

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
        guard let origin = dragStartOrigin else {
            return Unmanaged.passRetained(event)
        }
        dragStartOrigin = nil

        let dx = event.location.x - origin.x
        let dy = event.location.y - origin.y
        let absDx = abs(dx)
        let absDy = abs(dy)

        guard absDx > gestureThreshold || absDy > gestureThreshold else {
            MouseEvent.rightDown.post(location: event.location)
            MouseEvent.rightUp.post(location: event.location)
            return nil
        }

        if absDy > absDx {
            if dy >= 0 {
                MouseEvent.rightDown.post(location: event.location)
                MouseEvent.rightUp.post(location: event.location)
            } else {
                KeyEvent.showMissionControl.post()
            }
        } else {
            if dx < 0 {
                KeyEvent.switchLeft.post()
            } else {
                KeyEvent.switchRight.post()
            }
        }
        return nil

    default:
        return Unmanaged.passRetained(event)
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

    eventTap = tap
    return tap
}

func cleanUp() {
    guard let dragStartOrigin = dragStartOrigin else {
        return
    }
    MouseEvent.rightUp.post(location: dragStartOrigin)
}

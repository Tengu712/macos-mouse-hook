import CoreGraphics

enum MouseEvent {
    case rightDown
    case rightUp

    func post(location: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)

        guard
            let event = CGEvent(
                mouseEventSource: src,
                mouseType: self.type(),
                mouseCursorPosition: location,
                mouseButton: .right
            )
        else {
            fputs("warning: failed to post right button event: \(self.type().rawValue)\n", stderr)
            return
        }

        event.post(tap: .cgSessionEventTap)
    }

    private func type() -> CGEventType {
        switch self {
        case .rightDown: .rightMouseDown
        case .rightUp: .rightMouseUp
        }
    }
}

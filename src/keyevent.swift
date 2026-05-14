import CoreGraphics

enum KeyEvent: CGKeyCode {
    case showMissionControl = 126
    case switchLeft = 123
    case switchRight = 124

    func post() {
        let src = CGEventSource(stateID: .hidSystemState)

        guard
            let down = CGEvent(keyboardEventSource: src, virtualKey: self.rawValue, keyDown: true),
            let up = CGEvent(keyboardEventSource: src, virtualKey: self.rawValue, keyDown: false)
        else {
            fputs("warning: failed to key event: \(self.rawValue)\n", stderr)
            return
        }

        down.flags.formUnion(.maskControl)
        up.flags.formUnion(.maskControl)

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

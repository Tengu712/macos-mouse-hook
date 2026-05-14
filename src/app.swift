import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    // to prevent from being released
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let tap = createEventTap()
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        setupStatusBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanUp()
    }

    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        item.menu = NSMenu()
        item.menu!.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        guard
            let button = item.button,
            let image = NSImage(
                systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)
        else {
            fputs("warning: failed to set icon image.\n", stderr)
            return
        }

        button.image = image
    }
}

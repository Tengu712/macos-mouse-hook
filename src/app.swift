import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    // to prevent from being released
    private var statusItem: NSStatusItem?
    private var pauseMenuItem: NSMenuItem?
    private var iconRunning: NSImage!
    private var iconPaused: NSImage!
    private var isPaused = false

    override init() {
        guard
            let iconRunning = NSImage(
                systemSymbolName: "cursorarrow.click.2",
                accessibilityDescription: nil
            ),
            let iconPaused = NSImage(
                systemSymbolName: "cursorarrow.slash",
                accessibilityDescription: nil
            )
        else {
            fputs("warning: failed to create icon image.\n", stderr)
            return
        }

        self.iconRunning = iconRunning
        self.iconPaused = iconPaused
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let tap = createEventTap()
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        setEventTapEnabled(true)

        setupStatusBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanUp()
    }

    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        let pauseItem = NSMenuItem(
            title: "Pause",
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        pauseMenuItem = pauseItem

        item.menu = NSMenu()
        item.menu!.addItem(pauseItem)
        item.menu!.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        updateIcon()
    }

    private func updateIcon() {
        guard let button = statusItem?.button else {
            fputs("warning: failed to set icon image.\n", stderr)
            return
        }

        button.image = isPaused ? iconPaused : iconRunning
    }

    @objc
    private func togglePause() {
        isPaused.toggle()
        setEventTapEnabled(!isPaused)
        pauseMenuItem?.title = isPaused ? "Resume" : "Pause"
        updateIcon()
    }
}

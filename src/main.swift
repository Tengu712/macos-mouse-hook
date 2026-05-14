import Cocoa

// ensure permission
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
guard AXIsProcessTrustedWithOptions(options) else {
    fputs(
        "error: accessibility permission denied. allow this app in System Settings > Privacy & Security > Accessibility.\n",
        stderr
    )
    exit(1)
}

// run app
let app = NSApplication.shared
let appDelegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()

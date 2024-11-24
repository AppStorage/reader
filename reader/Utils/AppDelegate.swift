import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable tabbing for all new windows
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

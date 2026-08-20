import AppKit
import SwiftUI

@MainActor
public final class WindowManager {
    public static let shared = WindowManager()
    
    private var manageWindow: NSWindow?
    private var settingsWindow: NSWindow?
    
    private init() {}
    
    // MARK: - Manage Shortcuts Window
    public func showManageShortcuts() {
        if let window = manageWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = ManageShortcutsView(manager: ShortcutManager.shared)
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Manage Projects & Shortcuts — ProjectDeck"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 720, height: 520))
        window.minSize = NSSize(width: 640, height: 440)
        window.center()
        window.isReleasedWhenClosed = false
        
        self.manageWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Settings Window
    public func showSettings(selectedTab: String = "general") {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = SettingsView(manager: ShortcutManager.shared)
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "ProjectDeck Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 380))
        window.center()
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - About Alert
    public func showAbout() {
        showSettings(selectedTab: "about")
    }
}

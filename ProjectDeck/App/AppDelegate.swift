import AppKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "AppDelegate")

public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("ProjectDeck application launching...")
        
        // Hide dock icon dynamically if LSUIElement wasn't set yet
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar icon and menu
        MenuBarController.shared.setupMenuBar()
        
        // Register global hotkey
        let prefs = ShortcutManager.shared.preferences
        let registered = HotkeyManager.shared.register(
            keyCode: prefs.hotkeyKeyCode,
            modifiers: prefs.hotkeyModifiers
        )
        
        if !registered {
            logger.warning("Could not register initial hotkey: \(HotkeyManager.shared.lastError ?? "Unknown")")
        }
        
        // Connect Hotkey press to FloatingPanelController
        HotkeyManager.shared.onHotkeyPressed = {
            Task { @MainActor in
                FloatingPanelController.shared.toggle()
            }
        }
        
        // Connect FloatingPanel callbacks to WindowManager
        FloatingPanelController.shared.onOpenManagementRequested = {
            Task { @MainActor in
                WindowManager.shared.showManageShortcuts()
            }
        }
        
        FloatingPanelController.shared.onEditShortcutRequested = { shortcut in
            Task { @MainActor in
                WindowManager.shared.showManageShortcuts()
            }
        }
        
        // If this is first launch or active project has no folders, open Manage Shortcuts window directly
        // so user sees immediate feedback on launch
        if ShortcutManager.shared.activeFolders.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WindowManager.shared.showManageShortcuts()
            }
        }
        
        logger.info("ProjectDeck started and listening for hotkey.")
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
        ShortcutManager.shared.saveData()
        logger.info("ProjectDeck terminating.")
    }
}

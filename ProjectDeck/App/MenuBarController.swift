import AppKit
import SwiftUI

@MainActor
public final class MenuBarController {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var launchAtLoginMenuItem: NSMenuItem?
    
    private init() {}
    
    public func setupMenuBar() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use modern SF Symbol for folder deck
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            if let image = NSImage(systemSymbolName: "rectangle.stack.badge.play", accessibilityDescription: "ProjectDeck")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            } else if let fallbackImage = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "ProjectDeck")?.withSymbolConfiguration(config) {
                fallbackImage.isTemplate = true
                button.image = fallbackImage
            }
            button.toolTip = "ProjectDeck — Floating Folder Launcher (⌃ Space)"
        }
        
        let menu = NSMenu()
        
        // Show Launcher Item
        let showItem = NSMenuItem(
            title: "Show Launcher",
            action: #selector(handleShowLauncher),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Manage Shortcuts Item
        let manageItem = NSMenuItem(
            title: "Manage Shortcuts...",
            action: #selector(handleManageShortcuts),
            keyEquivalent: "m"
        )
        manageItem.target = self
        menu.addItem(manageItem)
        
        // Settings Item
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(handleSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Launch at Login Toggle
        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(handleToggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        self.launchAtLoginMenuItem = loginItem
        menu.addItem(loginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About Item
        let aboutItem = NSMenuItem(
            title: "About ProjectDeck",
            action: #selector(handleAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Quit Item
        let quitItem = NSMenuItem(
            title: "Quit ProjectDeck",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        self.statusItem = statusItem
        self.menu = menu
    }
    
    public func updateLaunchAtLoginState(enabled: Bool) {
        launchAtLoginMenuItem?.state = enabled ? .on : .off
    }
    
    // MARK: - Actions
    
    @objc private func handleShowLauncher() {
        FloatingPanelController.shared.show()
    }
    
    @objc private func handleManageShortcuts() {
        WindowManager.shared.showManageShortcuts()
    }
    
    @objc private func handleSettings() {
        WindowManager.shared.showSettings()
    }
    
    @objc private func handleToggleLaunchAtLogin() {
        let newState = !LaunchAtLoginManager.shared.isEnabled
        LaunchAtLoginManager.shared.setEnabled(newState)
        updateLaunchAtLoginState(enabled: newState)
    }
    
    @objc private func handleAbout() {
        WindowManager.shared.showAbout()
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}

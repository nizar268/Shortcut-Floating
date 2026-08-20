import Foundation
import AppKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "FloatingPanelController")

@MainActor
public final class FloatingPanelController {
    public static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    public var onOpenManagementRequested: (() -> Void)?
    public var onEditShortcutRequested: ((FolderShortcut) -> Void)?
    
    private let panelDimension: CGFloat = 500.0
    
    private init() {
        setupPanel()
    }
    
    private func setupPanel() {
        let launcherView = FloatingLauncherView(
            manager: ShortcutManager.shared,
            onDismiss: { [weak self] in
                self?.hide()
            },
            onOpenManagement: { [weak self] in
                self?.hide()
                self?.onOpenManagementRequested?()
            },
            onEditShortcut: { [weak self] shortcut in
                self?.hide()
                self?.onEditShortcutRequested?(shortcut)
            }
        )
        
        let hostingView = NSHostingView(rootView: launcherView)
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: panelDimension, height: panelDimension))
        panel.contentView = hostingView
        self.panel = panel
    }
    
    // MARK: - Toggle / Show / Hide
    
    public func toggle() {
        guard let panel = panel else { return }
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        guard let panel = panel else { return }
        
        // Refresh availability
        ShortcutManager.shared.refreshAllAvailability()
        
        let finalSize = CGSize(width: panelDimension, height: panelDimension)
        panel.setContentSize(finalSize)
        
        // Position centered at current mouse cursor location
        let mouseLocation = NSEvent.mouseLocation
        let origin = ScreenPositioner.calculateFloatingOrigin(
            windowSize: finalSize,
            cursorLocation: mouseLocation
        )
        
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0.0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Fast subtle scale / fade transition
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.10
            panel.animator().alphaValue = 1.0
        }
        
        startOutsideClickMonitoring()
        logger.info("Radial floating panel shown at \(origin.x), \(origin.y)")
    }
    
    public func hide() {
        guard let panel = panel, panel.isVisible else { return }
        stopOutsideClickMonitoring()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.08
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            panel.orderOut(nil)
        })
        
        logger.info("Floating panel dismissed")
    }
    
    // MARK: - Outside Click Monitoring
    
    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()
        
        // Global monitor for clicks outside the application
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            let clickLocation = NSEvent.mouseLocation
            if !NSPointInRect(clickLocation, panel.frame) {
                self.hide()
            }
        }
        
        // Local monitor for clicks inside app windows
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return event }
            if event.window != panel {
                self.hide()
            }
            return event
        }
    }
    
    private func stopOutsideClickMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}

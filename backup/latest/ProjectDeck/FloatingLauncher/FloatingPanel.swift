import AppKit

/// Custom lightweight NSPanel for the floating folder launcher.
public final class FloatingPanel: NSPanel {
    
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
    }
    
    override public var canBecomeKey: Bool {
        return true
    }
    
    override public var canBecomeMain: Bool {
        return false
    }
    
    /// Handle escape key at window level as backup
    override public func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }
}

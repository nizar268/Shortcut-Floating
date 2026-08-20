import SwiftUI
import AppKit

@MainActor
public struct FloatingLauncherView: View {
    @ObservedObject var manager: ShortcutManager
    public var onDismiss: () -> Void
    public var onOpenManagement: () -> Void
    public var onEditShortcut: (FolderShortcut) -> Void
    
    @State private var showProjectPopup: Bool = false
    @State private var hoveredFolderIndex: Int? = nil
    
    private let wheelDiameter: CGFloat = 480.0
    private var centerPoint: CGPoint {
        CGPoint(x: wheelDiameter / 2.0, y: wheelDiameter / 2.0)
    }
    private let innerRadius: CGFloat = 82.0
    private let outerRadius: CGFloat = 226.0
    
    public init(
        manager: ShortcutManager,
        onDismiss: @escaping () -> Void,
        onOpenManagement: @escaping () -> Void,
        onEditShortcut: @escaping (FolderShortcut) -> Void
    ) {
        self.manager = manager
        self.onDismiss = onDismiss
        self.onOpenManagement = onOpenManagement
        self.onEditShortcut = onEditShortcut
    }
    
    public var body: some View {
        let folders = manager.activeFolders
        let folderCount = folders.count
        
        ZStack {
            // Background Circle with Glassmorphism
            VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 28, x: 0, y: 14)
            
            // MARK: - Surrounding Radial Folder Segments
            if folderCount > 0 {
                let segmentAngle = 360.0 / Double(folderCount)
                let gapAngle = folderCount > 1 ? min(3.0, 360.0 / Double(folderCount * 8)) : 0.0
                
                ForEach(Array(folders.enumerated()), id: \.element.id) { index, shortcut in
                    let startDeg = -90.0 + (Double(index) * segmentAngle) + (gapAngle / 2.0)
                    let endDeg = -90.0 + (Double(index + 1) * segmentAngle) - (gapAngle / 2.0)
                    
                    RadialSegmentView(
                        shortcut: shortcut,
                        index: index,
                        startAngle: .degrees(startDeg),
                        endAngle: .degrees(endDeg),
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        center: centerPoint,
                        isHovered: hoveredFolderIndex == index,
                        onSelect: { inNewTab in
                            launchFolder(at: index, inNewTab: inNewTab)
                        },
                        onEdit: {
                            onDismiss()
                            onEditShortcut(shortcut)
                        },
                        onRemove: {
                            manager.removeFolderFromActiveProject(id: shortcut.id)
                        }
                    )
                }
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                
                // Continuous Radial Mouse Tracker for guaranteed hit-testing and Command-click support
                RadialHitTestOverlay(
                    diameter: wheelDiameter,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    folderCount: folderCount,
                    onHoverChange: { index in
                        if !showProjectPopup {
                            hoveredFolderIndex = index
                        }
                    },
                    onClick: { index, isCommandDown in
                        if !showProjectPopup {
                            launchFolder(at: index, inNewTab: isCommandDown)
                        }
                    }
                )
            } else {
                // Empty State in Radial Area
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary)
                    
                    Text("No folders in this project")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        onDismiss()
                        onOpenManagement()
                    }) {
                        Text("+ Add Folder")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .offset(y: 130)
                .allowsHitTesting(true)
            }
            
            // MARK: - Center Project Button
            ProjectCenterButtonView(
                project: manager.activeProject,
                folderCount: folderCount,
                onOptionClick: {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        showProjectPopup.toggle()
                    }
                },
                onNormalClick: {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        showProjectPopup.toggle()
                    }
                }
            )
            .frame(width: 140, height: 140)
            .contentShape(Circle())
            .zIndex(10)
            
            // MARK: - Project Management Popup Overlay
            if showProjectPopup {
                ProjectManagementPopupView(
                    manager: manager,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.14)) {
                            showProjectPopup = false
                        }
                    },
                    onOpenFullManagement: {
                        onDismiss()
                        onOpenManagement()
                    }
                )
                .position(x: centerPoint.x, y: centerPoint.y)
                .transition(.scale(scale: 0.88).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .clipShape(Circle())
        .onAppear {
            manager.refreshAllAvailability()
            hoveredFolderIndex = nil
        }
        // Keyboard navigation background
        .background(
            KeyHandlingView { event in
                return handleKeyEvent(event)
            }
        )
    }
    
    private func launchFolder(at index: Int, inNewTab: Bool = false) {
        let folders = manager.activeFolders
        guard folders.indices.contains(index) else { return }
        let target = folders[index]
        
        if inNewTab {
            manager.launchShortcutInNewTab(target)
        } else {
            manager.launchShortcut(target)
        }
        
        if manager.preferences.closeAfterLaunch {
            onDismiss()
        }
    }
    
    // MARK: - Keyboard Handling
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags
        
        switch event.keyCode {
        case 53: // Escape
            if showProjectPopup {
                withAnimation { showProjectPopup = false }
                return true
            }
            onDismiss()
            return true
            
        case 124: // Right Arrow
            if flags.contains(.command) || flags.contains(.option) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    manager.nextProject()
                }
                return true
            }
            
        case 123: // Left Arrow
            if flags.contains(.command) || flags.contains(.option) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    manager.previousProject()
                }
                return true
            }
            
        default:
            // Number keys 1-9 for slot quick launching
            if let num = numberKeyToSlotIndex(event.keyCode) {
                let isCommand = flags.contains(.command)
                launchFolder(at: num, inNewTab: isCommand)
                return true
            }
        }
        return false
    }
    
    private func numberKeyToSlotIndex(_ keyCode: UInt16) -> Int? {
        switch keyCode {
        case 18: return 0 // 1
        case 19: return 1 // 2
        case 20: return 2 // 3
        case 21: return 3 // 4
        case 23: return 4 // 5
        case 22: return 5 // 6
        case 26: return 6 // 7
        case 28: return 7 // 8
        case 25: return 8 // 9
        default: return nil
        }
    }
}

// MARK: - Radial Hit Test Overlay for Precise Mouse Tracking & Command Detection
private struct RadialHitTestOverlay: NSViewRepresentable {
    let diameter: CGFloat
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let folderCount: Int
    let onHoverChange: (Int?) -> Void
    let onClick: (_ index: Int, _ isCommandDown: Bool) -> Void
    
    func makeNSView(context: Context) -> RadialTrackerView {
        let view = RadialTrackerView()
        view.diameter = diameter
        view.innerRadius = innerRadius
        view.outerRadius = outerRadius
        view.folderCount = folderCount
        view.onHoverChange = onHoverChange
        view.onClick = onClick
        return view
    }
    
    func updateNSView(_ nsView: RadialTrackerView, context: Context) {
        nsView.diameter = diameter
        nsView.innerRadius = innerRadius
        nsView.outerRadius = outerRadius
        nsView.folderCount = folderCount
        nsView.onHoverChange = onHoverChange
        nsView.onClick = onClick
    }
    
    class RadialTrackerView: NSView {
        var diameter: CGFloat = 480.0
        var innerRadius: CGFloat = 82.0
        var outerRadius: CGFloat = 226.0
        var folderCount: Int = 0
        var onHoverChange: ((Int?) -> Void)?
        var onClick: ((_ index: Int, _ isCommandDown: Bool) -> Void)?
        
        private var trackingArea: NSTrackingArea?
        private var currentHovered: Int? = nil
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let existing = trackingArea {
                removeTrackingArea(existing)
            }
            let options: NSTrackingArea.Options = [.activeInActiveApp, .activeAlways, .mouseMoved, .mouseEnteredAndExited]
            let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(area)
            trackingArea = area
        }
        
        override func mouseMoved(with event: NSEvent) {
            let loc = convert(event.locationInWindow, from: nil)
            let newIndex = calculateSegmentIndex(at: loc)
            if newIndex != currentHovered {
                currentHovered = newIndex
                onHoverChange?(newIndex)
            }
        }
        
        override func mouseExited(with event: NSEvent) {
            if currentHovered != nil {
                currentHovered = nil
                onHoverChange?(nil)
            }
        }
        
        override func mouseDown(with event: NSEvent) {
            let loc = convert(event.locationInWindow, from: nil)
            let isCommand = event.modifierFlags.contains(.command)
            if let index = calculateSegmentIndex(at: loc) {
                onClick?(index, isCommand)
            } else {
                super.mouseDown(with: event)
            }
        }
        
        private func calculateSegmentIndex(at point: CGPoint) -> Int? {
            guard folderCount > 0 else { return nil }
            let mid = diameter / 2.0
            let dx = point.x - mid
            let dy = point.y - mid
            let r = sqrt(dx * dx + dy * dy)
            
            // Only respond within radial ring
            guard r >= innerRadius && r <= outerRadius else {
                return nil
            }
            
            let angleRad = atan2(dy, dx)
            var angleDeg = angleRad * 180.0 / .pi
            if angleDeg < 0 { angleDeg += 360.0 }
            
            var clockwiseFromTop = 90.0 - angleDeg
            if clockwiseFromTop < 0 { clockwiseFromTop += 360.0 }
            
            let segmentSize = 360.0 / Double(folderCount)
            let index = Int(clockwiseFromTop / segmentSize)
            return min(folderCount - 1, max(0, index))
        }
    }
}

// MARK: - KeyHandlingView
private struct KeyHandlingView: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: KeyView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
    
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Bool)?
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            if let handled = onKeyDown?(event), handled {
                return
            }
            super.keyDown(with: event)
        }
    }
}

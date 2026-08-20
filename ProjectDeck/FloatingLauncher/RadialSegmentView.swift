import SwiftUI
import AppKit

public struct RadialSegmentView: View {
    public let shortcut: FolderShortcut
    public let index: Int
    public let startAngle: Angle
    public let endAngle: Angle
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat
    public let center: CGPoint
    public let isHovered: Bool
    public let onSelect: (_ inNewTab: Bool) -> Void
    public let onEdit: () -> Void
    public let onRemove: () -> Void
    
    @State private var showDeleteConfirm: Bool = false
    
    public init(
        shortcut: FolderShortcut,
        index: Int,
        startAngle: Angle,
        endAngle: Angle,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        center: CGPoint,
        isHovered: Bool = false,
        onSelect: @escaping (_ inNewTab: Bool) -> Void,
        onEdit: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.shortcut = shortcut
        self.index = index
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.center = center
        self.isHovered = isHovered
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onRemove = onRemove
    }
    
    private var midAngle: Angle {
        Angle(radians: (startAngle.radians + endAngle.radians) / 2.0)
    }
    
    private var midRadius: CGFloat {
        (innerRadius + outerRadius) / 2.0
    }
    
    private var contentPosition: CGPoint {
        CGPoint(
            x: center.x + midRadius * CGFloat(cos(midAngle.radians)),
            y: center.y + midRadius * CGFloat(sin(midAngle.radians))
        )
    }
    
    private var wedgeShape: RadialWedgeShape {
        RadialWedgeShape(
            startAngle: startAngle,
            endAngle: endAngle,
            innerRadius: innerRadius,
            outerRadius: outerRadius
        )
    }
    
    public var body: some View {
        ZStack {
            // Background Wedge Shape
            wedgeShape
                .fill(
                    isHovered
                        ? (shortcut.colorHex != nil ? shortcut.accentColor.opacity(0.40) : Color.accentColor.opacity(0.32))
                        : Color(nsColor: .controlBackgroundColor).opacity(0.45)
                )
                .overlay(
                    wedgeShape
                        .stroke(
                            isHovered
                                ? (shortcut.colorHex != nil ? shortcut.accentColor : Color.accentColor)
                                : Color.white.opacity(0.15),
                            lineWidth: isHovered ? 2.5 : 1.0
                        )
                )
            
            // Content centered on wedge bisector
            VStack(spacing: 3) {
                // Folder Icon with optional number badge
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: FolderUtilities.iconForURL(url: shortcut.folderURL))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .opacity(shortcut.isAvailable ? 1.0 : 0.4)
                    
                    if index < 9 {
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 14, height: 14)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .offset(x: 4, y: -4)
                    }
                }
                
                // Folder Name (always right side up)
                Text(shortcut.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(shortcut.isAvailable ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 86)
                
                if !shortcut.isAvailable {
                    Text("Offline")
                        .font(.system(size: 8, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.red.opacity(0.3)))
                        .foregroundColor(.red)
                }
            }
            .position(contentPosition)
            .allowsHitTesting(false)
        }
        .frame(width: center.x * 2, height: center.y * 2)
        .contentShape(wedgeShape)
        .onTapGesture {
            let flags = NSEvent.modifierFlags
            let isControlCommand = flags.contains(.control) && flags.contains(.command)
            let isCommand = flags.contains(.command)
            let isNewTabRequested = isControlCommand || isCommand
            onSelect(isNewTabRequested)
        }
        .contextMenu {
            Button("Open in Finder") {
                onSelect(false)
            }
            
            Button("Open in New Tab (⌃⌘ Click)") {
                onSelect(true)
            }
            
            Divider()
            
            Button("Reveal in Finder") {
                FolderUtilities.revealInFinder(url: shortcut.folderURL)
            }
            
            Button("Copy Path") {
                FolderUtilities.copyPathToClipboard(url: shortcut.folderURL)
            }
            
            Button("Edit Shortcut...") {
                onEdit()
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                showDeleteConfirm = true
            }) {
                Label("Remove Shortcut", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Remove '\(shortcut.displayName)'?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove this folder shortcut from ProjectDeck.")
        }
    }
}

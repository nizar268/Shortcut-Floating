import SwiftUI
import AppKit

public struct ShortcutItemView: View {
    public let shortcut: FolderShortcut
    public let index: Int
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onEdit: () -> Void
    public let onRemove: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var showDeleteConfirm: Bool = false
    
    public init(
        shortcut: FolderShortcut,
        index: Int,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.shortcut = shortcut
        self.index = index
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onRemove = onRemove
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Folder Icon with optional custom color indicator
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: FolderUtilities.iconForURL(url: shortcut.folderURL))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .opacity(shortcut.isAvailable ? 1.0 : 0.4)
                    
                    if let colorHex = shortcut.colorHex, !colorHex.isEmpty {
                        Circle()
                            .fill(shortcut.accentColor)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Name and Path / Status
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(shortcut.displayName)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(shortcut.isAvailable ? .primary : .secondary)
                            .lineLimit(1)
                        
                        if !shortcut.isAvailable {
                            Text(shortcut.unavailableReason ?? "Unavailable")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.red.opacity(0.2)))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(shortcut.folderURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                // Number shortcut badge (for slots 1 to 9)
                if index < 9 {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.primary.opacity(isHovered || isSelected ? 0.15 : 0.06))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.22)
                            : (isHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Open in Finder") {
                onSelect()
            }
            
            Button("Reveal in Finder") {
                FolderUtilities.revealInFinder(url: shortcut.folderURL)
            }
            
            Divider()
            
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
            "Remove '\(shortcut.displayName)' from shortcuts?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will only remove the shortcut from ProjectDeck. The folder on your disk will not be deleted.")
        }
    }
}

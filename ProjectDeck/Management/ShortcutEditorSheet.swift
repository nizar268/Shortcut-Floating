import SwiftUI

@MainActor
public struct ShortcutEditorSheet: View {
    @ObservedObject var manager: ShortcutManager
    @Binding var shortcut: FolderShortcut
    public var onDismiss: () -> Void
    
    @State private var customLabel: String = ""
    @State private var selectedColorHex: String?
    @State private var selectedGroupId: UUID?
    
    // Curated sleek macOS accent colors
    private let presetColors: [String] = [
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#AF52DE", // Indigo / Violet
        "#FF2D55", // Pink
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#00C7BE", // Teal
        "#8E8E93"  // Slate Gray
    ]
    
    public init(
        manager: ShortcutManager,
        shortcut: Binding<FolderShortcut>,
        onDismiss: @escaping () -> Void
    ) {
        self.manager = manager
        self._shortcut = shortcut
        self.onDismiss = onDismiss
        self._customLabel = State(initialValue: shortcut.wrappedValue.customLabel ?? "")
        self._selectedColorHex = State(initialValue: shortcut.wrappedValue.colorHex)
        self._selectedGroupId = State(initialValue: shortcut.wrappedValue.groupId)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Folder Shortcut")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    saveChanges()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Folder Details Header
                    HStack(spacing: 12) {
                        Image(nsImage: FolderUtilities.iconForURL(url: shortcut.folderURL))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shortcut.label)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(shortcut.folderURL.path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    
                    // Custom Label
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom Display Label")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. \(shortcut.label)", text: $customLabel)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Accent Color Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent Color")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            // Default / None
                            Button(action: { selectedColorHex = nil }) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1.5)
                                        .frame(width: 24, height: 24)
                                    
                                    if selectedColorHex == nil {
                                        Circle()
                                            .fill(Color.primary.opacity(0.6))
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Default color")
                            
                            ForEach(presetColors, id: \.self) { hex in
                                Button(action: { selectedColorHex = hex }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex) ?? Color.blue)
                                            .frame(width: 24, height: 24)
                                        
                                        if selectedColorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Quick Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            FolderUtilities.revealInFinder(url: shortcut.folderURL)
                        }) {
                            Label("Reveal in Finder", systemImage: "folder")
                        }
                        
                        Button(action: {
                            FolderUtilities.copyPathToClipboard(url: shortcut.folderURL)
                        }) {
                            Label("Copy Path", systemImage: "doc.on.doc")
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive, action: {
                            manager.removeFolderFromActiveProject(id: shortcut.id)
                            onDismiss()
                        }) {
                            Label("Delete Shortcut", systemImage: "trash")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
        }
        .frame(width: 440, height: 400)
    }
    
    private func saveChanges() {
        var updated = shortcut
        updated.customLabel = customLabel.isEmpty ? nil : customLabel
        updated.colorHex = selectedColorHex
        updated.groupId = selectedGroupId
        manager.updateFolderInActiveProject(updated)
        shortcut = updated
    }
}

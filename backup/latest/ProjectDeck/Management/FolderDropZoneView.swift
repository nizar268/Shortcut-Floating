import SwiftUI
import UniformTypeIdentifiers

public struct FolderDropZoneView: View {
    public var onFolderDropped: (URL) -> Void
    public var onBrowseClicked: () -> Void
    
    @State private var isTargeted: Bool = false
    @State private var warningMessage: String?
    
    public init(
        onFolderDropped: @escaping (URL) -> Void,
        onBrowseClicked: @escaping () -> Void
    ) {
        self.onFolderDropped = onFolderDropped
        self.onBrowseClicked = onBrowseClicked
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
                .scaleEffect(isTargeted ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
            
            VStack(spacing: 4) {
                Text(isTargeted ? "Drop Folder to Add" : "Drag & Drop Finder Folder Here")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isTargeted ? .accentColor : .primary)
                
                Text("or click Browse to choose a directory")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            if let warning = warningMessage {
                Text(warning)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .transition(.opacity.combined(with: .scale))
            }
            
            Button(action: onBrowseClicked) {
                Text("Browse Folder...")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: [6, 4])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                if FolderUtilities.isDirectory(url: url) {
                    warningMessage = nil
                    onFolderDropped(url)
                } else {
                    withAnimation {
                        warningMessage = "Please drop a folder, not a regular file."
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation { warningMessage = nil }
                    }
                }
            }
        }
        return true
    }
}

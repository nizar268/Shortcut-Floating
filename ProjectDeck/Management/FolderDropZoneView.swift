import SwiftUI
import UniformTypeIdentifiers

public struct FolderDropZoneView: View {
    public var onFoldersDropped: ([URL]) -> Void
    public var onBrowseClicked: () -> Void
    
    @State private var isTargeted: Bool = false
    @State private var warningMessage: String?
    
    public init(
        onFoldersDropped: @escaping ([URL]) -> Void,
        onBrowseClicked: @escaping () -> Void
    ) {
        self.onFoldersDropped = onFoldersDropped
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
                Text(isTargeted ? "Drop Folders to Add" : "Drag & Drop Finder Folders Here")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isTargeted ? .accentColor : .primary)
                
                Text("Supports single or multiple folders at once • or click Browse")
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
                Label("Browse Folders...", systemImage: "folder")
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
        guard !providers.isEmpty else { return false }
        
        let group = DispatchGroup()
        var collectedURLs: [URL] = []
        var rejectedNonFolderCount = 0
        let lock = NSLock()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                var resolvedURL: URL? = nil
                if let url = item as? URL {
                    resolvedURL = url
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    resolvedURL = url
                }
                
                if let url = resolvedURL {
                    if FolderUtilities.isDirectory(url: url) {
                        lock.lock()
                        collectedURLs.append(url)
                        lock.unlock()
                    } else {
                        lock.lock()
                        rejectedNonFolderCount += 1
                        lock.unlock()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !collectedURLs.isEmpty {
                self.warningMessage = nil
                self.onFoldersDropped(collectedURLs)
                
                if rejectedNonFolderCount > 0 {
                    withAnimation {
                        self.warningMessage = "Added \(collectedURLs.count) folder(s). Skipped \(rejectedNonFolderCount) non-folder item(s)."
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation { self.warningMessage = nil }
                    }
                }
            } else if rejectedNonFolderCount > 0 {
                withAnimation {
                    self.warningMessage = "Please drop folders, not regular files."
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation { self.warningMessage = nil }
                }
            }
        }
        
        return true
    }
}

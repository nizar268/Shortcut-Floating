import SwiftUI
import AppKit

@MainActor
public struct ManageShortcutsView: View {
    @ObservedObject var manager: ShortcutManager
    
    @State private var selectedProjectId: UUID?
    @State private var editingShortcut: FolderShortcut?
    @State private var showNewProjectSheet: Bool = false
    @State private var newProjectName: String = ""
    @State private var newProjectColorHex: String = "#007AFF"
    
    @State private var showEditProjectSheet: Bool = false
    @State private var editingProjectName: String = ""
    @State private var editingProjectColorHex: String = "#007AFF"
    
    @State private var pendingDuplicateURL: URL?
    @State private var showDuplicateAlert: Bool = false
    
    private let presetColors: [String] = [
        "#007AFF", "#5856D6", "#AF52DE", "#FF2D55",
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#8E8E93"
    ]
    
    public init(manager: ShortcutManager) {
        self.manager = manager
        self._selectedProjectId = State(initialValue: manager.activeProjectId ?? manager.projects.first?.id)
    }
    
    public init() {
        self.manager = ShortcutManager.shared
        self._selectedProjectId = State(initialValue: ShortcutManager.shared.activeProjectId ?? ShortcutManager.shared.projects.first?.id)
    }
    
    private var selectedProject: Project? {
        if let id = selectedProjectId, let proj = manager.projects.first(where: { $0.id == id }) {
            return proj
        }
        return manager.projects.first
    }
    
    public var body: some View {
        HSplitView {
            // MARK: - Left Pane: Projects Master List
            VStack(spacing: 0) {
                HStack {
                    Text("Projects")
                        .font(.headline)
                    Spacer()
                    Button(action: { showNewProjectSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .help("Add New Project")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                
                Divider()
                
                List(selection: $selectedProjectId) {
                    ForEach(manager.projects) { proj in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(proj.accentColor)
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(proj.name)
                                        .font(.system(size: 13, weight: proj.id == selectedProjectId ? .semibold : .regular))
                                    
                                    if proj.id == manager.activeProjectId {
                                        Text("ACTIVE")
                                            .font(.system(size: 8, weight: .black))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                
                                Text("\(proj.folders.count) folders")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .tag(proj.id)
                        .contextMenu {
                            Button("Set as Active Project") {
                                manager.setActiveProject(id: proj.id)
                            }
                            
                            Button("Edit Project") {
                                editingProjectName = proj.name
                                editingProjectColorHex = proj.colorHex ?? "#007AFF"
                                showEditProjectSheet = true
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                manager.deleteProject(id: proj.id)
                                if selectedProjectId == proj.id {
                                    selectedProjectId = manager.projects.first?.id
                                }
                            } label: {
                                Label("Delete Project", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { source, dest in
                        manager.moveProjects(from: source, to: dest)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 260)
            
            // MARK: - Right Pane: Project Folders & Drop Zone
            if let proj = selectedProject {
                VStack(spacing: 0) {
                    // Project Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(proj.accentColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(proj.name)
                                    .font(.title3.bold())
                                
                                if proj.id == manager.activeProjectId {
                                    Text("Active Launcher Project")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                                        .foregroundColor(.accentColor)
                                } else {
                                    Button("Make Active") {
                                        manager.setActiveProject(id: proj.id)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            
                            Text("Folders appear clockwise around the radial wheel starting from 12 o'clock.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Drop Zone
                            FolderDropZoneView(
                                onFolderDropped: { url in
                                    handleFolderAddition(url: url, to: proj)
                                },
                                onBrowseClicked: {
                                    showOpenPanel()
                                }
                            )
                            
                            if proj.folders.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No folders configured for \(proj.name)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Drop folders above to build your radial command palette.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                // Folder Slots List
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Radial Slots (\(proj.folders.count))")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("Top slot = 12 o'clock")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    
                                    ForEach(Array(proj.folders.enumerated()), id: \.element.id) { index, shortcut in
                                        ProjectSlotCardView(
                                            shortcut: shortcut,
                                            slotNumber: index + 1,
                                            onEdit: {
                                                editingShortcut = shortcut
                                            },
                                            onDelete: {
                                                manager.removeFolderFromActiveProject(id: shortcut.id)
                                            },
                                            onLaunch: {
                                                manager.launchShortcut(shortcut)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(minWidth: 420)
            } else {
                VStack {
                    Text("Select or create a project")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 680, minHeight: 480)
        // Add Project Sheet
        .sheet(isPresented: $showNewProjectSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create New Project")
                    .font(.headline)
                
                TextField("Project Name (e.g. Corporate Video 2026)", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Accent Color")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button(action: { newProjectColorHex = hex }) {
                                Circle()
                                    .fill(Color(hex: hex) ?? Color.blue)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: newProjectColorHex == hex ? 2.5 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        showNewProjectSheet = false
                        newProjectName = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Create Project") {
                        let created = manager.addProject(name: newProjectName, colorHex: newProjectColorHex)
                        selectedProjectId = created.id
                        showNewProjectSheet = false
                        newProjectName = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
            .frame(width: 380)
        }
        // Edit Project Sheet
        .sheet(isPresented: $showEditProjectSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit Project")
                    .font(.headline)
                
                TextField("Project Name", text: $editingProjectName)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Accent Color")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button(action: { editingProjectColorHex = hex }) {
                                Circle()
                                    .fill(Color(hex: hex) ?? Color.blue)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: editingProjectColorHex == hex ? 2.5 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        showEditProjectSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Changes") {
                        if var proj = selectedProject {
                            proj.name = editingProjectName
                            proj.colorHex = editingProjectColorHex
                            manager.updateProject(proj)
                        }
                        showEditProjectSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 380)
        }
        // Edit Shortcut Sheet
        .sheet(item: $editingShortcut) { shortcut in
            let binding = Binding<FolderShortcut>(
                get: {
                    manager.activeFolders.first(where: { $0.id == shortcut.id }) ?? shortcut
                },
                set: { updated in
                    manager.updateFolderInActiveProject(updated)
                }
            )
            ShortcutEditorSheet(manager: manager, shortcut: binding) {
                editingShortcut = nil
            }
        }
        // Duplicate Alert
        .alert("Folder Already in Project", isPresented: $showDuplicateAlert) {
            Button("Add Anyway") {
                if let url = pendingDuplicateURL {
                    manager.addFolderToActiveProject(url: url)
                    pendingDuplicateURL = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDuplicateURL = nil
            }
        } message: {
            Text("This folder is already in this project. Would you like to add another slot for it?")
        }
    }
    
    // MARK: - Folder Addition & Open Panel
    
    private func handleFolderAddition(url: URL, to project: Project) {
        if manager.activeProjectId != project.id {
            manager.setActiveProject(id: project.id)
        }
        
        if manager.isDuplicateInActiveProject(url: url) {
            pendingDuplicateURL = url
            showDuplicateAlert = true
        } else {
            manager.addFolderToActiveProject(url: url)
        }
    }
    
    private func showOpenPanel() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Project Folder"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url, let proj = selectedProject {
            handleFolderAddition(url: url, to: proj)
        }
    }
}

// MARK: - Project Slot Card View
private struct ProjectSlotCardView: View {
    let shortcut: FolderShortcut
    let slotNumber: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onLaunch: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var showDeleteConfirm: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Slot Number Badge
            Text("\(slotNumber)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.primary.opacity(0.06)))
            
            // Folder Icon
            Image(nsImage: FolderUtilities.iconForURL(url: shortcut.folderURL))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .opacity(shortcut.isAvailable ? 1.0 : 0.4)
            
            // Label & Path
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(shortcut.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    
                    if !shortcut.isAvailable {
                        Text(shortcut.unavailableReason ?? "Unavailable")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.red.opacity(0.18)))
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
            
            // Actions
            HStack(spacing: 6) {
                Button(action: onLaunch) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Open in Finder")
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Edit Shortcut")
                
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Remove Shortcut")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .confirmationDialog(
            "Remove '\(shortcut.displayName)'?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove this folder from the project.")
        }
    }
}

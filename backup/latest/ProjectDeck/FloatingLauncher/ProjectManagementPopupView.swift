import SwiftUI

@MainActor
public struct ProjectManagementPopupView: View {
    @ObservedObject var manager: ShortcutManager
    public var onDismiss: () -> Void
    public var onOpenFullManagement: () -> Void
    
    @State private var isAddingNewProject: Bool = false
    @State private var newProjectName: String = ""
    @State private var newProjectColorHex: String = "#007AFF"
    @State private var showDeleteConfirm: Bool = false
    
    private let presetColors: [String] = [
        "#007AFF", "#5856D6", "#AF52DE", "#FF2D55",
        "#FF3B30", "#FF9500", "#34C759", "#00C7BE"
    ]
    
    public init(
        manager: ShortcutManager,
        onDismiss: @escaping () -> Void,
        onOpenFullManagement: @escaping () -> Void
    ) {
        self.manager = manager
        self.onDismiss = onDismiss
        self.onOpenFullManagement = onOpenFullManagement
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(manager.activeProject?.accentColor ?? Color.accentColor)
                    .frame(width: 10, height: 10)
                
                Text(manager.activeProject?.name ?? "Projects")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.04))
            
            Divider()
            
            if isAddingNewProject {
                // Inline Add Project View
                VStack(alignment: .leading, spacing: 10) {
                    Text("New Project")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Project Name", text: $newProjectName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 6) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button(action: { newProjectColorHex = hex }) {
                                Circle()
                                    .fill(Color(hex: hex) ?? Color.blue)
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: newProjectColorHex == hex ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack {
                        Button("Cancel") {
                            isAddingNewProject = false
                            newProjectName = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Create") {
                            if !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                manager.addProject(name: newProjectName, colorHex: newProjectColorHex)
                                isAddingNewProject = false
                                newProjectName = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(14)
            } else {
                // Menu Items List
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        // Switch Project Section
                        Text("SWITCH PROJECT")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.top, 6)
                        
                        ForEach(manager.projects) { proj in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    manager.setActiveProject(id: proj.id)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(proj.accentColor)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(proj.name)
                                        .font(.system(size: 12, weight: proj.id == manager.activeProjectId ? .bold : .medium))
                                        .foregroundColor(proj.id == manager.activeProjectId ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    if proj.id == manager.activeProjectId {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(proj.id == manager.activeProjectId ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // Fast Next / Previous Actions
                        MenuActionButton(icon: "arrow.right.circle", title: "Next Project", shortcut: "⌘→") {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                manager.nextProject()
                            }
                        }
                        
                        MenuActionButton(icon: "arrow.left.circle", title: "Previous Project", shortcut: "⌘←") {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                manager.previousProject()
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // Add Project & Manage Window Actions
                        MenuActionButton(icon: "plus.circle", title: "Add New Project...", shortcut: nil) {
                            isAddingNewProject = true
                        }
                        
                        MenuActionButton(icon: "slider.horizontal.3", title: "Manage Projects...", shortcut: nil) {
                            onDismiss()
                            onOpenFullManagement()
                        }
                        
                        if manager.projects.count > 1 {
                            Divider().padding(.vertical, 4)
                            
                            Button(action: { showDeleteConfirm = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12))
                                    Text("Delete Current Project...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 280)
            }
        }
        .frame(width: 250)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        .confirmationDialog(
            "Delete \"\(manager.activeProject?.name ?? "Project")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                if let id = manager.activeProjectId {
                    manager.deleteProject(id: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the project and its shortcuts from ProjectDeck. The actual folders and files in Finder will NOT be deleted.")
        }
    }
}

private struct MenuActionButton: View {
    let icon: String
    let title: String
    let shortcut: String?
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let sc = shortcut {
                    Text(sc)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

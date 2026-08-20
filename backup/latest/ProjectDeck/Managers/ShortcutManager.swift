import Foundation
import SwiftUI
import Combine
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "ShortcutManager")

/// Central Manager for Multi-Project Folder Architecture and persistence.
@MainActor
public final class ShortcutManager: ObservableObject {
    public static let shared = ShortcutManager()
    
    // MARK: - Published Properties
    @Published public var projects: [Project] = []
    @Published public var activeProjectId: UUID? = nil
    @Published public var preferences: AppPreferences = AppPreferences()
    @Published public var searchText: String = ""
    
    // MARK: - Persistence URLs
    private let fileManager = FileManager.default
    private var appSupportURL: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appDir = urls[0].appendingPathComponent("ProjectDeck", isDirectory: true)
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return appDir
    }
    
    private var projectsFileURL: URL {
        appSupportURL.appendingPathComponent("projects.json")
    }
    
    private var activeProjectFileURL: URL {
        appSupportURL.appendingPathComponent("active_project.json")
    }
    
    private var legacyShortcutsFileURL: URL {
        appSupportURL.appendingPathComponent("shortcuts.json")
    }
    
    private var preferencesFileURL: URL {
        appSupportURL.appendingPathComponent("preferences.json")
    }
    
    // MARK: - Init
    public init() {
        loadData()
        refreshAllAvailability()
    }
    
    // MARK: - Active Project Computed Properties
    
    public var activeProject: Project? {
        if let id = activeProjectId, let found = projects.first(where: { $0.id == id }) {
            return found
        }
        return projects.first
    }
    
    public var activeFolders: [FolderShortcut] {
        return activeProject?.folders ?? []
    }
    
    // MARK: - Persistence & Migration
    
    public func loadData() {
        // 1. Load Preferences
        if let data = try? Data(contentsOf: preferencesFileURL),
           let loadedPrefs = try? JSONDecoder().decode(AppPreferences.self, from: data) {
            self.preferences = loadedPrefs
        }
        
        // 2. Load Projects or Migrate
        var loadedProjects: [Project] = []
        
        if let data = try? Data(contentsOf: projectsFileURL),
           let decoded = try? JSONDecoder().decode([Project].self, from: data), !decoded.isEmpty {
            loadedProjects = decoded
        } else if let legacyData = try? Data(contentsOf: legacyShortcutsFileURL),
                  let legacyShortcuts = try? JSONDecoder().decode([FolderShortcut].self, from: legacyData) {
            // Migration: migrate legacy single-list shortcuts into a default project
            let migratedProject = Project(
                name: "My Project",
                colorHex: "#007AFF",
                folders: legacyShortcuts,
                sortOrder: 0
            )
            loadedProjects = [migratedProject]
            logger.info("Migrated \(legacyShortcuts.count) legacy shortcuts into 'My Project'.")
        }
        
        // If still empty, provide a clean starter project
        if loadedProjects.isEmpty {
            let defaultProject = Project(
                name: "Corporate Video 2026",
                colorHex: "#007AFF",
                folders: [],
                sortOrder: 0
            )
            loadedProjects = [defaultProject]
        }
        
        // Resolve security-scoped bookmarks & check availability for all project folders
        for pIndex in loadedProjects.indices {
            for fIndex in loadedProjects[pIndex].folders.indices {
                var folder = loadedProjects[pIndex].folders[fIndex]
                if let bookmarkData = folder.bookmarkData {
                    let (resolvedURL, isStale) = BookmarkManager.shared.resolveBookmark(data: bookmarkData)
                    if let validURL = resolvedURL {
                        folder.folderURL = validURL
                        if isStale {
                            folder.bookmarkData = BookmarkManager.shared.createBookmarkData(for: validURL)
                        }
                    }
                }
                let (available, reason) = FolderUtilities.checkAvailability(url: folder.folderURL)
                folder.isAvailable = available
                folder.unavailableReason = reason
                loadedProjects[pIndex].folders[fIndex] = folder
            }
        }
        
        self.projects = loadedProjects.sorted(by: { $0.sortOrder < $1.sortOrder })
        
        // 3. Load Active Project ID
        if let activeData = try? Data(contentsOf: activeProjectFileURL),
           let savedId = try? JSONDecoder().decode(UUID.self, from: activeData),
           projects.contains(where: { $0.id == savedId }) {
            self.activeProjectId = savedId
        } else {
            self.activeProjectId = projects.first?.id
        }
        
        saveData()
        logger.info("Loaded \(self.projects.count) projects. Active: \(self.activeProject?.name ?? "None")")
    }
    
    public func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Save Projects
            let projectData = try encoder.encode(projects)
            try projectData.write(to: projectsFileURL, options: .atomic)
            
            // Save Active Project ID
            if let activeId = activeProjectId {
                let activeData = try encoder.encode(activeId)
                try activeData.write(to: activeProjectFileURL, options: .atomic)
            }
            
            // Save Preferences
            let prefData = try encoder.encode(preferences)
            try prefData.write(to: preferencesFileURL, options: .atomic)
        } catch {
            logger.error("Failed to save project data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Project Switching & Navigation
    
    public func setActiveProject(id: UUID) {
        guard projects.contains(where: { $0.id == id }) else { return }
        self.activeProjectId = id
        saveData()
        refreshAllAvailability()
        logger.info("Switched active project to \(id)")
    }
    
    public func nextProject() {
        guard projects.count > 1 else { return }
        let currentIndex = projects.firstIndex(where: { $0.id == activeProjectId }) ?? 0
        let nextIndex = (currentIndex + 1) % projects.count
        setActiveProject(id: projects[nextIndex].id)
    }
    
    public func previousProject() {
        guard projects.count > 1 else { return }
        let currentIndex = projects.firstIndex(where: { $0.id == activeProjectId }) ?? 0
        let prevIndex = (currentIndex - 1 + projects.count) % projects.count
        setActiveProject(id: projects[prevIndex].id)
    }
    
    // MARK: - Project CRUD
    
    @discardableResult
    public func addProject(name: String, colorHex: String? = "#007AFF") -> Project {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "New Project" : trimmed
        let nextOrder = (projects.map { $0.sortOrder }.max() ?? -1) + 1
        
        let newProj = Project(
            name: finalName,
            colorHex: colorHex,
            folders: [],
            sortOrder: nextOrder
        )
        projects.append(newProj)
        setActiveProject(id: newProj.id)
        saveData()
        return newProj
    }
    
    public func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveData()
        }
    }
    
    public func deleteProject(id: UUID) {
        projects.removeAll(where: { $0.id == id })
        if projects.isEmpty {
            let defaultProj = Project(name: "My Project", colorHex: "#007AFF", folders: [], sortOrder: 0)
            projects.append(defaultProj)
            activeProjectId = defaultProj.id
        } else if activeProjectId == id || !projects.contains(where: { $0.id == activeProjectId }) {
            activeProjectId = projects.first?.id
        }
        reindexProjectOrders()
        saveData()
    }
    
    public func moveProjects(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        reindexProjectOrders()
        saveData()
    }
    
    private func reindexProjectOrders() {
        for index in projects.indices {
            projects[index].sortOrder = index
        }
    }
    
    // MARK: - Folder CRUD within Active Project
    
    public func isDuplicateInActiveProject(url: URL) -> Bool {
        guard let project = activeProject else { return false }
        let normalized = url.standardized.path
        return project.folders.contains(where: { $0.folderURL.standardized.path == normalized })
    }
    
    @discardableResult
    public func addFolderToActiveProject(
        url: URL,
        customLabel: String? = nil,
        colorHex: String? = nil
    ) -> FolderShortcut? {
        guard let activeId = activeProject?.id,
              let pIndex = projects.firstIndex(where: { $0.id == activeId }),
              FolderUtilities.isDirectory(url: url) else {
            return nil
        }
        
        let bookmarkData = BookmarkManager.shared.createBookmarkData(for: url)
        let originalName = url.lastPathComponent.isEmpty ? "Folder" : url.lastPathComponent
        let nextOrder = (projects[pIndex].folders.map { $0.sortOrder }.max() ?? -1) + 1
        let (isAvail, reason) = FolderUtilities.checkAvailability(url: url)
        
        let newShortcut = FolderShortcut(
            label: originalName,
            customLabel: customLabel,
            folderURL: url,
            bookmarkData: bookmarkData,
            colorHex: colorHex ?? projects[pIndex].colorHex,
            iconName: nil,
            groupId: nil,
            sortOrder: nextOrder,
            createdAt: Date(),
            isAvailable: isAvail,
            unavailableReason: reason
        )
        
        projects[pIndex].folders.append(newShortcut)
        saveData()
        return newShortcut
    }
    
    public func removeFolderFromActiveProject(id: UUID) {
        guard let activeId = activeProject?.id,
              let pIndex = projects.firstIndex(where: { $0.id == activeId }) else { return }
        
        projects[pIndex].folders.removeAll(where: { $0.id == id })
        for index in projects[pIndex].folders.indices {
            projects[pIndex].folders[index].sortOrder = index
        }
        saveData()
    }
    
    public func updateFolderInActiveProject(_ folder: FolderShortcut) {
        guard let activeId = activeProject?.id,
              let pIndex = projects.firstIndex(where: { $0.id == activeId }),
              let fIndex = projects[pIndex].folders.firstIndex(where: { $0.id == folder.id }) else { return }
        
        var updated = folder
        let (isAvail, reason) = FolderUtilities.checkAvailability(url: updated.folderURL)
        updated.isAvailable = isAvail
        updated.unavailableReason = reason
        projects[pIndex].folders[fIndex] = updated
        saveData()
    }
    
    public func moveFoldersInActiveProject(from source: IndexSet, to destination: Int) {
        guard let activeId = activeProject?.id,
              let pIndex = projects.firstIndex(where: { $0.id == activeId }) else { return }
        
        projects[pIndex].folders.move(fromOffsets: source, toOffset: destination)
        for index in projects[pIndex].folders.indices {
            projects[pIndex].folders[index].sortOrder = index
        }
        saveData()
    }
    
    // MARK: - Folder Launching & Availability
    
    public func launchShortcut(_ shortcut: FolderShortcut) {
        let success = FolderUtilities.openInFinder(url: shortcut.folderURL)
        if !success {
            refreshAllAvailability()
        }
    }
    
    public func launchShortcutInNewTab(_ shortcut: FolderShortcut) {
        let success = FolderUtilities.openInFinderNewTab(url: shortcut.folderURL)
        if !success {
            refreshAllAvailability()
        }
    }
    
    public func refreshAllAvailability() {
        for pIndex in projects.indices {
            for fIndex in projects[pIndex].folders.indices {
                let (isAvail, reason) = FolderUtilities.checkAvailability(url: projects[pIndex].folders[fIndex].folderURL)
                projects[pIndex].folders[fIndex].isAvailable = isAvail
                projects[pIndex].folders[fIndex].unavailableReason = reason
            }
        }
    }
}

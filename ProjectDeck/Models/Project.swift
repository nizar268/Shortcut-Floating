import Foundation
import SwiftUI

/// Represents a Project containing a collection of folder shortcuts.
public struct Project: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String?
    public var folders: [FolderShortcut]
    public var sortOrder: Int
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        folders: [FolderShortcut] = [],
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.folders = folders
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
    
    /// Accent color for the project
    public var accentColor: Color {
        guard let hex = colorHex, let color = Color(hex: hex) else {
            return Color.accentColor
        }
        return color
    }
}

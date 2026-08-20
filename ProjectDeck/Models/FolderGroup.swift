import Foundation
import SwiftUI

/// Represents an optional group for categorizing shortcuts.
public struct FolderGroup: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String?
    public var isExpanded: Bool
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        isExpanded: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isExpanded = isExpanded
        self.sortOrder = sortOrder
    }
    
    public var accentColor: Color {
        guard let hex = colorHex, let color = Color(hex: hex) else {
            return Color.accentColor
        }
        return color
    }
}

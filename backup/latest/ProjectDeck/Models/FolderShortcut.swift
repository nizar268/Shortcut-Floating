import Foundation
import SwiftUI

/// Represents a configured project folder shortcut.
public struct FolderShortcut: Identifiable, Codable, Hashable {
    public var id: UUID
    public var label: String
    public var customLabel: String?
    public var folderURL: URL
    public var bookmarkData: Data?
    public var colorHex: String?
    public var iconName: String?
    public var groupId: UUID?
    public var sortOrder: Int
    public var createdAt: Date
    public var isAvailable: Bool = true
    public var unavailableReason: String?
    
    public init(
        id: UUID = UUID(),
        label: String,
        customLabel: String? = nil,
        folderURL: URL,
        bookmarkData: Data? = nil,
        colorHex: String? = nil,
        iconName: String? = nil,
        groupId: UUID? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        isAvailable: Bool = true,
        unavailableReason: String? = nil
    ) {
        self.id = id
        self.label = label
        self.customLabel = customLabel
        self.folderURL = folderURL
        self.bookmarkData = bookmarkData
        self.colorHex = colorHex
        self.iconName = iconName
        self.groupId = groupId
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.isAvailable = isAvailable
        self.unavailableReason = unavailableReason
    }
    
    /// Display name: custom label if set, otherwise original folder label.
    public var displayName: String {
        if let custom = customLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return label.isEmpty ? folderURL.lastPathComponent : label
    }
    
    /// Accent color parsed from colorHex.
    public var accentColor: Color {
        guard let hex = colorHex, let color = Color(hex: hex) else {
            return Color.blue
        }
        return color
    }
}

// MARK: - Color Hex Extensions
extension Color {
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    public func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(components.redComponent * 255))
        let g = Int(round(components.greenComponent * 255))
        let b = Int(round(components.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

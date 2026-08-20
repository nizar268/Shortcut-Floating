import Foundation
import AppKit

public struct FolderUtilities {
    
    /// Verifies if a given URL is a directory/folder.
    public static func isDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
           let isDirectory = resourceValues.isDirectory {
            return isDirectory
        }
        return false
    }
    
    /// Checks folder accessibility and returns availability status along with an optional reason.
    public static func checkAvailability(url: URL) -> (isAvailable: Bool, reason: String?) {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        
        if !exists {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 3 && pathComponents[1] == "Volumes" {
                let volumeName = pathComponents[2]
                let volumePath = "/Volumes/\(volumeName)"
                if !FileManager.default.fileExists(atPath: volumePath) {
                    return (false, "Drive '\(volumeName)' not connected")
                }
            }
            return (false, "Folder unavailable or moved")
        }
        
        if !isDir.boolValue {
            return (false, "Item is not a folder")
        }
        
        return (true, nil)
    }
    
    /// Opens the folder in Finder and activates Finder window.
    @discardableResult
    public static func openInFinder(url: URL) -> Bool {
        return BookmarkManager.shared.withSecurityScope(for: url) {
            let success = NSWorkspace.shared.open(url)
            if success {
                if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                    finderApp.activate()
                }
            }
            return success
        }
    }
    
    /// Opens the folder in a NEW TAB within the active Finder window (triggered by Control+Command+Click or Command+Click).
    /// If no Finder window exists, opens as usual.
    @discardableResult
    public static func openInFinderNewTab(url: URL) -> Bool {
        return BookmarkManager.shared.withSecurityScope(for: url) {
            let folderPath = url.path
            let pathEscaped = folderPath
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            
            let scriptSource = """
            tell application "Finder"
                activate
                set targetFolder to (POSIX file "\(pathEscaped)" as alias)
                if (count of Finder windows) > 0 then
                    try
                        tell application "System Events"
                            tell process "Finder"
                                set frontmost to true
                                click menu item "New Tab" of menu "File" of menu bar 1
                            end tell
                        end tell
                    on error
                        try
                            tell application "System Events"
                                tell process "Finder"
                                    set frontmost to true
                                    keystroke "t" using command down
                                end tell
                            end tell
                        end try
                    end try
                    delay 0.05
                    set target of front Finder window to targetFolder
                else
                    open targetFolder
                end if
            end tell
            """
            
            // 1. Try NSAppleScript execution
            if let appleScript = NSAppleScript(source: scriptSource) {
                var errorInfo: NSDictionary?
                appleScript.executeAndReturnError(&errorInfo)
                if errorInfo == nil {
                    return true
                }
                NSLog("[ProjectDeck] NSAppleScript tab open error: %@", errorInfo ?? [:])
            }
            
            // 2. Fallback: Process-based osascript
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", scriptSource]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    return true
                }
            } catch {
                NSLog("[ProjectDeck] osascript process fallback error: %@", error.localizedDescription)
            }
            
            // 3. Fallback: Standard Finder open
            return openInFinder(url: url)
        }
    }
    
    /// Reveals the folder in Finder (selects it inside its parent folder).
    public static func revealInFinder(url: URL) {
        BookmarkManager.shared.withSecurityScope(for: url) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    /// Copies the folder path string to the system clipboard.
    public static func copyPathToClipboard(url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
    
    /// Returns default Finder-style folder icon for the URL.
    public static func iconForURL(url: URL) -> NSImage {
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

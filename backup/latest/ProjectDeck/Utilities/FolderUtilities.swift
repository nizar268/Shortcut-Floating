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
    
    /// Opens the folder in a NEW TAB within the existing front Finder window (when ⌘ Command is held).
    /// If no Finder window exists, opens as usual.
    /// Uses Process-based osascript for reliable Automation permission handling.
    @discardableResult
    public static func openInFinderNewTab(url: URL) -> Bool {
        return BookmarkManager.shared.withSecurityScope(for: url) {
            let folderPath = url.path
            
            // Strategy: Use osascript via Process for better permission handling.
            // System Events "click menu item" requires Automation permission which
            // macOS will prompt for on first use when NSAppleEventsUsageDescription is in Info.plist.
            let scriptSource = """
            tell application "Finder"
                activate
                set windowCount to count of Finder windows
                if windowCount > 0 then
                    tell application "System Events"
                        tell process "Finder"
                            click menu item "New Tab" of menu "File" of menu bar 1
                        end tell
                    end tell
                    delay 0.15
                    set target of front Finder window to (POSIX file "\(folderPath)" as alias)
                else
                    open (POSIX file "\(folderPath)" as alias)
                end if
            end tell
            """
            
            // Try NSAppleScript first (works when Automation permission is already granted)
            if let appleScript = NSAppleScript(source: scriptSource) {
                var errorInfo: NSDictionary?
                appleScript.executeAndReturnError(&errorInfo)
                if errorInfo == nil {
                    return true
                }
                
                // If NSAppleScript failed, try via Process-based osascript as fallback
                NSLog("[ProjectDeck] NSAppleScript new-tab failed: %@, trying osascript Process...", errorInfo ?? [:])
            }
            
            // Fallback 1: Use Process to call /usr/bin/osascript
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
                NSLog("[ProjectDeck] osascript Process new-tab exited with status: %d", process.terminationStatus)
            } catch {
                NSLog("[ProjectDeck] osascript Process new-tab failed: %@", error.localizedDescription)
            }
            
            // Fallback 2: Open normally via NSWorkspace
            NSLog("[ProjectDeck] Falling back to standard Finder open for: %@", folderPath)
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

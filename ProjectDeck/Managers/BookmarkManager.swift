import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "BookmarkManager")

/// Manages Security-Scoped Bookmarks for persistent folder access across macOS restarts.
public final class BookmarkManager {
    public static let shared = BookmarkManager()
    
    private init() {}
    
    /// Creates security-scoped bookmark data for a given URL.
    public func createBookmarkData(for url: URL) -> Data? {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            logger.info("Successfully created security-scoped bookmark for \(url.path)")
            return bookmark
        } catch {
            logger.error("Failed to create security-scoped bookmark for \(url.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Resolves a security-scoped bookmark back into a usable URL.
    /// Returns the resolved URL and whether the bookmark was stale.
    public func resolveBookmark(data: Data) -> (url: URL?, isStale: Bool) {
        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (resolvedURL, isStale)
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
            return (nil, false)
        }
    }
    
    /// Executes a block of code with security-scoped resource access.
    @discardableResult
    public func withSecurityScope<T>(for url: URL, block: () throws -> T) rethrows -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try block()
    }
}

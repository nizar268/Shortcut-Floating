import Foundation
import ServiceManagement
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "LaunchAtLoginManager")

/// Manages Launch at Login using the modern macOS SMAppService API.
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    @Published public var isEnabled: Bool = false
    
    private init() {
        refreshStatus()
    }
    
    public func refreshStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            self.isEnabled = (status == .enabled)
        }
    }
    
    public func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                refreshStatus()
                logger.info("Launch at login set to \(enabled)")
            } catch {
                logger.error("Failed to update Launch at Login: \(error.localizedDescription)")
                refreshStatus()
            }
        }
    }
}

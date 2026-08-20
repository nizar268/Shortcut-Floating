import Foundation
import Carbon
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.nizart.projectdeck", category: "HotkeyManager")

/// Native Carbon global hotkey manager that intercepts global keypresses (e.g. Control + Space).
public final class HotkeyManager {
    public static let shared = HotkeyManager()
    
    // MARK: - Properties
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyID = EventHotKeyID(signature: OSType(0x50444543), id: UInt32(1)) // "PDEC", 1
    
    public var onHotkeyPressed: (() -> Void)?
    
    private(set) public var isRegistered: Bool = false
    private(set) public var lastError: String?
    
    private init() {}
    
    // MARK: - Registration
    
    /// Registers the global hotkey with given Carbon keycode and modifiers.
    @discardableResult
    public func register(keyCode: UInt32 = UInt32(kVK_Space), modifiers: UInt32 = UInt32(controlKey)) -> Bool {
        unregister()
        
        // Install Carbon Event Handler if not installed
        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            let handler: EventHandlerUPP = { _, eventRef, userData in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                var hkID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                
                if status == noErr && hkID.signature == manager.hotKeyID.signature && hkID.id == manager.hotKeyID.id {
                    DispatchQueue.main.async {
                        manager.onHotkeyPressed?()
                    }
                }
                return noErr
            }
            
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            let status = InstallEventHandler(
                GetApplicationEventTarget(),
                handler,
                1,
                &eventType,
                selfPtr,
                &eventHandlerRef
            )
            
            if status != noErr {
                lastError = "Failed to install Carbon event handler (Status: \(status))"
                logger.error("Failed to install event handler: \(status)")
                return false
            }
        }
        
        // Register Event HotKey
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if regStatus != noErr {
            isRegistered = false
            lastError = "Could not register shortcut. It may conflict with another application or macOS system shortcut (Status: \(regStatus))."
            logger.error("Failed to register hotkey: \(regStatus)")
            return false
        }
        
        isRegistered = true
        lastError = nil
        logger.info("Successfully registered global hotkey: keyCode \(keyCode), modifiers \(modifiers)")
        return true
    }
    
    /// Unregisters the current global hotkey.
    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        isRegistered = false
    }
    
    deinit {
        unregister()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}

import SwiftUI
import Carbon
import AppKit

@MainActor
public struct HotkeyRecorderView: View {
    @ObservedObject var manager: ShortcutManager
    @State private var isRecording: Bool = false
    @State private var conflictMessage: String?
    @State private var localEventMonitor: Any?
    
    public init(manager: ShortcutManager) {
        self.manager = manager
    }
    
    public init() {
        self.manager = ShortcutManager.shared
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Global Keyboard Shortcut")
                .font(.headline)
            
            Text("Press this keyboard combination from any macOS application to display the floating launcher at your cursor position.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Hotkey badge display / recorder
                Button(action: toggleRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: isRecording ? "record.circle.fill" : "keyboard")
                            .foregroundColor(isRecording ? .red : .accentColor)
                        
                        Text(isRecording ? "Type shortcut..." : manager.preferences.hotkeyDisplayString)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording ? Color.red.opacity(0.12) : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRecording ? Color.red : Color.primary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                if isRecording {
                    Button("Cancel") {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Reset to Default (⌃ Space)") {
                        applyShortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey))
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Common Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("Popular Presets:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    PresetButton(title: "⌃ Space (Default)") {
                        applyShortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey))
                    }
                    PresetButton(title: "⌥ Space") {
                        applyShortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
                    }
                    PresetButton(title: "⌘ ⌥ Space") {
                        applyShortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | optionKey))
                    }
                    PresetButton(title: "⌃ ⌥ P") {
                        applyShortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(controlKey | optionKey))
                    }
                }
            }
            .padding(.top, 4)
            
            // Conflict Notice / Info
            if let conflict = conflictMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(conflict)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.15)))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Tip: If Control + Space is reserved by macOS for Input Sources (Input Menu), you can change it here or in macOS System Settings → Keyboard → Keyboard Shortcuts → Input Sources.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        conflictMessage = nil
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let flags = event.modifierFlags
            var carbonModifiers: UInt32 = 0
            if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
            if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            
            // Require at least one modifier key
            if carbonModifiers != 0 && event.keyCode != 53 { // 53 = Esc
                applyShortcut(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
                stopRecording()
                return nil
            } else if event.keyCode == 53 { // Esc cancels recording
                stopRecording()
                return nil
            }
            return event
        }
    }
    
    private func stopRecording() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        isRecording = false
    }
    
    private func applyShortcut(keyCode: UInt32, modifiers: UInt32) {
        manager.preferences.hotkeyKeyCode = keyCode
        manager.preferences.hotkeyModifiers = modifiers
        manager.saveData()
        
        let success = HotkeyManager.shared.register(keyCode: keyCode, modifiers: modifiers)
        if !success {
            conflictMessage = HotkeyManager.shared.lastError ?? "Shortcut conflict detected."
        } else {
            conflictMessage = nil
        }
    }
}

private struct PresetButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
    }
}

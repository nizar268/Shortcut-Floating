import SwiftUI

@MainActor
public struct SettingsView: View {
    @ObservedObject var manager: ShortcutManager = .shared
    @ObservedObject var launchAtLogin: LaunchAtLoginManager = .shared
    
    public init(manager: ShortcutManager) {
        self.manager = manager
    }
    
    public init() {
        self.manager = ShortcutManager.shared
    }
    
    public var body: some View {
        TabView {
            // MARK: - General Tab
            Form {
                Section(header: Text("Application Behavior").font(.headline)) {
                    Toggle("Launch ProjectDeck at Login", isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                    
                    Toggle("Close Floating Launcher after opening a folder", isOn: $manager.preferences.closeAfterLaunch)
                        .onChange(of: manager.preferences.closeAfterLaunch) {
                            manager.saveData()
                        }
                    
                    Toggle("Show quick number badges (1-9)", isOn: $manager.preferences.showNumberBadges)
                        .onChange(of: manager.preferences.showNumberBadges) {
                            manager.saveData()
                        }
                }
                
                Section(header: Text("Finder Integration").font(.headline)) {
                    Text("When a folder shortcut is triggered, ProjectDeck opens it in Finder and brings the window forward.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // MARK: - Hotkey Tab
            VStack(alignment: .leading, spacing: 16) {
                HotkeyRecorderView(manager: manager)
                Spacer()
            }
            .padding(20)
            .tabItem {
                Label("Hotkeys", systemImage: "keyboard")
            }
            
            // MARK: - About Tab
            VStack(spacing: 16) {
                Image(systemName: "folder.fill.badge.gearshape")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 4) {
                    Text("ProjectDeck")
                        .font(.title2.bold())
                    Text("Version 1.0.0 (Sonoma / Apple Silicon & Intel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("A lightning-fast native macOS floating project folder launcher that activates at your mouse cursor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard Tips:")
                        .font(.caption.bold())
                    Text("• Press Control + Space to toggle the floating launcher anywhere.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Press 1-9 to immediately open the corresponding shortcut.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Use Up/Down arrow keys and Enter to navigate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Press Escape to dismiss.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 24)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 380)
    }
}

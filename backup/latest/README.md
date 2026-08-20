# ProjectDeck 📁✨

**ProjectDeck** is a native macOS background productivity utility that provides instant access to your project folders via a floating shortcut panel positioned directly at your mouse cursor.

---

## 🌟 Key Features

- **Global Hotkey Trigger (`Control + Space`)**: Instantly toggle the floating launcher from any active application (Finder, Premiere Pro, After Effects, Photoshop, Safari, VS Code, Chrome, etc.).
- **Smart Mouse Cursor Positioning**: Uses `NSEvent.mouseLocation` and intelligent display boundary clamping so the launcher always appears cleanly adjacent to your cursor across single and multi-monitor setups.
- **Drag & Drop Folder Setup**: Easily drag any folder from macOS Finder directly into the shortcut manager.
- **Persistent Access via Security-Scoped Bookmarks**: Stored folder permissions survive macOS reboots, system updates, and app relaunches.
- **Instant Search & Filter**: Type immediately when the panel opens to filter folders in real time.
- **Keyboard Navigation & Quick Slots**:
  - `1` – `9`: Instantly open slot 1 to 9.
  - `↑` / `↓`: Navigate through items.
  - `Return`: Open selected folder in Finder.
  - `Esc`: Dismiss the launcher.
- **Menu Bar Utility**: Runs silently in the background (`LSUIElement`) with status item menu:
  - *Show Launcher*
  - *Manage Shortcuts...*
  - *Settings...*
  - *Launch at Login*
  - *About*
  - *Quit*
- **Offline & Native**: 100% Swift & SwiftUI. Zero cloud dependencies, zero Electron, minimal idle CPU/RAM footprint.

---

## 📂 Project Architecture

```text
ProjectDeck/
├── App/
│   ├── ProjectDeckApp.swift          # Main SwiftUI App entry point
│   ├── AppDelegate.swift             # App lifecycle, hotkey & window wiring
│   └── MenuBarController.swift       # NSStatusItem and menu configuration
│
├── Models/
│   ├── FolderShortcut.swift          # Core shortcut model with bookmark data & colors
│   ├── FolderGroup.swift             # Group/Category model
│   └── AppPreferences.swift          # Hotkey & user settings model
│
├── Managers/
│   ├── ShortcutManager.swift         # CRUD, JSON persistence & state management
│   ├── HotkeyManager.swift           # Native Carbon global hotkey registration
│   ├── BookmarkManager.swift         # Security-Scoped Bookmarks handler
│   └── LaunchAtLoginManager.swift    # SMAppService launch at login integration
│
├── FloatingLauncher/
│   ├── FloatingPanel.swift           # Custom floating non-activating NSPanel
│   ├── FloatingPanelController.swift # Cursor tracking & outside-click dismissal
│   ├── FloatingLauncherView.swift    # Glassmorphic SwiftUI launcher panel
│   └── ShortcutItemView.swift        # Interactive folder item button
│
├── Management/
│   ├── ManageShortcutsView.swift     # Management window with reordering & slots
│   ├── ShortcutEditorSheet.swift     # Modal for editing label, color, and group
│   └── FolderDropZoneView.swift      # Drag & Drop receiver with validation
│
├── Settings/
│   ├── SettingsView.swift            # Settings UI (General, Hotkey, About)
│   ├── HotkeyRecorderView.swift      # Visual hotkey recorder & conflict helper
│   └── SettingsWindowController.swift# WindowManager for native windows
│
├── Utilities/
│   ├── ScreenPositioner.swift        # Multi-monitor & screen edge clamping
│   ├── FolderUtilities.swift         # Finder opening, status checking & paths
│   └── VisualEffectView.swift        # Native macOS glassmorphism wrapper
│
├── Resources/
│   ├── Assets.xcassets               # App icon & accent color sets
│   └── Info.plist                    # App metadata & LSUIElement flag
│
├── scripts/
│   └── build_app.sh                  # One-click release app bundle builder
│
├── Package.swift                     # Swift Package Manager manifest
└── ProjectDeck.xcodeproj             # Xcode project configuration
```

---

## 🚀 Building & Running

### Option 1: Build Application Bundle (Recommended)

Run the included build script to generate `build/ProjectDeck.app`:

```bash
./scripts/build_app.sh
```

To launch the built app:

```bash
open build/ProjectDeck.app
```

### Option 2: Swift Package Manager CLI

Build and run directly in development mode:

```bash
swift run
```

### Option 3: Open in Xcode

You can open either the `ProjectDeck.xcodeproj` or the project folder directly in Xcode:

```bash
open ProjectDeck.xcodeproj
```

---

## ⌨️ Global Hotkey & Troubleshooting

### Default Shortcut
- **`Control + Space`** (`⌃ Space`)

### Customizing the Shortcut
You can change the global shortcut anytime in **Menu Bar Icon → Settings... → Hotkeys** or choose from popular presets (`⌥ Space`, `⌘ ⌥ Space`, `⌃ ⌥ P`, etc.).

### macOS Input Sources Conflict Note
By default, some macOS versions map `Control + Space` to switch keyboard input languages. If a conflict occurs:
1. Open **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**.
2. Uncheck or remap "Select the previous input source".
3. Alternatively, pick another shortcut inside **ProjectDeck Settings**.

---

## 🔒 Permissions & Security

- **Security-Scoped Bookmarks**: When you add a folder to ProjectDeck, a security-scoped bookmark is created. This ensures the app can access and open the folder across system restarts even if the app runs in sandboxed environments.
- **External Drives / Network Shares**: If an external SSD or network drive is disconnected, ProjectDeck marks the folder with a subtle status badge (`Drive not connected`) rather than deleting your shortcut. Once reconnected, it works immediately.

---

## 📋 Definition of Done Checklist

- [x] Background menu bar agent (`LSUIElement`)
- [x] Global hotkey toggle (`Control + Space` via Carbon `RegisterEventHotKey`)
- [x] Floating `NSPanel` at active mouse cursor position
- [x] Multi-monitor and screen edge boundary clamping
- [x] Drag and drop folder receiver with directory validation
- [x] Security-scoped bookmark persistence (`~/Library/Application Support/ProjectDeck/`)
- [x] Instant search filtering
- [x] Keyboard navigation (`1-9` numeric keys, Arrow keys, Enter, Esc)
- [x] Manage Shortcuts & Settings window
- [x] Launch at Login via `SMAppService`
- [x] Dark Mode and Light Mode support
- [x] Zero build warnings on macOS Sonoma / Swift 6
- [x] Installer (.dmg) packaging ready for subsequent phase upon instruction

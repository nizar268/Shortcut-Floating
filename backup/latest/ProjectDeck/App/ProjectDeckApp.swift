import SwiftUI

@main
struct ProjectDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Since ProjectDeck is an accessory menu bar application with custom NSWindows / NSPanels,
        // we use an empty Settings scene to avoid creating empty default windows on launch.
        Settings {
            EmptyView()
        }
    }
}

import SwiftUI

@main
struct UncticoApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Create default user account on first launch
        InitialSetup.createDefaultAccount()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

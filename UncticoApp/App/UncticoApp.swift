// UncticoApp.swift
// Main app entry point
// QA Note: This is where the app starts

import SwiftUI

@main
struct UncticoApp: App {

    // Initialize core services when app launches
    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            // Show login screen if not authenticated, otherwise show main app
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

/// Manages overall app state
/// Simple class to track what's happening in the app
class AppState: ObservableObject {

    // Is the app currently loading something?
    @Published var isLoading = false

    // Any error messages to show
    @Published var errorMessage: String?

    // Is the app in the background?
    @Published var isInBackground = false

    // When did the app go to background?
    @Published var backgroundTime: Date?

    init() {
        setupBackgroundDetection()
    }

    /// Detect when app goes to background
    /// QA Note: Used for auto-logout feature
    private func setupBackgroundDetection() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isInBackground = true
            self?.backgroundTime = Date()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isInBackground = false
            self?.checkIfNeedsReauth()
        }
    }

    /// Check if user needs to re-authenticate
    /// QA Note: This runs when app comes back from background
    private func checkIfNeedsReauth() {
        guard let backgroundTime = backgroundTime else { return }

        let timeInBackground = Date().timeIntervalSince(backgroundTime)
        let maxBackgroundTime = TimeInterval(AppConfig.autoLogoutMinutes * 60)

        if timeInBackground > maxBackgroundTime {
            // App was in background too long - require re-authentication
            NotificationCenter.default.post(name: .requireReauth, object: nil)
        }
    }
}

// Custom notification names
extension Notification.Name {
    static let requireReauth = Notification.Name("requireReauth")
}

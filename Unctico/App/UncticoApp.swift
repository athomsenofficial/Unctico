// UncticoApp.swift
// Main entry point for the Unctico massage therapy business management app

import SwiftUI

/// The main app structure
/// This is the first thing that runs when the app launches
@main
struct UncticoApp: App {

    // MARK: - Properties

    /// Manages the app's overall state (logged in, onboarding, etc.)
    @StateObject private var appState = AppStateManager()

    /// Manages user authentication (login, logout, session)
    @StateObject private var authManager = AuthenticationManager()

    /// Manages secure database operations
    @StateObject private var databaseManager = DatabaseManager()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            // Show different screens based on authentication status
            if authManager.isAuthenticated {
                // User is logged in - show main app
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authManager)
                    .environmentObject(databaseManager)
            } else {
                // User is not logged in - show login/onboarding
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
    }
}

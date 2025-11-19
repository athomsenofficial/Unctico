// AppStateManager.swift
// Manages the overall state of the app (which screen to show, loading states, etc.)

import SwiftUI

/// Controls the overall state of the application
/// This is a single source of truth for app-wide state
class AppStateManager: ObservableObject {

    // MARK: - Published Properties

    /// Is the app currently loading something?
    @Published var isLoading: Bool = false

    /// Is this the first time the app is being launched?
    @Published var isFirstLaunch: Bool = true

    /// Has the user completed onboarding?
    @Published var hasCompletedOnboarding: Bool = false

    /// The current selected tab in the main navigation
    @Published var selectedTab: MainTab = .dashboard

    /// Any error message to show to the user
    @Published var errorMessage: String?

    /// Is there currently an error to display?
    @Published var showError: Bool = false

    // MARK: - Initialization

    init() {
        loadAppState()
    }

    // MARK: - Public Methods

    /// Load the app state from storage
    func loadAppState() {
        // Check if app has been launched before
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        // Check if onboarding was completed
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    /// Mark that the app has been launched
    func markAppAsLaunched() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        isFirstLaunch = false
    }

    /// Mark that onboarding has been completed
    func markOnboardingAsCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }

    /// Show an error message to the user
    /// - Parameter message: The error message to display
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Clear the current error message
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Main Tab Enum

/// The main tabs available in the app
enum MainTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case clients = "Clients"
    case schedule = "Schedule"
    case soapNotes = "SOAP Notes"
    case billing = "Billing"

    /// The SF Symbol icon for this tab
    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar.fill"
        case .clients:
            return "person.2.fill"
        case .schedule:
            return "calendar"
        case .soapNotes:
            return "doc.text.fill"
        case .billing:
            return "dollarsign.circle.fill"
        }
    }
}

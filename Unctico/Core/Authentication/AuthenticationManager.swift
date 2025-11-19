// AuthenticationManager.swift
// Handles user login, logout, and session management

import SwiftUI
import Combine

/// Manages user authentication and session state
/// This controls whether user is logged in and handles login/logout
class AuthenticationManager: ObservableObject {

    // MARK: - Published Properties

    /// Is the user currently authenticated (logged in)?
    @Published var isAuthenticated: Bool = false

    /// The currently logged in user
    @Published var currentUser: User?

    /// Is a login/logout operation currently in progress?
    @Published var isLoading: Bool = false

    /// Any error from authentication operations
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Keychain manager for secure storage
    private let keychainManager = KeychainManager.shared

    /// Key for storing user data in UserDefaults
    private let currentUserKey = "currentUser"

    // MARK: - Initialization

    init() {
        checkAuthenticationStatus()
    }

    // MARK: - Public Methods

    /// Check if user is already authenticated (has valid session)
    func checkAuthenticationStatus() {
        // Check if we have a stored auth token
        if let _ = keychainManager.getString(forKey: KeychainKey.authToken) {
            // Load the user data
            loadCurrentUser()
            isAuthenticated = currentUser != nil
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }

    /// Log in a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // TODO: Replace with actual API call to backend
        // For now, we'll do basic validation

        guard !email.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "Please enter both email and password"
                isLoading = false
            }
            return
        }

        guard email.contains("@") else {
            await MainActor.run {
                errorMessage = "Please enter a valid email address"
                isLoading = false
            }
            return
        }

        // For demo purposes, accept any valid email/password combo
        // In production, this would call your backend API

        // Create a user object
        let user = User(email: email, fullName: "Demo Therapist")

        // Generate a mock auth token
        let authToken = UUID().uuidString

        // Save the token securely
        let tokenSaved = keychainManager.save(authToken, forKey: KeychainKey.authToken)

        guard tokenSaved else {
            await MainActor.run {
                errorMessage = "Failed to save authentication token"
                isLoading = false
            }
            return
        }

        // Save the user data
        saveCurrentUser(user)

        await MainActor.run {
            currentUser = user
            isAuthenticated = true
            isLoading = false
        }
    }

    /// Register a new user account
    /// - Parameters:
    ///   - email: Email address for new account
    ///   - password: Password for new account
    ///   - fullName: User's full name
    func register(email: String, password: String, fullName: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Validate inputs
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            await MainActor.run {
                errorMessage = "Please fill in all fields"
                isLoading = false
            }
            return
        }

        guard email.contains("@") else {
            await MainActor.run {
                errorMessage = "Please enter a valid email address"
                isLoading = false
            }
            return
        }

        guard password.count >= 8 else {
            await MainActor.run {
                errorMessage = "Password must be at least 8 characters"
                isLoading = false
            }
            return
        }

        // TODO: Call backend API to create account
        // For now, simulate the registration

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Create the new user
        let newUser = User(email: email, fullName: fullName)

        // Generate auth token
        let authToken = UUID().uuidString

        // Save credentials securely
        keychainManager.save(authToken, forKey: KeychainKey.authToken)
        keychainManager.save(password, forKey: KeychainKey.userPassword)

        // Save user data
        saveCurrentUser(newUser)

        await MainActor.run {
            currentUser = newUser
            isAuthenticated = true
            isLoading = false
        }
    }

    /// Log out the current user
    func logout() {
        // Delete all keychain data
        keychainManager.delete(forKey: KeychainKey.authToken)
        keychainManager.delete(forKey: KeychainKey.userPassword)
        keychainManager.delete(forKey: KeychainKey.refreshToken)

        // Clear user data
        UserDefaults.standard.removeObject(forKey: currentUserKey)

        // Update state
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Private Methods

    /// Save the current user to UserDefaults
    /// - Parameter user: The user to save
    private func saveCurrentUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }

    /// Load the current user from UserDefaults
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }
}

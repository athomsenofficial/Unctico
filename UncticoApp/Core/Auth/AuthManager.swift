// AuthManager.swift
// Handles user authentication and security
// QA Note: Manages login, Face ID/Touch ID, and security

import Foundation
import LocalAuthentication
import Combine

/// Manages user authentication
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var failedAttempts = 0
    @Published var isLocked = false
    @Published var lockoutEndTime: Date?

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let context = LAContext()

    // UserDefaults keys
    private let isAuthenticatedKey = "isAuthenticated"
    private let failedAttemptsKey = "failedAttempts"
    private let lockoutEndTimeKey = "lockoutEndTime"

    // MARK: - Initialization

    init() {
        loadAuthState()
        checkLockout()
    }

    // MARK: - Load State

    /// Load authentication state from storage
    /// QA Note: This remembers if user was logged in
    private func loadAuthState() {
        // Don't auto-login if app was closed
        // Always require authentication on app launch
        self.isAuthenticated = false
        self.failedAttempts = userDefaults.integer(forKey: failedAttemptsKey)

        if let lockoutDate = userDefaults.object(forKey: lockoutEndTimeKey) as? Date {
            self.lockoutEndTime = lockoutDate
        }
    }

    /// Check if account is currently locked out
    private func checkLockout() {
        guard let lockoutEnd = lockoutEndTime else {
            isLocked = false
            return
        }

        if Date() < lockoutEnd {
            // Still locked
            isLocked = true
        } else {
            // Lockout period ended
            unlockAccount()
        }
    }

    // MARK: - Biometric Authentication

    /// Authenticate using Face ID or Touch ID
    /// QA Note: This shows the Face ID/Touch ID prompt
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        // Check if locked out
        if isLocked {
            let remaining = Int(lockoutEndTime?.timeIntervalSinceNow ?? 0)
            completion(false, "Account locked. Try again in \(remaining) seconds.")
            return
        }

        // Check if biometrics are available
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available, fall back to passcode
            completion(false, "Biometrics not available: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        // Show biometric prompt
        let reason = "Authenticate to access Unctico"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    self?.loginSuccessful()
                    completion(true, nil)
                } else {
                    self?.loginFailed()
                    completion(false, authError?.localizedDescription)
                }
            }
        }
    }

    /// Authenticate with passcode
    /// QA Note: This is the backup authentication method
    func authenticateWithPasscode(_ passcode: String, completion: @escaping (Bool, String?) -> Void) {
        // Check if locked out
        if isLocked {
            let remaining = Int(lockoutEndTime?.timeIntervalSinceNow ?? 0)
            completion(false, "Account locked. Try again in \(remaining) seconds.")
            return
        }

        // Get stored passcode
        guard let storedPasscode = userDefaults.string(forKey: "userPasscode") else {
            // No passcode set - this is first time setup
            savePasscode(passcode)
            loginSuccessful()
            completion(true, nil)
            return
        }

        // Verify passcode
        if passcode == storedPasscode {
            loginSuccessful()
            completion(true, nil)
        } else {
            loginFailed()
            completion(false, "Incorrect passcode")
        }
    }

    // MARK: - Login Success/Failure

    /// Handle successful login
    /// QA Note: This runs after successful authentication
    private func loginSuccessful() {
        isAuthenticated = true
        failedAttempts = 0
        userDefaults.set(0, forKey: failedAttemptsKey)

        // Load or create user
        loadUser()
    }

    /// Handle failed login attempt
    /// QA Note: This tracks failed attempts and locks account if needed
    private func loginFailed() {
        failedAttempts += 1
        userDefaults.set(failedAttempts, forKey: failedAttemptsKey)

        // Lock account after max attempts
        if failedAttempts >= AppConfig.maxLoginAttempts {
            lockAccount()
        }
    }

    // MARK: - Account Locking

    /// Lock account for configured duration
    /// QA Note: This prevents brute force attacks
    private func lockAccount() {
        isLocked = true
        lockoutEndTime = Date().addingTimeInterval(TimeInterval(AppConfig.lockoutDurationSeconds))
        userDefaults.set(lockoutEndTime, forKey: lockoutEndTimeKey)

        // Auto-unlock after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(AppConfig.lockoutDurationSeconds)) { [weak self] in
            self?.unlockAccount()
        }
    }

    /// Unlock account
    private func unlockAccount() {
        isLocked = false
        lockoutEndTime = nil
        failedAttempts = 0
        userDefaults.removeObject(forKey: lockoutEndTimeKey)
        userDefaults.set(0, forKey: failedAttemptsKey)
    }

    // MARK: - User Management

    /// Load user from storage or create new user
    private func loadUser() {
        if let userData = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        } else {
            // Create default user
            createDefaultUser()
        }
    }

    /// Create default user for solo practitioner
    private func createDefaultUser() {
        let user = User(
            id: UUID(),
            firstName: "Therapist",
            lastName: "User",
            email: "therapist@unctico.com",
            role: .owner
        )
        currentUser = user
        saveUser(user)
    }

    /// Save user to storage
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: "currentUser")
        }
    }

    /// Save passcode
    private func savePasscode(_ passcode: String) {
        userDefaults.set(passcode, forKey: "userPasscode")
    }

    // MARK: - Logout

    /// Logout user
    /// QA Note: Call this to log user out
    func logout() {
        isAuthenticated = false
        currentUser = nil
        userDefaults.set(false, forKey: isAuthenticatedKey)
    }

    // MARK: - Passcode Management

    /// Check if passcode is set
    func hasPasscode() -> Bool {
        userDefaults.string(forKey: "userPasscode") != nil
    }

    /// Change passcode
    func changePasscode(old: String, new: String, completion: @escaping (Bool, String?) -> Void) {
        guard let storedPasscode = userDefaults.string(forKey: "userPasscode") else {
            completion(false, "No passcode set")
            return
        }

        if old == storedPasscode {
            savePasscode(new)
            completion(true, nil)
        } else {
            completion(false, "Incorrect old passcode")
        }
    }
}

// MARK: - User Model

/// Represents a user of the app (therapist/staff)
struct User: Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var role: UserRole

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    init(id: UUID = UUID(), firstName: String, lastName: String, email: String, role: UserRole) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
    }
}

/// User role in the app
enum UserRole: String, Codable {
    case owner = "Owner"
    case admin = "Administrator"
    case therapist = "Therapist"
    case frontDesk = "Front Desk"
}

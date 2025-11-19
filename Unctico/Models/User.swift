// User.swift
// Represents a therapist user in the Unctico app

import Foundation

/// Represents a massage therapist who uses the app
struct User: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for this user
    let id: UUID

    /// Therapist's email address (used for login)
    var email: String

    /// Therapist's full name
    var fullName: String

    /// Therapist's professional license number
    var licenseNumber: String?

    /// State/province where licensed
    var licenseState: String?

    /// License expiration date
    var licenseExpirationDate: Date?

    /// Business name (if different from personal name)
    var businessName: String?

    /// Phone number for business
    var phoneNumber: String?

    /// When this user account was created
    let createdAt: Date

    /// When this user account was last updated
    var updatedAt: Date

    // MARK: - Initialization

    /// Creates a new user
    /// - Parameters:
    ///   - email: The user's email address
    ///   - fullName: The user's full name
    init(email: String, fullName: String) {
        self.id = UUID()
        self.email = email
        self.fullName = fullName
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns true if the license is expired or expiring within 30 days
    var isLicenseExpiringSoon: Bool {
        guard let expirationDate = licenseExpirationDate else {
            return false
        }

        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expirationDate <= thirtyDaysFromNow
    }
}

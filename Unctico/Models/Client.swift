// Client.swift
// Represents a client/patient in the massage practice

import Foundation

/// Represents a client who receives massage therapy services
struct Client: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for this client
    let id: UUID

    /// Client's first name
    var firstName: String

    /// Client's last name
    var lastName: String

    /// Client's email address
    var email: String?

    /// Client's phone number
    var phoneNumber: String?

    /// Client's date of birth
    var dateOfBirth: Date?

    /// Emergency contact name
    var emergencyContactName: String?

    /// Emergency contact phone number
    var emergencyContactPhone: String?

    /// When this client was first added
    let createdAt: Date

    /// When this client record was last updated
    var updatedAt: Date

    /// Notes about client preferences (pressure, temperature, etc.)
    var preferenceNotes: String?

    /// Is this client currently active?
    var isActive: Bool

    // MARK: - Initialization

    /// Creates a new client
    /// - Parameters:
    ///   - firstName: Client's first name
    ///   - lastName: Client's last name
    init(firstName: String, lastName: String) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
    }

    // MARK: - Computed Properties

    /// Client's full name (first + last)
    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    /// Client's age (calculated from date of birth)
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else {
            return nil
        }

        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }
}

// Client.swift
// Model for client/patient information
// QA Note: This represents a single client in the system

import Foundation
import SwiftUI

/// Represents a massage therapy client
/// Contains all personal and medical information
struct Client: Identifiable, Codable {

    // MARK: - Basic Information

    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var dateOfBirth: Date
    var createdDate: Date
    var lastVisitDate: Date?

    // MARK: - Contact Information

    var address: Address?
    var emergencyContact: EmergencyContact?

    // MARK: - Medical Information

    var medicalHistory: MedicalHistory
    var allergies: [String]
    var medications: [Medication]
    var chronicConditions: [String]

    // MARK: - Preferences

    var preferences: ClientPreferences

    // MARK: - Status

    var isActive: Bool
    var notes: String

    // MARK: - Computed Properties

    /// Full name for display
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Age calculated from date of birth
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    /// Initialize a new client with default values
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        dateOfBirth: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.createdDate = Date()
        self.isActive = true
        self.notes = ""
        self.medicalHistory = MedicalHistory()
        self.allergies = []
        self.medications = []
        self.chronicConditions = []
        self.preferences = ClientPreferences()
    }
}

/// Client's physical address
struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String

    var formatted: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
}

/// Emergency contact information
struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phone: String
}

/// Client's medical history
struct MedicalHistory: Codable {
    var surgeries: [Surgery]
    var injuries: [Injury]
    var hasHeartCondition: Bool
    var hasHighBloodPressure: Bool
    var hasDiabetes: Bool
    var isPregnant: Bool
    var pregnancyWeek: Int?

    init() {
        self.surgeries = []
        self.injuries = []
        self.hasHeartCondition = false
        self.hasHighBloodPressure = false
        self.hasDiabetes = false
        self.isPregnant = false
        self.pregnancyWeek = nil
    }
}

/// Record of a surgery
struct Surgery: Identifiable, Codable {
    let id: UUID
    var type: String
    var date: Date
    var notes: String

    init(id: UUID = UUID(), type: String, date: Date, notes: String = "") {
        self.id = id
        self.type = type
        self.date = date
        self.notes = notes
    }
}

/// Record of an injury
struct Injury: Identifiable, Codable {
    let id: UUID
    var type: String
    var date: Date
    var severity: InjurySeverity
    var notes: String

    init(id: UUID = UUID(), type: String, date: Date, severity: InjurySeverity, notes: String = "") {
        self.id = id
        self.type = type
        self.date = date
        self.severity = severity
        self.notes = notes
    }
}

/// How severe an injury is
enum InjurySeverity: String, Codable, CaseIterable {
    case minor = "Minor"
    case moderate = "Moderate"
    case severe = "Severe"
}

/// Current medication
struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: String
    var startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), name: String, dosage: String, frequency: String, startDate: Date = Date()) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.startDate = startDate
    }
}

/// Client preferences for treatments
struct ClientPreferences: Codable {

    // Pressure preference
    var pressureLevel: PressureLevel

    // Room temperature preference
    var temperaturePreference: TemperatureLevel

    // Music preference
    var musicType: MusicType

    // Aromatherapy preferences
    var aromas: [String]

    // Preferred therapist
    var preferredTherapistId: UUID?

    // Preferred appointment time
    var preferredTimeOfDay: TimeOfDay?

    // Communication preferences
    var emailReminders: Bool
    var smsReminders: Bool
    var callReminders: Bool

    init() {
        self.pressureLevel = .medium
        self.temperaturePreference = .comfortable
        self.musicType = .relaxing
        self.aromas = []
        self.emailReminders = true
        self.smsReminders = true
        self.callReminders = false
    }
}

/// How much pressure client prefers
enum PressureLevel: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case firm = "Firm"
    case deep = "Deep Tissue"
}

/// Room temperature preference
enum TemperatureLevel: String, Codable, CaseIterable {
    case cool = "Cool"
    case comfortable = "Comfortable"
    case warm = "Warm"
}

/// Type of music
enum MusicType: String, Codable, CaseIterable {
    case none = "No Music"
    case relaxing = "Relaxing"
    case nature = "Nature Sounds"
    case classical = "Classical"
    case custom = "Custom Playlist"
}

/// Time of day preference
enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
}

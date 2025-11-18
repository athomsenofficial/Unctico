// Therapist.swift
// Model for massage therapist
// QA Note: Represents a therapist/practitioner

import Foundation

/// Massage therapist/practitioner
struct Therapist: Identifiable, Codable {

    // MARK: - Basic Information

    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String

    // MARK: - Professional Information

    var licenseNumber: String
    var licenseState: String
    var licenseExpiration: Date
    var certifications: [Certification]
    var specialties: [String]

    // MARK: - Schedule

    var workingHours: [WeekdaySchedule]
    var isActive: Bool

    // MARK: - Computed Properties

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Is license expired or expiring soon?
    var needsLicenseRenewal: Bool {
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: licenseExpiration).day ?? 0
        return daysUntilExpiration < 60  // Warn if less than 60 days
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        licenseNumber: String,
        licenseState: String,
        licenseExpiration: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.licenseState = licenseState
        self.licenseExpiration = licenseExpiration
        self.certifications = []
        self.specialties = []
        self.workingHours = WeekdaySchedule.defaultSchedule()
        self.isActive = true
    }
}

/// Professional certification
struct Certification: Identifiable, Codable {
    let id: UUID
    var name: String
    var issuingOrganization: String
    var issueDate: Date
    var expirationDate: Date?
    var certificateNumber: String

    init(
        id: UUID = UUID(),
        name: String,
        issuingOrganization: String,
        issueDate: Date,
        expirationDate: Date? = nil,
        certificateNumber: String = ""
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.certificateNumber = certificateNumber
    }
}

/// Working hours for a weekday
struct WeekdaySchedule: Identifiable, Codable {
    let id: UUID
    var weekday: Weekday
    var isWorking: Bool
    var startTime: Date  // Time only
    var endTime: Date    // Time only
    var breakStart: Date?
    var breakEnd: Date?

    init(
        id: UUID = UUID(),
        weekday: Weekday,
        isWorking: Bool = true,
        startTime: Date = Date(),
        endTime: Date = Date()
    ) {
        self.id = id
        self.weekday = weekday
        self.isWorking = isWorking
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Default 9-5 schedule for all weekdays
    static func defaultSchedule() -> [WeekdaySchedule] {
        let calendar = Calendar.current
        let startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        let endTime = calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()

        return Weekday.allCases.map { weekday in
            WeekdaySchedule(
                weekday: weekday,
                isWorking: weekday != .sunday && weekday != .saturday,
                startTime: startTime,
                endTime: endTime
            )
        }
    }
}

/// Days of the week
enum Weekday: String, Codable, CaseIterable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
}

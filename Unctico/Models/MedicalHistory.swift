// MedicalHistory.swift
// Comprehensive medical history tracking for clients

import Foundation

/// Medical history for a client
/// This is updated over time as conditions change
struct MedicalHistory: Codable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let clientId: UUID

    // MARK: - Current Health Status

    /// Active health conditions
    var activeConditions: [HealthCondition]

    /// Resolved health conditions
    var resolvedConditions: [HealthCondition]

    /// Current medications and supplements
    var currentMedications: [Medication]

    /// Known allergies
    var allergies: [Allergy]

    // MARK: - Surgical History

    /// All past surgeries
    var surgeries: [Surgery]

    /// Implants or medical devices
    var implants: [MedicalImplant]

    // MARK: - Women's Health (if applicable)

    /// Is client pregnant?
    var isPregnant: Bool

    /// Current trimester (if pregnant)
    var trimester: Int?

    /// Due date (if pregnant)
    var dueDate: Date?

    /// Is client nursing?
    var isNursing: Bool

    /// Last menstrual period
    var lastMenstrualPeriod: Date?

    /// Menopause status
    var menopauseStatus: MenopauseStatus?

    // MARK: - Injury History

    /// Past and current injuries
    var injuries: [Injury]

    /// Chronic pain areas
    var chronicPainAreas: [BodyArea]

    // MARK: - Lifestyle Factors

    /// Typical sleep hours per night
    var averageSleepHours: Double?

    /// Sleep quality rating (1-5)
    var sleepQuality: Int?

    /// Current stress level (1-10)
    var stressLevel: Int?

    /// Primary stress triggers
    var stressTriggers: [String]

    /// Exercise routine
    var exerciseRoutine: String?

    /// Occupation and physical demands
    var occupationDetails: String?

    /// Hobbies and activities
    var hobbies: [String]

    // MARK: - Contraindications

    /// Calculated contraindications for massage
    var contraindications: [Contraindication]

    // MARK: - Physician Information

    /// Primary care physician
    var primaryCarePhysician: PhysicianContact?

    /// Specialists being seen
    var specialists: [PhysicianContact]

    /// Recent physician visits
    var recentPhysicianVisits: [PhysicianVisit]

    // MARK: - Metadata

    let createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(clientId: UUID) {
        self.id = UUID()
        self.clientId = clientId
        self.activeConditions = []
        self.resolvedConditions = []
        self.currentMedications = []
        self.allergies = []
        self.surgeries = []
        self.implants = []
        self.isPregnant = false
        self.isNursing = false
        self.injuries = []
        self.chronicPainAreas = []
        self.stressTriggers = []
        self.hobbies = []
        self.contraindications = []
        self.specialists = []
        self.recentPhysicianVisits = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Are there any absolute contraindications?
    var hasAbsoluteContraindications: Bool {
        contraindications.contains { $0.severity == .absolute }
    }

    /// Current medication count
    var medicationCount: Int {
        currentMedications.count
    }

    /// Active allergy count
    var allergyCount: Int {
        allergies.count
    }
}

// MARK: - Supporting Types

struct MedicalImplant: Codable, Identifiable {
    let id: UUID
    var type: String
    var location: BodyArea
    var implantDate: Date?
    var notes: String?

    init(type: String, location: BodyArea) {
        self.id = UUID()
        self.type = type
        self.location = location
    }
}

enum MenopauseStatus: String, Codable {
    case premenopausal = "Premenopausal"
    case perimenopausal = "Perimenopausal"
    case postmenopausal = "Postmenopausal"
}

struct Injury: Codable, Identifiable {
    let id: UUID
    var description: String
    var injuryDate: Date?
    var affectedAreas: [BodyArea]
    var isResolved: Bool
    var notes: String?

    init(description: String, affectedAreas: [BodyArea]) {
        self.id = UUID()
        self.description = description
        self.affectedAreas = affectedAreas
        self.isResolved = false
    }
}

struct Contraindication: Codable, Identifiable {
    let id: UUID
    var condition: String
    var severity: ContraindicationSeverity
    var affectedAreas: [BodyArea]
    var notes: String?

    init(condition: String, severity: ContraindicationSeverity, affectedAreas: [BodyArea] = []) {
        self.id = UUID()
        self.condition = condition
        self.severity = severity
        self.affectedAreas = affectedAreas
    }
}

enum ContraindicationSeverity: String, Codable {
    case absolute = "Absolute" // No massage allowed
    case local = "Local"       // Avoid specific areas
    case caution = "Caution"   // Proceed with modifications
}

struct PhysicianContact: Codable, Identifiable {
    let id: UUID
    var name: String
    var specialty: String?
    var phoneNumber: String?
    var faxNumber: String?
    var email: String?

    init(name: String, specialty: String? = nil) {
        self.id = UUID()
        self.name = name
        self.specialty = specialty
    }
}

struct PhysicianVisit: Codable, Identifiable {
    let id: UUID
    var physicianName: String
    var visitDate: Date
    var reason: String
    var diagnosis: String?
    var treatment: String?

    init(physicianName: String, visitDate: Date, reason: String) {
        self.id = UUID()
        self.physicianName = physicianName
        self.visitDate = visitDate
        self.reason = reason
    }
}

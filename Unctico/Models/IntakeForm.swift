// IntakeForm.swift
// Client intake form model for initial assessment

import Foundation

/// Client intake form for first visit or annual updates
struct IntakeForm: Codable, Identifiable {

    // MARK: - Properties

    let id: UUID
    let clientId: UUID
    var formDate: Date

    // MARK: - Personal Information

    var occupation: String?
    var maritalStatus: MaritalStatus?
    var referralSource: String?

    // MARK: - Medical History

    /// Current health conditions
    var currentConditions: [HealthCondition]

    /// Past surgeries
    var pastSurgeries: [Surgery]

    /// Current medications
    var medications: [Medication]

    /// Allergies and sensitivities
    var allergies: [Allergy]

    /// Pregnancy status (if applicable)
    var isPregnant: Bool
    var pregnancyWeeks: Int?

    /// Family medical history
    var familyHistory: String?

    // MARK: - Current Complaints

    /// Primary reason for seeking massage
    var chiefComplaint: String

    /// Pain level (0-10)
    var painLevel: Int

    /// Pain location
    var painLocation: [BodyArea]

    /// How long has this been an issue?
    var symptomDuration: String?

    /// What makes it better?
    var relievingFactors: String?

    /// What makes it worse?
    var aggravatingFactors: String?

    /// Previous treatment for this issue
    var previousTreatment: String?

    // MARK: - Lifestyle Factors

    /// Sleep quality (1-5)
    var sleepQuality: Int?

    /// Stress level (1-5)
    var stressLevel: Int?

    /// Exercise frequency
    var exerciseFrequency: ExerciseFrequency?

    /// Water intake (glasses per day)
    var waterIntake: Int?

    /// Tobacco use
    var usesTobacco: Bool

    /// Alcohol consumption
    var alcoholConsumption: AlcoholFrequency?

    // MARK: - Massage History

    /// Has received massage before?
    var hasPreviousMassageExperience: Bool

    /// Preferred pressure
    var preferredPressure: PressureLevel?

    /// Areas to focus on
    var areasToFocus: [BodyArea]

    /// Areas to avoid
    var areasToAvoid: [BodyArea]

    /// Any concerns about massage?
    var massageConcerns: String?

    // MARK: - Consents

    /// Date client signed informed consent
    var informedConsentDate: Date?

    /// Date client signed HIPAA notice
    var hipaaConsentDate: Date?

    /// Photo/video consent
    var photoConsentGiven: Bool

    /// Text message consent for reminders
    var smsConsentGiven: Bool

    // MARK: - Metadata

    let createdAt: Date
    var updatedAt: Date
    var isComplete: Bool

    // MARK: - Initialization

    init(clientId: UUID) {
        self.id = UUID()
        self.clientId = clientId
        self.formDate = Date()
        self.currentConditions = []
        self.pastSurgeries = []
        self.medications = []
        self.allergies = []
        self.isPregnant = false
        self.chiefComplaint = ""
        self.painLevel = 0
        self.painLocation = []
        self.areasToFocus = []
        self.areasToAvoid = []
        self.usesTobacco = false
        self.hasPreviousMassageExperience = false
        self.photoConsentGiven = false
        self.smsConsentGiven = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isComplete = false
    }
}

// MARK: - Supporting Types

enum MaritalStatus: String, Codable, CaseIterable {
    case single = "Single"
    case married = "Married"
    case divorced = "Divorced"
    case widowed = "Widowed"
    case partnered = "Partnered"
}

struct HealthCondition: Codable, Identifiable {
    let id: UUID
    var name: String
    var diagnosedDate: Date?
    var isCurrent: Bool

    init(name: String, isCurrent: Bool = true) {
        self.id = UUID()
        self.name = name
        self.isCurrent = isCurrent
    }
}

struct Surgery: Codable, Identifiable {
    let id: UUID
    var procedureName: String
    var surgeryDate: Date?
    var notes: String?

    init(procedureName: String, surgeryDate: Date? = nil) {
        self.id = UUID()
        self.procedureName = procedureName
        self.surgeryDate = surgeryDate
    }
}

struct Medication: Codable, Identifiable {
    let id: UUID
    var name: String
    var dosage: String?
    var frequency: String?
    var purpose: String?

    init(name: String, dosage: String? = nil) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
    }
}

struct Allergy: Codable, Identifiable {
    let id: UUID
    var allergen: String
    var reaction: String?
    var severity: AllergySeverity

    init(allergen: String, severity: AllergySeverity = .moderate) {
        self.id = UUID()
        self.allergen = allergen
        self.severity = severity
    }
}

enum AllergySeverity: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case anaphylactic = "Anaphylactic"
}

enum ExerciseFrequency: String, Codable, CaseIterable {
    case none = "None"
    case onceAWeek = "1x per week"
    case twiceAWeek = "2x per week"
    case threePlusAWeek = "3+ per week"
    case daily = "Daily"
}

enum AlcoholFrequency: String, Codable, CaseIterable {
    case never = "Never"
    case occasionally = "Occasionally"
    case weekly = "Weekly"
    case daily = "Daily"
}

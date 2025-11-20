import Foundation
import SwiftUI

/// Comprehensive medical history for client safety and treatment planning
struct MedicalHistory: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let lastUpdated: Date

    // Health Conditions
    var healthConditions: [HealthCondition]
    var chronicConditions: [ChronicCondition]

    // Medical History
    var surgeries: [Surgery]
    var hospitalizations: [Hospitalization]
    var injuries: [InjuryHistory]

    // Medications & Supplements
    var medications: [Medication]
    var supplements: [Supplement]
    var allergies: [Allergy]

    // Family History
    var familyHistory: [FamilyMedicalHistory]

    // Women's Health
    var pregnancyStatus: PregnancyStatus?
    var nursingStatus: Bool

    // Devices & Implants
    var medicalDevices: [MedicalDevice]
    var implants: [Implant]

    // Lifestyle Factors
    var lifestyle: LifestyleFactors

    // Emergency Contacts
    var emergencyContact: EmergencyContact?
    var physicianInfo: PhysicianInfo?

    // Contraindications & Precautions
    var contraindications: [Contraindication]
    var precautions: [String]

    // Notes
    var additionalNotes: String

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        lastUpdated: Date = Date(),
        healthConditions: [HealthCondition] = [],
        chronicConditions: [ChronicCondition] = [],
        surgeries: [Surgery] = [],
        hospitalizations: [Hospitalization] = [],
        injuries: [InjuryHistory] = [],
        medications: [Medication] = [],
        supplements: [Supplement] = [],
        allergies: [Allergy] = [],
        familyHistory: [FamilyMedicalHistory] = [],
        pregnancyStatus: PregnancyStatus? = nil,
        nursingStatus: Bool = false,
        medicalDevices: [MedicalDevice] = [],
        implants: [Implant] = [],
        lifestyle: LifestyleFactors = LifestyleFactors(),
        emergencyContact: EmergencyContact? = nil,
        physicianInfo: PhysicianInfo? = nil,
        contraindications: [Contraindication] = [],
        precautions: [String] = [],
        additionalNotes: String = ""
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.lastUpdated = lastUpdated
        self.healthConditions = healthConditions
        self.chronicConditions = chronicConditions
        self.surgeries = surgeries
        self.hospitalizations = hospitalizations
        self.injuries = injuries
        self.medications = medications
        self.supplements = supplements
        self.allergies = allergies
        self.familyHistory = familyHistory
        self.pregnancyStatus = pregnancyStatus
        self.nursingStatus = nursingStatus
        self.medicalDevices = medicalDevices
        self.implants = implants
        self.lifestyle = lifestyle
        self.emergencyContact = emergencyContact
        self.physicianInfo = physicianInfo
        self.contraindications = contraindications
        self.precautions = precautions
        self.additionalNotes = additionalNotes
    }

    /// Check if there are any active contraindications
    var hasActiveContraindications: Bool {
        !contraindications.filter { $0.severity == .absolute || $0.severity == .relative }.isEmpty
    }

    /// Get high-priority health alerts
    var criticalAlerts: [String] {
        var alerts: [String] = []

        // Check for absolute contraindications
        let absoluteContra = contraindications.filter { $0.severity == .absolute }
        if !absoluteContra.isEmpty {
            alerts.append("CRITICAL: \(absoluteContra.count) absolute contraindications")
        }

        // Check for severe allergies
        let severeAllergies = allergies.filter { $0.severity == .severe }
        if !severeAllergies.isEmpty {
            alerts.append("WARNING: Severe allergies to \(severeAllergies.map { $0.allergen }.joined(separator: ", "))")
        }

        // Check pregnancy
        if let pregnancy = pregnancyStatus, pregnancy.isPregnant && pregnancy.trimester == 1 {
            alerts.append("CAUTION: First trimester pregnancy - special considerations required")
        }

        // Check for blood thinners
        let bloodThinners = medications.filter { med in
            ["warfarin", "aspirin", "heparin", "eliquis"].contains(where: { med.name.localizedCaseInsensitiveContains($0) })
        }
        if !bloodThinners.isEmpty {
            alerts.append("CAUTION: Client on blood thinners - avoid deep pressure")
        }

        return alerts
    }
}

// MARK: - Health Conditions

struct HealthCondition: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: ConditionCategory
    let diagnosedDate: Date?
    let isActive: Bool
    let severity: ConditionSeverity
    let notes: String

    init(
        id: UUID = UUID(),
        name: String,
        category: ConditionCategory,
        diagnosedDate: Date? = nil,
        isActive: Bool = true,
        severity: ConditionSeverity = .moderate,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.diagnosedDate = diagnosedDate
        self.isActive = isActive
        self.severity = severity
        self.notes = notes
    }
}

enum ConditionCategory: String, Codable, CaseIterable {
    case cardiovascular = "Cardiovascular"
    case respiratory = "Respiratory"
    case musculoskeletal = "Musculoskeletal"
    case neurological = "Neurological"
    case dermatological = "Dermatological"
    case gastrointestinal = "Gastrointestinal"
    case endocrine = "Endocrine"
    case autoimmune = "Autoimmune"
    case infectious = "Infectious"
    case psychiatric = "Psychiatric"
    case other = "Other"

    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .respiratory: return "lungs.fill"
        case .musculoskeletal: return "figure.walk"
        case .neurological: return "brain.head.profile"
        case .dermatological: return "hand.raised.fill"
        case .gastrointestinal: return "stomach"
        case .endocrine: return "drop.fill"
        case .autoimmune: return "shield.lefthalf.filled"
        case .infectious: return "cross.case.fill"
        case .psychiatric: return "brain"
        case .other: return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .cardiovascular: return .red
        case .respiratory: return .blue
        case .musculoskeletal: return .green
        case .neurological: return .purple
        case .dermatological: return .orange
        case .gastrointestinal: return .brown
        case .endocrine: return .cyan
        case .autoimmune: return .pink
        case .infectious: return .yellow
        case .psychiatric: return .indigo
        case .other: return .gray
        }
    }
}

enum ConditionSeverity: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct ChronicCondition: Identifiable, Codable {
    let id: UUID
    let condition: String
    let diagnosedDate: Date
    let managementPlan: String
    let affectsTreatment: Bool
    let notes: String

    init(
        id: UUID = UUID(),
        condition: String,
        diagnosedDate: Date,
        managementPlan: String = "",
        affectsTreatment: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.condition = condition
        self.diagnosedDate = diagnosedDate
        self.managementPlan = managementPlan
        self.affectsTreatment = affectsTreatment
        self.notes = notes
    }
}

// MARK: - Medical History

struct Surgery: Identifiable, Codable {
    let id: UUID
    let procedure: String
    let date: Date
    let surgeonName: String
    let complications: String
    let recoveryNotes: String
    let affectsTreatmentArea: Bool

    init(
        id: UUID = UUID(),
        procedure: String,
        date: Date,
        surgeonName: String = "",
        complications: String = "",
        recoveryNotes: String = "",
        affectsTreatmentArea: Bool = false
    ) {
        self.id = id
        self.procedure = procedure
        self.date = date
        self.surgeonName = surgeonName
        self.complications = complications
        self.recoveryNotes = recoveryNotes
        self.affectsTreatmentArea = affectsTreatmentArea
    }
}

struct Hospitalization: Identifiable, Codable {
    let id: UUID
    let reason: String
    let admissionDate: Date
    let dischargeDate: Date?
    let facility: String
    let notes: String

    init(
        id: UUID = UUID(),
        reason: String,
        admissionDate: Date,
        dischargeDate: Date? = nil,
        facility: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.reason = reason
        self.admissionDate = admissionDate
        self.dischargeDate = dischargeDate
        self.facility = facility
        self.notes = notes
    }
}

struct InjuryHistory: Identifiable, Codable {
    let id: UUID
    let injuryType: String
    let date: Date
    let location: String
    let treatment: String
    let isResolved: Bool
    let notes: String

    init(
        id: UUID = UUID(),
        injuryType: String,
        date: Date,
        location: String = "",
        treatment: String = "",
        isResolved: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.injuryType = injuryType
        self.date = date
        self.location = location
        self.treatment = treatment
        self.isResolved = isResolved
        self.notes = notes
    }
}

// MARK: - Medications & Allergies

struct Medication: Identifiable, Codable {
    let id: UUID
    let name: String
    let dosage: String
    let frequency: String
    let prescribedBy: String
    let startDate: Date
    let endDate: Date?
    let purpose: String
    let sideEffects: String
    let interactionsWithMassage: String

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        frequency: String,
        prescribedBy: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        purpose: String = "",
        sideEffects: String = "",
        interactionsWithMassage: String = ""
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.prescribedBy = prescribedBy
        self.startDate = startDate
        self.endDate = endDate
        self.purpose = purpose
        self.sideEffects = sideEffects
        self.interactionsWithMassage = interactionsWithMassage
    }
}

struct Supplement: Identifiable, Codable {
    let id: UUID
    let name: String
    let dosage: String
    let frequency: String
    let purpose: String

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        frequency: String,
        purpose: String = ""
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.purpose = purpose
    }
}

struct Allergy: Identifiable, Codable {
    let id: UUID
    let allergen: String
    let reaction: String
    let severity: AllergySeverity
    let diagnosedDate: Date?

    init(
        id: UUID = UUID(),
        allergen: String,
        reaction: String,
        severity: AllergySeverity = .moderate,
        diagnosedDate: Date? = nil
    ) {
        self.id = id
        self.allergen = allergen
        self.reaction = reaction
        self.severity = severity
        self.diagnosedDate = diagnosedDate
    }
}

enum AllergySeverity: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe (Anaphylaxis Risk)"

    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Family History

struct FamilyMedicalHistory: Identifiable, Codable {
    let id: UUID
    let relationship: String
    let condition: String
    let ageAtDiagnosis: Int?
    let isRelevantToClient: Bool

    init(
        id: UUID = UUID(),
        relationship: String,
        condition: String,
        ageAtDiagnosis: Int? = nil,
        isRelevantToClient: Bool = false
    ) {
        self.id = id
        self.relationship = relationship
        self.condition = condition
        self.ageAtDiagnosis = ageAtDiagnosis
        self.isRelevantToClient = isRelevantToClient
    }
}

// MARK: - Pregnancy & Women's Health

struct PregnancyStatus: Codable {
    let isPregnant: Bool
    let trimester: Int
    let dueDate: Date?
    let complications: String
    let obgynName: String
    let clearanceForMassage: Bool

    init(
        isPregnant: Bool,
        trimester: Int = 1,
        dueDate: Date? = nil,
        complications: String = "",
        obgynName: String = "",
        clearanceForMassage: Bool = false
    ) {
        self.isPregnant = isPregnant
        self.trimester = trimester
        self.dueDate = dueDate
        self.complications = complications
        self.obgynName = obgynName
        self.clearanceForMassage = clearanceForMassage
    }
}

// MARK: - Medical Devices & Implants

struct MedicalDevice: Identifiable, Codable {
    let id: UUID
    let deviceType: String
    let implantDate: Date?
    let restrictions: String

    init(
        id: UUID = UUID(),
        deviceType: String,
        implantDate: Date? = nil,
        restrictions: String = ""
    ) {
        self.id = id
        self.deviceType = deviceType
        self.implantDate = implantDate
        self.restrictions = restrictions
    }
}

struct Implant: Identifiable, Codable {
    let id: UUID
    let implantType: String
    let location: String
    let implantDate: Date
    let restrictions: String

    init(
        id: UUID = UUID(),
        implantType: String,
        location: String,
        implantDate: Date,
        restrictions: String = ""
    ) {
        self.id = id
        self.implantType = implantType
        self.location = location
        self.implantDate = implantDate
        self.restrictions = restrictions
    }
}

// MARK: - Lifestyle Factors

struct LifestyleFactors: Codable {
    var exerciseFrequency: ExerciseFrequency
    var sleepQuality: SleepQuality
    var stressLevel: Int // 1-10
    var alcoholConsumption: AlcoholConsumption
    var tobaccoUse: TobaccoUse
    var occupation: String
    var hobbies: String
    var dietaryNotes: String

    init(
        exerciseFrequency: ExerciseFrequency = .occasional,
        sleepQuality: SleepQuality = .fair,
        stressLevel: Int = 5,
        alcoholConsumption: AlcoholConsumption = .none,
        tobaccoUse: TobaccoUse = .none,
        occupation: String = "",
        hobbies: String = "",
        dietaryNotes: String = ""
    ) {
        self.exerciseFrequency = exerciseFrequency
        self.sleepQuality = sleepQuality
        self.stressLevel = stressLevel
        self.alcoholConsumption = alcoholConsumption
        self.tobaccoUse = tobaccoUse
        self.occupation = occupation
        self.hobbies = hobbies
        self.dietaryNotes = dietaryNotes
    }
}

enum ExerciseFrequency: String, Codable, CaseIterable {
    case none = "None"
    case occasional = "1-2x per week"
    case moderate = "3-4x per week"
    case frequent = "5+ per week"
}

enum SleepQuality: String, Codable, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
}

enum AlcoholConsumption: String, Codable, CaseIterable {
    case none = "None"
    case occasional = "Occasional"
    case moderate = "Moderate"
    case heavy = "Heavy"
}

enum TobaccoUse: String, Codable, CaseIterable {
    case none = "None"
    case former = "Former User"
    case current = "Current User"
}

// MARK: - Emergency & Physician Info

struct EmergencyContact: Codable {
    let name: String
    let relationship: String
    let phone: String
    let alternatePhone: String

    init(
        name: String,
        relationship: String,
        phone: String,
        alternatePhone: String = ""
    ) {
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.alternatePhone = alternatePhone
    }
}

struct PhysicianInfo: Codable {
    let name: String
    let specialty: String
    let phone: String
    let address: String
    let lastVisit: Date?

    init(
        name: String,
        specialty: String = "",
        phone: String,
        address: String = "",
        lastVisit: Date? = nil
    ) {
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.address = address
        self.lastVisit = lastVisit
    }
}

// MARK: - Contraindications

struct Contraindication: Identifiable, Codable {
    let id: UUID
    let condition: String
    let severity: ContraindicationSeverity
    let affectedAreas: [String]
    let precautions: String
    let dateIdentified: Date

    init(
        id: UUID = UUID(),
        condition: String,
        severity: ContraindicationSeverity,
        affectedAreas: [String] = [],
        precautions: String = "",
        dateIdentified: Date = Date()
    ) {
        self.id = id
        self.condition = condition
        self.severity = severity
        self.affectedAreas = affectedAreas
        self.precautions = precautions
        self.dateIdentified = dateIdentified
    }
}

enum ContraindicationSeverity: String, Codable {
    case absolute = "Absolute (No Massage)"
    case relative = "Relative (Modified Treatment)"
    case local = "Local (Avoid Specific Areas)"
    case caution = "Caution Required"

    var color: Color {
        switch self {
        case .absolute: return .red
        case .relative: return .orange
        case .local: return .yellow
        case .caution: return .blue
        }
    }
}

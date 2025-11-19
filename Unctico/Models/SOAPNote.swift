// SOAPNote.swift
// SOAP note model for clinical documentation
// SOAP = Subjective, Objective, Assessment, Plan

import Foundation

/// Represents a SOAP note for a massage therapy session
/// SOAP notes are the standard for clinical documentation
struct SOAPNote: Codable, Identifiable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Which client this note is for
    let clientId: UUID

    /// Date of the session
    var sessionDate: Date

    // MARK: - SOAP Components

    /// Subjective: What the client reports
    /// Examples: pain level, symptoms, concerns, goals
    var subjective: String

    /// Objective: What the therapist observes
    /// Examples: posture, range of motion, palpation findings, muscle tension
    var objective: String

    /// Assessment: Professional analysis
    /// Examples: diagnosis, progress evaluation, clinical reasoning
    var assessment: String

    /// Plan: Treatment plan and recommendations
    /// Examples: frequency, home care, referrals, next steps
    var plan: String

    // MARK: - Additional Details

    /// Duration of the session in minutes
    var sessionDuration: Int

    /// Techniques used during the session
    var techniquesUsed: [MassageTechnique]

    /// Areas of body worked on
    var areasWorked: [BodyArea]

    /// Pressure level used
    var pressureLevel: PressureLevel

    /// Modalities used (hot stones, cupping, etc.)
    var modalities: [Modality]

    /// Client's response to treatment
    var clientResponse: String?

    /// Any adverse reactions or concerns
    var adverseReactions: String?

    // MARK: - Metadata

    /// When this note was created
    let createdAt: Date

    /// When this note was last updated
    var updatedAt: Date

    /// Is this note finalized? (can't edit once finalized)
    var isFinalized: Bool

    // MARK: - Initialization

    /// Create a new SOAP note
    /// - Parameters:
    ///   - clientId: ID of the client
    ///   - sessionDate: Date of the session
    init(clientId: UUID, sessionDate: Date = Date()) {
        self.id = UUID()
        self.clientId = clientId
        self.sessionDate = sessionDate
        self.subjective = ""
        self.objective = ""
        self.assessment = ""
        self.plan = ""
        self.sessionDuration = 60
        self.techniquesUsed = []
        self.areasWorked = []
        self.pressureLevel = .medium
        self.modalities = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFinalized = false
    }

    // MARK: - Computed Properties

    /// Is this note complete? (all SOAP sections filled in)
    var isComplete: Bool {
        return !subjective.isEmpty &&
               !objective.isEmpty &&
               !assessment.isEmpty &&
               !plan.isEmpty
    }

    /// Word count for documentation compliance
    var wordCount: Int {
        let allText = "\(subjective) \(objective) \(assessment) \(plan)"
        return allText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - Supporting Enums

/// Massage techniques available
enum MassageTechnique: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case triggerPoint = "Trigger Point Therapy"
    case myofascialRelease = "Myofascial Release"
    case neuromuscular = "Neuromuscular Therapy"
    case lymphaticDrainage = "Lymphatic Drainage"
    case shiatsu = "Shiatsu"
    case thaiMassage = "Thai Massage"
    case prenatal = "Prenatal"
    case hotStone = "Hot Stone"
    case aromatherapy = "Aromatherapy"
}

/// Body areas that can be worked on
enum BodyArea: String, Codable, CaseIterable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case arms = "Arms"
    case hands = "Hands"
    case legs = "Legs"
    case feet = "Feet"
    case hips = "Hips"
    case chest = "Chest"
    case abdomen = "Abdomen"
    case face = "Face"
    case scalp = "Scalp"
}

/// Pressure levels for massage
enum PressureLevel: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case firm = "Firm"
    case deep = "Deep"

    /// Numeric value for tracking (1-4)
    var numericValue: Int {
        switch self {
        case .light: return 1
        case .medium: return 2
        case .firm: return 3
        case .deep: return 4
        }
    }
}

/// Modalities (additional tools/techniques)
enum Modality: String, Codable, CaseIterable {
    case hotStones = "Hot Stones"
    case coldStones = "Cold Stones"
    case cupping = "Cupping"
    case gua = "Gua Sha"
    case essentialOils = "Essential Oils"
    case heatTherapy = "Heat Therapy"
    case coldTherapy = "Cold Therapy"
    case kinesioTape = "Kinesio Tape"
    case bamboo = "Bamboo Tools"
    case percussion = "Percussion Therapy"
}

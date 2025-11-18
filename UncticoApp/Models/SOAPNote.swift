// SOAPNote.swift
// SOAP Notes (Subjective, Objective, Assessment, Plan) model
// QA Note: This is the clinical documentation for each session

import Foundation

/// SOAP Note - Clinical documentation for massage session
/// SOAP = Subjective, Objective, Assessment, Plan
struct SOAPNote: Identifiable, Codable {

    // MARK: - Basic Information

    let id: UUID
    var clientId: UUID
    var sessionId: UUID
    var createdDate: Date
    var lastModifiedDate: Date
    var therapistId: UUID

    // MARK: - SOAP Components

    var subjective: Subjective
    var objective: Objective
    var assessment: Assessment
    var plan: Plan

    // MARK: - Session Details

    var sessionDuration: Int  // in minutes
    var techniques: [TechniqueUsed]

    init(
        id: UUID = UUID(),
        clientId: UUID,
        sessionId: UUID,
        therapistId: UUID
    ) {
        self.id = id
        self.clientId = clientId
        self.sessionId = sessionId
        self.therapistId = therapistId
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.sessionDuration = 60
        self.techniques = []
        self.subjective = Subjective()
        self.objective = Objective()
        self.assessment = Assessment()
        self.plan = Plan()
    }
}

// MARK: - Subjective (What the client tells you)

/// Subjective information - What client reports
struct Subjective: Codable {

    var chiefComplaint: String  // Main reason for visit
    var painLevel: Int  // 0-10 scale
    var painLocations: [BodyLocation]
    var symptomDuration: String
    var previousTreatments: String
    var medications: String
    var sleepQuality: SleepQuality
    var stressLevel: Int  // 0-10 scale
    var activities: String  // Recent activities
    var goals: String  // Client's goals for session
    var voiceNotes: String  // Transcribed voice notes

    init() {
        self.chiefComplaint = ""
        self.painLevel = 0
        self.painLocations = []
        self.symptomDuration = ""
        self.previousTreatments = ""
        self.medications = ""
        self.sleepQuality = .normal
        self.stressLevel = 0
        self.activities = ""
        self.goals = ""
        self.voiceNotes = ""
    }
}

/// Location on the body
struct BodyLocation: Identifiable, Codable {
    let id: UUID
    var area: BodyArea
    var side: BodySide
    var description: String

    init(id: UUID = UUID(), area: BodyArea, side: BodySide, description: String = "") {
        self.id = id
        self.area = area
        self.side = side
        self.description = description
    }
}

/// Areas of the body
enum BodyArea: String, Codable, CaseIterable {
    case neck = "Neck"
    case shoulders = "Shoulders"
    case upperBack = "Upper Back"
    case midBack = "Mid Back"
    case lowerBack = "Lower Back"
    case arms = "Arms"
    case hands = "Hands"
    case hips = "Hips"
    case legs = "Legs"
    case feet = "Feet"
    case chest = "Chest"
    case abdomen = "Abdomen"
}

/// Which side of the body
enum BodySide: String, Codable {
    case left = "Left"
    case right = "Right"
    case both = "Both"
    case center = "Center"
}

/// Sleep quality rating
enum SleepQuality: String, Codable, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case normal = "Normal"
    case good = "Good"
    case excellent = "Excellent"
}

// MARK: - Objective (What you observe and measure)

/// Objective findings - What therapist observes
struct Objective: Codable {

    var posture: String
    var rangeOfMotion: [RangeOfMotionTest]
    var muscleTension: [MuscleTension]
    var triggerPoints: [TriggerPoint]
    var tissueTex ture: String
    var observations: String
    var photos: [String]  // Photo file paths

    init() {
        self.posture = ""
        self.rangeOfMotion = []
        self.muscleTension = []
        self.triggerPoints = []
        self.tissueTexture = ""
        self.observations = ""
        self.photos = []
    }
}

/// Range of motion test result
struct RangeOfMotionTest: Identifiable, Codable {
    let id: UUID
    var joint: String
    var movement: String
    var limitation: MovementLimitation

    init(id: UUID = UUID(), joint: String, movement: String, limitation: MovementLimitation) {
        self.id = id
        self.joint = joint
        self.movement = movement
        self.limitation = limitation
    }
}

/// How limited is movement
enum MovementLimitation: String, Codable, CaseIterable {
    case normal = "Normal"
    case mild = "Mild Limitation"
    case moderate = "Moderate Limitation"
    case severe = "Severe Limitation"
}

/// Muscle tension finding
struct MuscleTension: Identifiable, Codable {
    let id: UUID
    var muscle: String
    var location: BodyLocation
    var grade: TensionGrade  // 1-5 scale

    init(id: UUID = UUID(), muscle: String, location: BodyLocation, grade: TensionGrade) {
        self.id = id
        self.muscle = muscle
        self.location = location
        self.grade = grade
    }
}

/// Tension severity (1-5 scale)
enum TensionGrade: Int, Codable, CaseIterable {
    case normal = 1
    case mild = 2
    case moderate = 3
    case firm = 4
    case severe = 5
}

/// Trigger point location
struct TriggerPoint: Identifiable, Codable {
    let id: UUID
    var muscle: String
    var location: BodyLocation
    var referralPattern: String  // Where pain refers to

    init(id: UUID = UUID(), muscle: String, location: BodyLocation, referralPattern: String = "") {
        self.id = id
        self.muscle = muscle
        self.location = location
        self.referralPattern = referralPattern
    }
}

// MARK: - Assessment (Your professional judgment)

/// Assessment - Clinical reasoning and diagnosis
struct Assessment: Codable {

    var diagnosis: String
    var icdCodes: [String]  // ICD-10 codes
    var contraindications: [String]
    var progress: ProgressLevel
    var functionalImprovement: String
    var clinicalReasoning: String
    var redFlags: [String]  // Warning signs

    init() {
        self.diagnosis = ""
        self.icdCodes = []
        self.contraindications = []
        self.progress = .noChange
        self.functionalImprovement = ""
        self.clinicalReasoning = ""
        self.redFlags = []
    }
}

/// How much progress client has made
enum ProgressLevel: String, Codable, CaseIterable {
    case worsened = "Condition Worsened"
    case noChange = "No Change"
    case slightImprovement = "Slight Improvement"
    case goodImprovement = "Good Improvement"
    case significantImprovement = "Significant Improvement"
    case resolved = "Fully Resolved"
}

// MARK: - Plan (Treatment plan and next steps)

/// Plan - Treatment plan and recommendations
struct Plan: Codable {

    var treatmentPlan: String
    var frequency: String  // How often to return
    var homecare: [HomeCareInstruction]
    var referrals: [Referral]
    var followUpDate: Date?
    var goals: String
    var modifications: String  // Any treatment modifications needed

    init() {
        self.treatmentPlan = ""
        self.frequency = ""
        self.homecare = []
        self.referrals = []
        self.goals = ""
        self.modifications = ""
    }
}

/// Home care instructions for client
struct HomeCareInstruction: Identifiable, Codable {
    let id: UUID
    var type: HomeCareType
    var description: String
    var frequency: String
    var duration: String

    init(id: UUID = UUID(), type: HomeCareType, description: String, frequency: String, duration: String) {
        self.id = id
        self.type = type
        self.description = description
        self.frequency = frequency
        self.duration = duration
    }
}

/// Type of home care
enum HomeCareType: String, Codable, CaseIterable {
    case stretching = "Stretching"
    case icing = "Ice Application"
    case heating = "Heat Application"
    case rest = "Rest"
    case exercise = "Exercise"
    case selfMassage = "Self-Massage"
    case hydration = "Hydration"
    case posture = "Posture Correction"
}

/// Referral to another provider
struct Referral: Identifiable, Codable {
    let id: UUID
    var providerType: String
    var reason: String
    var urgent: Bool

    init(id: UUID = UUID(), providerType: String, reason: String, urgent: Bool = false) {
        self.id = id
        self.providerType = providerType
        self.reason = reason
        self.urgent = urgent
    }
}

// MARK: - Techniques Used

/// Massage technique used in session
struct TechniqueUsed: Identifiable, Codable {
    let id: UUID
    var technique: MassageTechnique
    var duration: Int  // minutes
    var areas: [BodyArea]
    var pressure: PressureLevel

    init(id: UUID = UUID(), technique: MassageTechnique, duration: Int, areas: [BodyArea], pressure: PressureLevel) {
        self.id = id
        self.technique = technique
        self.duration = duration
        self.areas = areas
        self.pressure = pressure
    }
}

/// Types of massage techniques
enum MassageTechnique: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case trigger = "Trigger Point Therapy"
    case myofascial = "Myofascial Release"
    case stretching = "Stretching"
    case hotStone = "Hot Stone"
    case cupping = "Cupping"
    case prenatal = "Prenatal"
    case aromatherapy = "Aromatherapy"
}

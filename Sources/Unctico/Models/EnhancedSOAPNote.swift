import Foundation
import SwiftUI

/// Enhanced SOAP note extensions with body diagrams and advanced assessment tools
extension SOAPNote {
    /// Get completion percentage
    var completionPercentage: Double {
        var completed = 0
        var total = 8

        if !subjective.chiefComplaint.isEmpty { completed += 1 }
        if subjective.painLevel > 0 { completed += 1 }
        if !objective.areasWorked.isEmpty { completed += 1 }
        if !objective.muscleTension.isEmpty { completed += 1 }
        if !assessment.diagnosis.isEmpty { completed += 1 }
        if !assessment.progressNotes.isEmpty { completed += 1 }
        if !plan.treatmentFrequency.isEmpty { completed += 1 }
        if !plan.homeCareInstructions.isEmpty { completed += 1 }

        return Double(completed) / Double(total) * 100
    }

    /// Check if note is complete
    var isComplete: Bool {
        completionPercentage >= 75
    }
}

/// Body diagram annotation for visual pain/treatment tracking
struct BodyDiagramAnnotation: Identifiable, Codable {
    let id: UUID
    let point: CGPoint // Relative position on body diagram (0-1)
    let annotationType: AnnotationType
    let severity: Int // 1-10
    let notes: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        point: CGPoint,
        annotationType: AnnotationType,
        severity: Int = 5,
        notes: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.point = point
        self.annotationType = annotationType
        self.severity = severity
        self.notes = notes
        self.timestamp = timestamp
    }

    enum AnnotationType: String, Codable, CaseIterable {
        case pain = "Pain"
        case tension = "Muscle Tension"
        case triggerPoint = "Trigger Point"
        case restriction = "Movement Restriction"
        case inflammation = "Inflammation"
        case scar = "Scar Tissue"
        case adhesion = "Adhesion"
        case workArea = "Area Worked"

        var color: Color {
            switch self {
            case .pain: return .red
            case .tension: return .orange
            case .triggerPoint: return .purple
            case .restriction: return .yellow
            case .inflammation: return .pink
            case .scar: return .brown
            case .adhesion: return .gray
            case .workArea: return .green
            }
        }

        var icon: String {
            switch self {
            case .pain: return "bolt.fill"
            case .tension: return "flame.fill"
            case .triggerPoint: return "circle.fill"
            case .restriction: return "lock.fill"
            case .inflammation: return "flame.circle.fill"
            case .scar: return "bandage.fill"
            case .adhesion: return "link.circle.fill"
            case .workArea: return "hand.raised.fill"
            }
        }
    }
}

/// Session-specific treatment tracking
struct TreatmentSession: Identifiable, Codable {
    let id: UUID
    let soapNoteId: UUID
    let sessionDate: Date
    let duration: TimeInterval // in seconds
    let techniques: [TechniqueUsed]
    let modalities: [ModalityUsed]
    let pressureLevels: [PressureLevel]
    let clientPosition: ClientPosition
    let areaSpecificTime: [BodyLocation: TimeInterval]
    let clientFeedback: String
    let therapistObservations: String

    init(
        id: UUID = UUID(),
        soapNoteId: UUID,
        sessionDate: Date = Date(),
        duration: TimeInterval,
        techniques: [TechniqueUsed] = [],
        modalities: [ModalityUsed] = [],
        pressureLevels: [PressureLevel] = [],
        clientPosition: ClientPosition = .prone,
        areaSpecificTime: [BodyLocation: TimeInterval] = [:],
        clientFeedback: String = "",
        therapistObservations: String = ""
    ) {
        self.id = id
        self.soapNoteId = soapNoteId
        self.sessionDate = sessionDate
        self.duration = duration
        self.techniques = techniques
        self.modalities = modalities
        self.pressureLevels = pressureLevels
        self.clientPosition = clientPosition
        self.areaSpecificTime = areaSpecificTime
        self.clientFeedback = clientFeedback
        self.therapistObservations = therapistObservations
    }
}

struct TechniqueUsed: Identifiable, Codable {
    let id: UUID
    let technique: MassageTechnique
    let duration: TimeInterval
    let areas: [BodyLocation]

    init(id: UUID = UUID(), technique: MassageTechnique, duration: TimeInterval, areas: [BodyLocation] = []) {
        self.id = id
        self.technique = technique
        self.duration = duration
        self.areas = areas
    }
}

enum MassageTechnique: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case myofascial = "Myofascial Release"
    case triggerPoint = "Trigger Point Therapy"
    case neuromuscular = "Neuromuscular"
    case lymphatic = "Lymphatic Drainage"
    case prenatal = "Prenatal"
    case hotStone = "Hot Stone"
    case shiatsu = "Shiatsu"
    case thai = "Thai Massage"
    case reflexology = "Reflexology"
    case aromatherapy = "Aromatherapy"
    case cupping = "Cupping"
    case gua = "Gua Sha"

    var icon: String {
        switch self {
        case .swedish: return "hand.raised.fill"
        case .deepTissue: return "hand.point.down.fill"
        case .sports: return "sportscourt.fill"
        case .myofascial: return "waveform.path"
        case .triggerPoint: return "circle.fill"
        case .neuromuscular: return "brain"
        case .lymphatic: return "drop.fill"
        case .prenatal: return "figure.walk"
        case .hotStone: return "flame.fill"
        case .shiatsu: return "hand.tap.fill"
        case .thai: return "figure.flexibility"
        case .reflexology: return "footprints"
        case .aromatherapy: return "sparkles"
        case .cupping: return "circle.circle.fill"
        case .gua: return "waveform"
        }
    }
}

struct ModalityUsed: Identifiable, Codable {
    let id: UUID
    let modality: Modality
    let duration: TimeInterval
    let notes: String

    init(id: UUID = UUID(), modality: Modality, duration: TimeInterval, notes: String = "") {
        self.id = id
        self.modality = modality
        self.duration = duration
        self.notes = notes
    }
}

enum Modality: String, Codable, CaseIterable {
    case heat = "Heat Therapy"
    case ice = "Ice/Cold Therapy"
    case hotStones = "Hot Stones"
    case coldStones = "Cold Stones"
    case essentialOils = "Essential Oils"
    case cbd = "CBD Products"
    case cupping = "Cupping"
    case guaSha = "Gua Sha"
    case kinesioTape = "Kinesiology Tape"
    case tens = "TENS Unit"
    case ultrasound = "Ultrasound"
    case infrared = "Infrared Therapy"

    var icon: String {
        switch self {
        case .heat: return "flame.fill"
        case .ice: return "snowflake"
        case .hotStones: return "circle.fill"
        case .coldStones: return "circle"
        case .essentialOils: return "drop.fill"
        case .cbd: return "leaf.fill"
        case .cupping: return "circle.circle.fill"
        case .guaSha: return "waveform"
        case .kinesioTape: return "bandage.fill"
        case .tens: return "bolt.fill"
        case .ultrasound: return "waveform.path"
        case .infrared: return "light.beacon.max.fill"
        }
    }
}

struct PressureLevel: Identifiable, Codable {
    let id: UUID
    let area: BodyLocation
    let pressure: Int // 1-5 scale

    init(id: UUID = UUID(), area: BodyLocation, pressure: Int) {
        self.id = id
        self.area = area
        self.pressure = pressure
    }

    var pressureDescription: String {
        switch pressure {
        case 1: return "Very Light"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Firm"
        case 5: return "Deep"
        default: return "Moderate"
        }
    }
}

enum ClientPosition: String, Codable, CaseIterable {
    case prone = "Prone (Face Down)"
    case supine = "Supine (Face Up)"
    case sideLeft = "Side-Lying (Left)"
    case sideRight = "Side-Lying (Right)"
    case seated = "Seated"
    case semiReclined = "Semi-Reclined"

    var icon: String {
        switch self {
        case .prone: return "figure.walk.arrival"
        case .supine: return "figure.walk"
        case .sideLeft, .sideRight: return "figure.walk.motion"
        case .seated: return "figure.seated.side"
        case .semiReclined: return "figure.cooldown"
        }
    }
}

/// Pain assessment tools
struct PainAssessment: Codable {
    var painScale: Int // 0-10
    var painQuality: [PainQuality]
    var painPattern: PainPattern
    var onsetDate: Date?
    var aggravatingFactors: [String]
    var relievingFactors: [String]
    var timeOfDay: [TimeOfDay]

    init(
        painScale: Int = 0,
        painQuality: [PainQuality] = [],
        painPattern: PainPattern = .constant,
        onsetDate: Date? = nil,
        aggravatingFactors: [String] = [],
        relievingFactors: [String] = [],
        timeOfDay: [TimeOfDay] = []
    ) {
        self.painScale = painScale
        self.painQuality = painQuality
        self.painPattern = painPattern
        self.onsetDate = onsetDate
        self.aggravatingFactors = aggravatingFactors
        self.relievingFactors = relievingFactors
        self.timeOfDay = timeOfDay
    }
}

enum PainQuality: String, Codable, CaseIterable {
    case sharp = "Sharp"
    case dull = "Dull"
    case aching = "Aching"
    case burning = "Burning"
    case tingling = "Tingling"
    case numbness = "Numbness"
    case radiating = "Radiating"
    case throbbing = "Throbbing"
    case shooting = "Shooting"
    case stabbing = "Stabbing"
}

enum PainPattern: String, Codable, CaseIterable {
    case constant = "Constant"
    case intermittent = "Intermittent"
    case worsening = "Progressive/Worsening"
    case improving = "Improving"
    case variable = "Variable"
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
    case allDay = "All Day"
}

/// Postural assessment
struct PosturalAssessment: Codable {
    var headPosition: HeadPosition
    var shoulderLevel: ShoulderLevel
    var spinalCurvature: SpinalCurvature
    var hipLevel: HipLevel
    var footPosition: FootPosition
    var overallPosture: String
    var notes: String

    init(
        headPosition: HeadPosition = .neutral,
        shoulderLevel: ShoulderLevel = .level,
        spinalCurvature: SpinalCurvature = .normal,
        hipLevel: HipLevel = .level,
        footPosition: FootPosition = .neutral,
        overallPosture: String = "",
        notes: String = ""
    ) {
        self.headPosition = headPosition
        self.shoulderLevel = shoulderLevel
        self.spinalCurvature = spinalCurvature
        self.hipLevel = hipLevel
        self.footPosition = footPosition
        self.overallPosture = overallPosture
        self.notes = notes
    }
}

enum HeadPosition: String, Codable, CaseIterable {
    case neutral = "Neutral"
    case forwardHead = "Forward Head"
    case leftTilt = "Left Tilt"
    case rightTilt = "Right Tilt"
    case leftRotation = "Left Rotation"
    case rightRotation = "Right Rotation"
}

enum ShoulderLevel: String, Codable, CaseIterable {
    case level = "Level"
    case leftHigh = "Left Higher"
    case rightHigh = "Right Higher"
    case rounded = "Rounded Forward"
    case retracted = "Retracted"
}

enum SpinalCurvature: String, Codable, CaseIterable {
    case normal = "Normal"
    case hyperlordosis = "Hyperlordosis (Excessive Curve)"
    case hyperkyphosis = "Hyperkyphosis (Rounded Upper Back)"
    case scoliosis = "Scoliosis (Lateral Curve)"
    case flatBack = "Flat Back"
}

enum HipLevel: String, Codable, CaseIterable {
    case level = "Level"
    case leftHigh = "Left Higher"
    case rightHigh = "Right Higher"
    case anteriorTilt = "Anterior Tilt"
    case posteriorTilt = "Posterior Tilt"
}

enum FootPosition: String, Codable, CaseIterable {
    case neutral = "Neutral"
    case pronated = "Pronated (Flat Feet)"
    case supinated = "Supinated (High Arch)"
    case toedIn = "Toed In"
    case toedOut = "Toed Out"
}

/// Range of motion detailed assessment
struct DetailedROMAssessment: Identifiable, Codable {
    let id: UUID
    let joint: Joint
    let movement: Movement
    let degrees: Int
    let painDuring: Bool
    let endFeel: EndFeel
    let limitations: String
    let comparedToNormal: String

    init(
        id: UUID = UUID(),
        joint: Joint,
        movement: Movement,
        degrees: Int,
        painDuring: Bool = false,
        endFeel: EndFeel = .normal,
        limitations: String = "",
        comparedToNormal: String = ""
    ) {
        self.id = id
        self.joint = joint
        self.movement = movement
        self.degrees = degrees
        self.painDuring = painDuring
        self.endFeel = endFeel
        self.limitations = limitations
        self.comparedToNormal = comparedToNormal
    }
}

enum Joint: String, Codable, CaseIterable {
    case neck = "Neck/Cervical"
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case wrist = "Wrist"
    case lumbar = "Lumbar Spine"
    case hip = "Hip"
    case knee = "Knee"
    case ankle = "Ankle"
}

enum Movement: String, Codable {
    case flexion = "Flexion"
    case extension = "Extension"
    case abduction = "Abduction"
    case adduction = "Adduction"
    case rotation = "Rotation"
    case lateralFlexion = "Lateral Flexion"
}

enum EndFeel: String, Codable {
    case normal = "Normal/Soft"
    case firm = "Firm"
    case hard = "Hard/Bony"
    case springy = "Springy"
    case empty = "Empty (Pain Stops)"
}

/// Functional outcome measures
struct FunctionalOutcome: Codable {
    var activitiesOfDailyLiving: [ADLRating]
    var workCapacity: WorkCapacityRating
    var sleepQuality: Int // 1-10
    var overallWellbeing: Int // 1-10
    var goalProgress: [GoalProgress]

    init(
        activitiesOfDailyLiving: [ADLRating] = [],
        workCapacity: WorkCapacityRating = .fullDuty,
        sleepQuality: Int = 5,
        overallWellbeing: Int = 5,
        goalProgress: [GoalProgress] = []
    ) {
        self.activitiesOfDailyLiving = activitiesOfDailyLiving
        self.workCapacity = workCapacity
        self.sleepQuality = sleepQuality
        self.overallWellbeing = overallWellbeing
        self.goalProgress = goalProgress
    }
}

struct ADLRating: Identifiable, Codable {
    let id: UUID
    let activity: String
    let difficulty: DifficultyLevel

    init(id: UUID = UUID(), activity: String, difficulty: DifficultyLevel) {
        self.id = id
        self.activity = activity
        self.difficulty = difficulty
    }

    enum DifficultyLevel: String, Codable {
        case noDifficulty = "No Difficulty"
        case mild = "Mild Difficulty"
        case moderate = "Moderate Difficulty"
        case severe = "Severe Difficulty"
        case unable = "Unable to Perform"
    }
}

enum WorkCapacityRating: String, Codable {
    case fullDuty = "Full Duty"
    case lightDuty = "Light Duty"
    case modified = "Modified Duty"
    case unableToWork = "Unable to Work"
}

struct GoalProgress: Identifiable, Codable {
    let id: UUID
    let goal: String
    let targetDate: Date?
    let progress: Int // 0-100%
    let notes: String

    init(id: UUID = UUID(), goal: String, targetDate: Date? = nil, progress: Int = 0, notes: String = "") {
        self.id = id
        self.goal = goal
        self.targetDate = targetDate
        self.progress = progress
        self.notes = notes
    }
}

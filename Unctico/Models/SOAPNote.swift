import Foundation

struct SOAPNote: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let sessionId: UUID
    var date: Date

    var subjective: Subjective
    var objective: Objective
    var assessment: Assessment
    var plan: Plan

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        clientId: UUID,
        sessionId: UUID,
        date: Date = Date(),
        subjective: Subjective = Subjective(),
        objective: Objective = Objective(),
        assessment: Assessment = Assessment(),
        plan: Plan = Plan(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.sessionId = sessionId
        self.date = date
        self.subjective = subjective
        self.objective = objective
        self.assessment = assessment
        self.plan = plan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Subjective
struct Subjective: Codable {
    var chiefComplaint: String = ""
    var painLevel: Int = 0
    var symptomDuration: String = ""
    var symptomLocations: [BodyLocation] = []
    var activities: String = ""
    var sleepQuality: SleepQuality = .fair
    var stressLevel: Int = 5
    var medications: [String] = []
    var patientGoals: String = ""
    var voiceNotes: String = ""

    enum SleepQuality: String, Codable, CaseIterable {
        case poor = "Poor"
        case fair = "Fair"
        case good = "Good"
        case excellent = "Excellent"
    }
}

// MARK: - Objective
struct Objective: Codable {
    var areasWorked: [BodyLocation] = []
    var muscleTension: [MuscleTensionReading] = []
    var rangeOfMotion: [ROMAssessment] = []
    var postureFindings: String = ""
    var triggerPoints: [TriggerPoint] = []
    var tissueTexture: String = ""
    var palpationFindings: String = ""

    struct MuscleTensionReading: Codable, Identifiable {
        let id: UUID
        var location: BodyLocation
        var tensionLevel: Int

        init(id: UUID = UUID(), location: BodyLocation, tensionLevel: Int) {
            self.id = id
            self.location = location
            self.tensionLevel = tensionLevel
        }
    }

    struct ROMAssessment: Codable, Identifiable {
        let id: UUID
        var joint: String
        var measurement: String
        var limitations: String?

        init(id: UUID = UUID(), joint: String, measurement: String, limitations: String? = nil) {
            self.id = id
            self.joint = joint
            self.measurement = measurement
            self.limitations = limitations
        }
    }

    struct TriggerPoint: Codable, Identifiable {
        let id: UUID
        var location: BodyLocation
        var severity: Int
        var referralPattern: String?

        init(id: UUID = UUID(), location: BodyLocation, severity: Int, referralPattern: String? = nil) {
            self.id = id
            self.location = location
            self.severity = severity
            self.referralPattern = referralPattern
        }
    }
}

// MARK: - Assessment
struct Assessment: Codable {
    var diagnosis: [String] = []
    var icdCodes: [String] = []
    var progressNotes: String = ""
    var contraindications: [String] = []
    var clinicalReasoning: String = ""
    var treatmentResponse: TreatmentResponse = .improving

    enum TreatmentResponse: String, Codable, CaseIterable {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Declining"
        case resolved = "Resolved"
    }
}

// MARK: - Plan
struct Plan: Codable {
    var treatmentFrequency: String = ""
    var homeCareInstructions: [String] = []
    var recommendedExercises: [Exercise] = []
    var productRecommendations: [String] = []
    var followUpDate: Date?
    var referrals: [String] = []
    var nextSessionFocus: String = ""

    struct Exercise: Codable, Identifiable {
        let id: UUID
        var name: String
        var description: String
        var frequency: String
        var videoUrl: String?

        init(id: UUID = UUID(), name: String, description: String, frequency: String, videoUrl: String? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.frequency = frequency
            self.videoUrl = videoUrl
        }
    }
}

// MARK: - Supporting Types
struct BodyLocation: Codable, Hashable {
    var region: BodyRegion
    var side: BodySide
    var specificArea: String?

    enum BodyRegion: String, Codable, CaseIterable {
        case neck = "Neck"
        case upperBack = "Upper Back"
        case lowerBack = "Lower Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case hands = "Hands"
        case chest = "Chest"
        case hips = "Hips"
        case legs = "Legs"
        case feet = "Feet"
    }

    enum BodySide: String, Codable, CaseIterable {
        case left = "Left"
        case right = "Right"
        case bilateral = "Bilateral"
        case central = "Central"
    }

    var displayName: String {
        let base = "\(side.rawValue) \(region.rawValue)"
        if let specific = specificArea {
            return "\(base) - \(specific)"
        }
        return base
    }
}

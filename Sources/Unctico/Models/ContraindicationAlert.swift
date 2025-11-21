import Foundation
import SwiftUI

/// Contraindication alert system for client safety
/// Identifies conditions that may require modified treatment or referral
struct ContraindicationAlert: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let condition: ContraindicationCondition
    let severity: Severity
    let detectedDate: Date
    let notes: String
    let actionTaken: String?
    let isResolved: Bool
    let resolvedDate: Date?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        condition: ContraindicationCondition,
        severity: Severity,
        detectedDate: Date = Date(),
        notes: String = "",
        actionTaken: String? = nil,
        isResolved: Bool = false,
        resolvedDate: Date? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.condition = condition
        self.severity = severity
        self.detectedDate = detectedDate
        self.notes = notes
        self.actionTaken = actionTaken
        self.isResolved = isResolved
        self.resolvedDate = resolvedDate
    }

    enum Severity: String, Codable, CaseIterable {
        case absolute = "Absolute Contraindication"
        case local = "Local Contraindication"
        case caution = "Requires Caution"
        case modified = "Modified Treatment"

        var color: Color {
            switch self {
            case .absolute: return .red
            case .local: return .orange
            case .caution: return .yellow
            case .modified: return .blue
            }
        }

        var icon: String {
            switch self {
            case .absolute: return "exclamationmark.triangle.fill"
            case .local: return "exclamationmark.circle.fill"
            case .caution: return "exclamationmark.shield.fill"
            case .modified: return "info.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .absolute: return "Do not proceed with massage therapy"
            case .local: return "Avoid specific area, may treat elsewhere"
            case .caution: return "Proceed with care and modified approach"
            case .modified: return "Adjust techniques and pressure accordingly"
            }
        }
    }

    enum ContraindicationCondition: String, Codable, CaseIterable {
        // Absolute Contraindications
        case fever = "Fever"
        case activeInfection = "Active Infection"
        case openWounds = "Open Wounds"
        case severeOsteoporosis = "Severe Osteoporosis"
        case dvt = "Deep Vein Thrombosis (DVT)"
        case recentSurgery = "Recent Surgery"
        case severeHypertension = "Severe Uncontrolled Hypertension"
        case activeInflammation = "Acute Inflammation"
        case contagiousSkinCondition = "Contagious Skin Condition"
        case hemophilia = "Hemophilia"

        // Local Contraindications
        case bruising = "Bruising/Hematoma"
        case varicoseVeins = "Varicose Veins"
        case skinRash = "Skin Rash"
        case recentInjury = "Recent Injury"
        case bursitis = "Bursitis"
        case tendinitis = "Acute Tendinitis"
        case fracture = "Recent Fracture"
        case burns = "Burns"

        // Caution Required
        case pregnancy = "Pregnancy"
        case cancer = "Cancer/Tumors"
        case heartCondition = "Heart Condition"
        case diabetes = "Diabetes"
        case epilepsy = "Epilepsy"
        case autoimmune = "Autoimmune Disorder"
        case bloodThinners = "Blood Thinning Medication"
        case nerveDamage = "Nerve Damage"
        case chronicPain = "Chronic Pain Syndrome"
        case asthma = "Asthma"

        // Modified Treatment
        case arthritis = "Arthritis"
        case fibromyalgia = "Fibromyalgia"
        case migraines = "Chronic Migraines"
        case anxiety = "Anxiety/Panic Disorder"
        case depression = "Depression"
        case highBloodPressure = "Controlled High Blood Pressure"
        case previousMassageReaction = "Previous Adverse Reaction to Massage"

        var category: String {
            switch self {
            case .fever, .activeInfection, .openWounds, .severeOsteoporosis, .dvt,
                 .recentSurgery, .severeHypertension, .activeInflammation,
                 .contagiousSkinCondition, .hemophilia:
                return "Absolute Contraindication"

            case .bruising, .varicoseVeins, .skinRash, .recentInjury, .bursitis,
                 .tendinitis, .fracture, .burns:
                return "Local Contraindication"

            case .pregnancy, .cancer, .heartCondition, .diabetes, .epilepsy,
                 .autoimmune, .bloodThinners, .nerveDamage, .chronicPain, .asthma:
                return "Requires Caution"

            case .arthritis, .fibromyalgia, .migraines, .anxiety, .depression,
                 .highBloodPressure, .previousMassageReaction:
                return "Modified Treatment"
            }
        }

        var defaultSeverity: Severity {
            switch self {
            case .fever, .activeInfection, .openWounds, .severeOsteoporosis, .dvt,
                 .recentSurgery, .severeHypertension, .activeInflammation,
                 .contagiousSkinCondition, .hemophilia:
                return .absolute

            case .bruising, .varicoseVeins, .skinRash, .recentInjury, .bursitis,
                 .tendinitis, .fracture, .burns:
                return .local

            case .pregnancy, .cancer, .heartCondition, .diabetes, .epilepsy,
                 .autoimmune, .bloodThinners, .nerveDamage, .chronicPain, .asthma:
                return .caution

            case .arthritis, .fibromyalgia, .migraines, .anxiety, .depression,
                 .highBloodPressure, .previousMassageReaction:
                return .modified
            }
        }

        var recommendations: [String] {
            switch self {
            case .fever:
                return [
                    "Do not proceed with massage",
                    "Reschedule after fever subsides",
                    "Client should rest and recover"
                ]
            case .activeInfection:
                return [
                    "Do not proceed with massage",
                    "Risk of spreading infection",
                    "Reschedule after infection clears"
                ]
            case .dvt:
                return [
                    "Absolutely no massage",
                    "Risk of blood clot dislodgement",
                    "Refer to physician immediately"
                ]
            case .pregnancy:
                return [
                    "Use prenatal positioning (side-lying)",
                    "Avoid deep abdominal work",
                    "Modify pressure as needed",
                    "Get physician clearance for high-risk pregnancies"
                ]
            case .cancer:
                return [
                    "Obtain physician clearance before massage",
                    "Avoid tumor sites",
                    "Use light to moderate pressure only",
                    "Be aware of treatment side effects (chemo, radiation)"
                ]
            case .diabetes:
                return [
                    "Check blood sugar before session",
                    "Have client eat beforehand",
                    "Monitor for signs of hypoglycemia",
                    "Avoid deep tissue on extremities"
                ]
            case .varicoseVeins:
                return [
                    "Avoid direct pressure on affected veins",
                    "May work above area with light effleurage",
                    "Do not use deep pressure or friction"
                ]
            case .arthritis:
                return [
                    "Use gentle techniques",
                    "Avoid inflamed joints",
                    "Heat or cold therapy may help",
                    "Work within client's pain tolerance"
                ]
            default:
                return [
                    "Proceed with caution",
                    "Modify techniques as needed",
                    "Communicate with client throughout session"
                ]
            }
        }

        var requiresPhysicianClearance: Bool {
            switch self {
            case .cancer, .dvt, .recentSurgery, .severeHypertension,
                 .heartCondition, .hemophilia, .epilepsy:
                return true
            default:
                return false
            }
        }
    }
}

/// Red flag symptoms that require immediate attention or referral
struct RedFlagAlert: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let symptom: RedFlagSymptom
    let detectedDate: Date
    let notes: String
    let actionTaken: String?
    let wasReferred: Bool
    let referralDetails: String?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        symptom: RedFlagSymptom,
        detectedDate: Date = Date(),
        notes: String = "",
        actionTaken: String? = nil,
        wasReferred: Bool = false,
        referralDetails: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.symptom = symptom
        self.detectedDate = detectedDate
        self.notes = notes
        self.actionTaken = actionTaken
        self.wasReferred = wasReferred
        self.referralDetails = referralDetails
    }

    enum RedFlagSymptom: String, Codable, CaseIterable {
        // Neurological Red Flags
        case suddenWeakness = "Sudden Weakness/Numbness"
        case visionChanges = "Vision Changes/Loss"
        case severeHeadache = "Severe Sudden Headache"
        case difficultyWalking = "Difficulty Walking/Balance Issues"
        case confusionSpeech = "Confusion/Speech Difficulty"
        case seizures = "Seizures"

        // Cardiovascular Red Flags
        case chestPain = "Chest Pain/Pressure"
        case shortnessOfBreath = "Severe Shortness of Breath"
        case irregularHeartbeat = "Irregular Heartbeat"
        case legSwelling = "Sudden Leg Swelling (one leg)"
        case cyanosis = "Bluish Skin Color"

        // Musculoskeletal Red Flags
        case traumaticInjury = "Recent Traumatic Injury"
        case progressiveWeakness = "Progressive Muscle Weakness"
        case nightPain = "Severe Night Pain"
        case boneDeformity = "Visible Bone Deformity"
        case crepitus = "Grinding/Popping with Pain"

        // Systemic Red Flags
        case unexplainedWeightLoss = "Unexplained Weight Loss"
        case nightSweats = "Night Sweats/Chills"
        case uncontrolledBleeding = "Uncontrolled Bleeding"
        case highFever = "High Fever (>103°F)"
        case severeAbdominalPain = "Severe Abdominal Pain"

        // Infection Red Flags
        case redStreaking = "Red Streaking on Skin"
        case rapidlySpreadingRash = "Rapidly Spreading Rash"
        case pus = "Pus or Discharge"
        case hotJoint = "Hot, Swollen Joint"

        var urgency: Urgency {
            switch self {
            case .chestPain, .shortnessOfBreath, .suddenWeakness, .visionChanges,
                 .confusionSpeech, .seizures, .uncontrolledBleeding, .cyanosis:
                return .emergency

            case .severeHeadache, .legSwelling, .irregularHeartbeat, .traumaticInjury,
                 .highFever, .severeAbdominalPain, .redStreaking:
                return .urgent

            case .progressiveWeakness, .nightPain, .unexplainedWeightLoss, .nightSweats,
                 .rapidlySpreadingRash, .hotJoint:
                return .prompt

            case .difficultyWalking, .boneDeformity, .crepitus, .pus:
                return .soon
            }
        }

        var recommendedAction: String {
            switch urgency {
            case .emergency:
                return "CALL 911 IMMEDIATELY - Do not massage"
            case .urgent:
                return "Refer to emergency room TODAY - Do not massage"
            case .prompt:
                return "Refer to physician within 24-48 hours - Do not massage"
            case .soon:
                return "Advise to see physician within 1 week - Proceed with caution"
            }
        }

        var icon: String {
            switch urgency {
            case .emergency: return "phone.fill"
            case .urgent: return "cross.fill"
            case .prompt: return "stethoscope"
            case .soon: return "calendar.badge.exclamationmark"
            }
        }

        var color: Color {
            switch urgency {
            case .emergency: return .red
            case .urgent: return .orange
            case .prompt: return .yellow
            case .soon: return .blue
            }
        }
    }

    enum Urgency: String, Codable {
        case emergency = "Emergency - 911"
        case urgent = "Urgent - ER Today"
        case prompt = "Prompt - 24-48 Hours"
        case soon = "Soon - Within 1 Week"
    }
}

/// Service for managing contraindications and red flags
@MainActor
class ContraindicationService: ObservableObject {
    @Published var contraindications: [ContraindicationAlert] = []
    @Published var redFlags: [RedFlagAlert] = []

    private let repository: ContraindicationRepository

    init(repository: ContraindicationRepository = .shared) {
        self.repository = repository
        loadData()
    }

    private func loadData() {
        self.contraindications = repository.getAllContraindications()
        self.redFlags = repository.getAllRedFlags()
    }

    // MARK: - Contraindication Management

    func addContraindication(_ contraindication: ContraindicationAlert) {
        repository.saveContraindication(contraindication)
        contraindications.append(contraindication)
    }

    func updateContraindication(_ contraindication: ContraindicationAlert) {
        repository.updateContraindication(contraindication)
        if let index = contraindications.firstIndex(where: { $0.id == contraindication.id }) {
            contraindications[index] = contraindication
        }
    }

    func resolveContraindication(id: UUID, actionTaken: String) {
        guard let index = contraindications.firstIndex(where: { $0.id == id }) else { return }

        var updated = contraindications[index]
        let resolved = ContraindicationAlert(
            id: updated.id,
            clientId: updated.clientId,
            condition: updated.condition,
            severity: updated.severity,
            detectedDate: updated.detectedDate,
            notes: updated.notes,
            actionTaken: actionTaken,
            isResolved: true,
            resolvedDate: Date()
        )

        updateContraindication(resolved)
    }

    func getActiveContraindicationsForClient(_ clientId: UUID) -> [ContraindicationAlert] {
        contraindications.filter { $0.clientId == clientId && !$0.isResolved }
    }

    func getAbsoluteContraindicationsForClient(_ clientId: UUID) -> [ContraindicationAlert] {
        getActiveContraindicationsForClient(clientId)
            .filter { $0.severity == .absolute }
    }

    func canProceedWithMassage(clientId: UUID) -> (canProceed: Bool, alerts: [ContraindicationAlert]) {
        let absolute = getAbsoluteContraindicationsForClient(clientId)
        return (absolute.isEmpty, absolute)
    }

    // MARK: - Red Flag Management

    func addRedFlag(_ redFlag: RedFlagAlert) {
        repository.saveRedFlag(redFlag)
        redFlags.append(redFlag)
    }

    func updateRedFlag(_ redFlag: RedFlagAlert) {
        repository.updateRedFlag(redFlag)
        if let index = redFlags.firstIndex(where: { $0.id == redFlag.id }) {
            redFlags[index] = redFlag
        }
    }

    func getRedFlagsForClient(_ clientId: UUID) -> [RedFlagAlert] {
        redFlags.filter { $0.clientId == clientId }
    }

    func getEmergencyRedFlagsForClient(_ clientId: UUID) -> [RedFlagAlert] {
        getRedFlagsForClient(clientId)
            .filter { $0.symptom.urgency == .emergency }
    }

    // MARK: - Auto-Detection

    /// Analyze medical history for contraindications
    func detectContraindicationsFromMedicalHistory(
        clientId: UUID,
        conditions: [String],
        medications: [String]
    ) -> [ContraindicationAlert] {
        var detected: [ContraindicationAlert] = []

        // Check conditions
        for condition in conditions.map({ $0.lowercased() }) {
            if let match = matchCondition(condition) {
                let alert = ContraindicationAlert(
                    clientId: clientId,
                    condition: match,
                    severity: match.defaultSeverity,
                    notes: "Detected from medical history"
                )
                detected.append(alert)
            }
        }

        // Check medications
        for medication in medications.map({ $0.lowercased() }) {
            if isBloodThinner(medication) {
                let alert = ContraindicationAlert(
                    clientId: clientId,
                    condition: .bloodThinners,
                    severity: .caution,
                    notes: "Taking blood thinning medication: \(medication)"
                )
                detected.append(alert)
            }
        }

        return detected
    }

    private func matchCondition(_ condition: String) -> ContraindicationAlert.ContraindicationCondition? {
        let keywords: [String: ContraindicationAlert.ContraindicationCondition] = [
            "cancer": .cancer,
            "tumor": .cancer,
            "pregnancy": .pregnancy,
            "pregnant": .pregnancy,
            "diabetes": .diabetes,
            "diabetic": .diabetes,
            "heart": .heartCondition,
            "cardiac": .heartCondition,
            "hypertension": .highBloodPressure,
            "blood pressure": .highBloodPressure,
            "epilepsy": .epilepsy,
            "seizure": .epilepsy,
            "osteoporosis": .severeOsteoporosis,
            "arthritis": .arthritis,
            "fibromyalgia": .fibromyalgia,
            "autoimmune": .autoimmune,
            "lupus": .autoimmune,
            "rheumatoid": .autoimmune,
            "asthma": .asthma,
            "anxiety": .anxiety,
            "depression": .depression,
            "migraine": .migraines,
            "varicose": .varicoseVeins,
            "dvt": .dvt,
            "thrombosis": .dvt
        ]

        for (keyword, conditionType) in keywords {
            if condition.contains(keyword) {
                return conditionType
            }
        }

        return nil
    }

    private func isBloodThinner(_ medication: String) -> Bool {
        let bloodThinners = [
            "warfarin", "coumadin", "aspirin", "plavix", "clopidogrel",
            "eliquis", "apixaban", "xarelto", "rivaroxaban", "heparin"
        ]

        return bloodThinners.contains { medication.contains($0) }
    }

    // MARK: - Statistics

    func getContraindicationStatistics() -> ContraindicationStatistics {
        let total = contraindications.count
        let active = contraindications.filter { !$0.isResolved }.count
        let resolved = contraindications.filter { $0.isResolved }.count

        let byCategory = Dictionary(grouping: contraindications.filter { !$0.isResolved }) { $0.condition.category }

        return ContraindicationStatistics(
            total: total,
            active: active,
            resolved: resolved,
            absolute: contraindications.filter { $0.severity == .absolute && !$0.isResolved }.count,
            local: contraindications.filter { $0.severity == .local && !$0.isResolved }.count,
            caution: contraindications.filter { $0.severity == .caution && !$0.isResolved }.count,
            modified: contraindications.filter { $0.severity == .modified && !$0.isResolved }.count,
            byCategory: byCategory.mapValues { $0.count }
        )
    }

    func getRedFlagStatistics() -> RedFlagStatistics {
        let total = redFlags.count
        let emergency = redFlags.filter { $0.symptom.urgency == .emergency }.count
        let urgent = redFlags.filter { $0.symptom.urgency == .urgent }.count
        let prompt = redFlags.filter { $0.symptom.urgency == .prompt }.count
        let referred = redFlags.filter { $0.wasReferred }.count

        return RedFlagStatistics(
            total: total,
            emergency: emergency,
            urgent: urgent,
            prompt: prompt,
            referred: referred,
            referralRate: total > 0 ? Double(referred) / Double(total) * 100 : 0
        )
    }
}

struct ContraindicationStatistics {
    let total: Int
    let active: Int
    let resolved: Int
    let absolute: Int
    let local: Int
    let caution: Int
    let modified: Int
    let byCategory: [String: Int]
}

struct RedFlagStatistics {
    let total: Int
    let emergency: Int
    let urgent: Int
    let prompt: Int
    let referred: Int
    let referralRate: Double
}

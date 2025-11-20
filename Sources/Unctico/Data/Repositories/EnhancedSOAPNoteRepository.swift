import Foundation

/// Enhanced repository for SOAP notes with body diagrams and advanced assessment
@MainActor
class EnhancedSOAPNoteRepository: ObservableObject {
    static let shared = EnhancedSOAPNoteRepository()

    @Published var treatmentSessions: [TreatmentSession] = []
    @Published var bodyDiagrams: [UUID: [BodyDiagramAnnotation]] = [:] // SOAP Note ID -> Annotations
    @Published var painAssessments: [UUID: PainAssessment] = [:] // SOAP Note ID -> Assessment
    @Published var posturalAssessments: [UUID: PosturalAssessment] = [:] // SOAP Note ID -> Assessment
    @Published var romAssessments: [UUID: [DetailedROMAssessment]] = [:] // SOAP Note ID -> Assessments
    @Published var functionalOutcomes: [UUID: FunctionalOutcome] = [:] // SOAP Note ID -> Outcome

    private let sessionsKey = "unctico_treatment_sessions"
    private let diagramsKey = "unctico_body_diagrams"
    private let painKey = "unctico_pain_assessments"
    private let posturalKey = "unctico_postural_assessments"
    private let romKey = "unctico_rom_assessments"
    private let outcomesKey = "unctico_functional_outcomes"

    init() {
        loadData()
    }

    // MARK: - Treatment Sessions

    func addTreatmentSession(_ session: TreatmentSession) {
        treatmentSessions.append(session)
        saveSessions()
    }

    func updateTreatmentSession(_ session: TreatmentSession) {
        if let index = treatmentSessions.firstIndex(where: { $0.id == session.id }) {
            treatmentSessions[index] = session
            saveSessions()
        }
    }

    func getTreatmentSession(for soapNoteId: UUID) -> TreatmentSession? {
        treatmentSessions.first { $0.soapNoteId == soapNoteId }
    }

    func getAllTreatmentSessions(for clientId: UUID, soapNotes: [SOAPNote]) -> [TreatmentSession] {
        let clientNoteIds = soapNotes.filter { $0.clientId == clientId }.map { $0.id }
        return treatmentSessions.filter { clientNoteIds.contains($0.soapNoteId) }
    }

    // MARK: - Body Diagrams

    func setBodyDiagram(for soapNoteId: UUID, annotations: [BodyDiagramAnnotation]) {
        bodyDiagrams[soapNoteId] = annotations
        saveDiagrams()
    }

    func getBodyDiagram(for soapNoteId: UUID) -> [BodyDiagramAnnotation] {
        bodyDiagrams[soapNoteId] ?? []
    }

    func addAnnotation(_ annotation: BodyDiagramAnnotation, to soapNoteId: UUID) {
        var existing = bodyDiagrams[soapNoteId] ?? []
        existing.append(annotation)
        bodyDiagrams[soapNoteId] = existing
        saveDiagrams()
    }

    func removeAnnotation(_ annotationId: UUID, from soapNoteId: UUID) {
        guard var existing = bodyDiagrams[soapNoteId] else { return }
        existing.removeAll { $0.id == annotationId }
        bodyDiagrams[soapNoteId] = existing
        saveDiagrams()
    }

    // MARK: - Pain Assessments

    func setPainAssessment(for soapNoteId: UUID, assessment: PainAssessment) {
        painAssessments[soapNoteId] = assessment
        savePainAssessments()
    }

    func getPainAssessment(for soapNoteId: UUID) -> PainAssessment? {
        painAssessments[soapNoteId]
    }

    func getPainTrend(for clientId: UUID, soapNotes: [SOAPNote]) -> [PainDataPoint] {
        let clientNoteIds = soapNotes.filter { $0.clientId == clientId }
            .sorted { $0.date < $1.date }
            .map { $0.id }

        return clientNoteIds.compactMap { noteId in
            guard let assessment = painAssessments[noteId],
                  let note = soapNotes.first(where: { $0.id == noteId }) else { return nil }

            return PainDataPoint(
                date: note.date,
                painLevel: assessment.painScale
            )
        }
    }

    // MARK: - Postural Assessments

    func setPosturalAssessment(for soapNoteId: UUID, assessment: PosturalAssessment) {
        posturalAssessments[soapNoteId] = assessment
        savePosturalAssessments()
    }

    func getPosturalAssessment(for soapNoteId: UUID) -> PosturalAssessment? {
        posturalAssessments[soapNoteId]
    }

    // MARK: - ROM Assessments

    func setROMAssessments(for soapNoteId: UUID, assessments: [DetailedROMAssessment]) {
        romAssessments[soapNoteId] = assessments
        saveROMAssessments()
    }

    func getROMAssessments(for soapNoteId: UUID) -> [DetailedROMAssessment] {
        romAssessments[soapNoteId] ?? []
    }

    func addROMAssessment(_ assessment: DetailedROMAssessment, to soapNoteId: UUID) {
        var existing = romAssessments[soapNoteId] ?? []
        existing.append(assessment)
        romAssessments[soapNoteId] = existing
        saveROMAssessments()
    }

    // MARK: - Functional Outcomes

    func setFunctionalOutcome(for soapNoteId: UUID, outcome: FunctionalOutcome) {
        functionalOutcomes[soapNoteId] = outcome
        saveFunctionalOutcomes()
    }

    func getFunctionalOutcome(for soapNoteId: UUID) -> FunctionalOutcome? {
        functionalOutcomes[soapNoteId]
    }

    func getProgressTrend(for clientId: UUID, soapNotes: [SOAPNote]) -> [ProgressDataPoint] {
        let clientNoteIds = soapNotes.filter { $0.clientId == clientId }
            .sorted { $0.date < $1.date }
            .map { $0.id }

        return clientNoteIds.compactMap { noteId in
            guard let outcome = functionalOutcomes[noteId],
                  let note = soapNotes.first(where: { $0.id == noteId }) else { return nil }

            return ProgressDataPoint(
                date: note.date,
                wellbeing: outcome.overallWellbeing,
                sleepQuality: outcome.sleepQuality
            )
        }
    }

    // MARK: - Statistics

    func getTreatmentStatistics(for clientId: UUID, soapNotes: [SOAPNote]) -> TreatmentStatistics {
        let clientSessions = getAllTreatmentSessions(for: clientId, soapNotes: soapNotes)

        let totalSessions = clientSessions.count
        let totalDuration = clientSessions.reduce(0) { $0 + $1.duration }
        let averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0

        var techniquesUsed: [MassageTechnique: Int] = [:]
        for session in clientSessions {
            for technique in session.techniques {
                techniquesUsed[technique.technique, default: 0] += 1
            }
        }

        var modalitiesUsed: [Modality: Int] = [:]
        for session in clientSessions {
            for modality in session.modalities {
                modalitiesUsed[modality.modality, default: 0] += 1
            }
        }

        let painTrend = getPainTrend(for: clientId, soapNotes: soapNotes)
        let averagePain = painTrend.isEmpty ? 0 : painTrend.reduce(0) { $0 + $1.painLevel } / painTrend.count

        return TreatmentStatistics(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            techniquesUsed: techniquesUsed,
            modalitiesUsed: modalitiesUsed,
            averagePainLevel: averagePain,
            painTrend: painTrend
        )
    }

    // MARK: - Quick Phrase Library

    func getQuickPhrases(for section: SOAPSection) -> [String] {
        switch section {
        case .subjective:
            return [
                "Client reports decreased pain since last session",
                "Client reports increased pain this week",
                "Client experiencing difficulty with daily activities",
                "Client sleeping better this week",
                "Client under increased stress at work",
                "Client reports improvement in flexibility",
                "Client experiencing new symptoms",
                "Client reports no change in condition"
            ]
        case .objective:
            return [
                "Increased muscle tension noted in upper trapezius",
                "Trigger points palpable in levator scapulae",
                "Decreased range of motion observed",
                "Improved tissue texture compared to last session",
                "Adhesions noted in IT band",
                "Postural deviations: forward head posture",
                "Muscle guarding present",
                "Good response to treatment today"
            ]
        case .assessment:
            return [
                "Client responding well to treatment",
                "Progress toward goals is satisfactory",
                "Recommend continued treatment at current frequency",
                "Client would benefit from increased frequency",
                "Consider referral to physical therapy",
                "No contraindications noted at this time",
                "Functional improvements observed",
                "Symptoms remain stable"
            ]
        case .plan:
            return [
                "Continue current treatment plan",
                "Increase frequency to twice weekly",
                "Recommend home stretching exercises",
                "Apply heat before session",
                "Use ice after activities",
                "Follow up in 2 weeks",
                "Schedule follow-up in 1 week",
                "Recommend physician consultation"
            ]
        }
    }

    enum SOAPSection {
        case subjective, objective, assessment, plan
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([TreatmentSession].self, from: data) {
            treatmentSessions = decoded
        }

        if let data = UserDefaults.standard.data(forKey: diagramsKey),
           let decoded = try? JSONDecoder().decode([UUID: [BodyDiagramAnnotation]].self, from: data) {
            bodyDiagrams = decoded
        }

        if let data = UserDefaults.standard.data(forKey: painKey),
           let decoded = try? JSONDecoder().decode([UUID: PainAssessment].self, from: data) {
            painAssessments = decoded
        }

        if let data = UserDefaults.standard.data(forKey: posturalKey),
           let decoded = try? JSONDecoder().decode([UUID: PosturalAssessment].self, from: data) {
            posturalAssessments = decoded
        }

        if let data = UserDefaults.standard.data(forKey: romKey),
           let decoded = try? JSONDecoder().decode([UUID: [DetailedROMAssessment]].self, from: data) {
            romAssessments = decoded
        }

        if let data = UserDefaults.standard.data(forKey: outcomesKey),
           let decoded = try? JSONDecoder().decode([UUID: FunctionalOutcome].self, from: data) {
            functionalOutcomes = decoded
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(treatmentSessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    private func saveDiagrams() {
        if let encoded = try? JSONEncoder().encode(bodyDiagrams) {
            UserDefaults.standard.set(encoded, forKey: diagramsKey)
        }
    }

    private func savePainAssessments() {
        if let encoded = try? JSONEncoder().encode(painAssessments) {
            UserDefaults.standard.set(encoded, forKey: painKey)
        }
    }

    private func savePosturalAssessments() {
        if let encoded = try? JSONEncoder().encode(posturalAssessments) {
            UserDefaults.standard.set(encoded, forKey: posturalKey)
        }
    }

    private func saveROMAssessments() {
        if let encoded = try? JSONEncoder().encode(romAssessments) {
            UserDefaults.standard.set(encoded, forKey: romKey)
        }
    }

    private func saveFunctionalOutcomes() {
        if let encoded = try? JSONEncoder().encode(functionalOutcomes) {
            UserDefaults.standard.set(encoded, forKey: outcomesKey)
        }
    }
}

// MARK: - Supporting Types

struct PainDataPoint {
    let date: Date
    let painLevel: Int
}

struct ProgressDataPoint {
    let date: Date
    let wellbeing: Int
    let sleepQuality: Int
}

struct TreatmentStatistics {
    let totalSessions: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let techniquesUsed: [MassageTechnique: Int]
    let modalitiesUsed: [Modality: Int]
    let averagePainLevel: Int
    let painTrend: [PainDataPoint]

    var averageDurationMinutes: Double {
        averageDuration / 60
    }

    var totalDurationHours: Double {
        totalDuration / 3600
    }

    var mostUsedTechnique: MassageTechnique? {
        techniquesUsed.max(by: { $0.value < $1.value })?.key
    }

    var mostUsedModality: Modality? {
        modalitiesUsed.max(by: { $0.value < $1.value })?.key
    }
}

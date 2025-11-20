import Foundation

/// Repository for managing client medical histories
@MainActor
class MedicalHistoryRepository: ObservableObject {
    static let shared = MedicalHistoryRepository()

    @Published var histories: [MedicalHistory] = []

    private let storageKey = "unctico_medical_histories"

    init() {
        loadHistories()
    }

    // MARK: - CRUD Operations

    /// Create or update medical history for a client
    func saveMedicalHistory(_ history: MedicalHistory) {
        if let index = histories.firstIndex(where: { $0.clientId == history.clientId }) {
            histories[index] = history
        } else {
            histories.append(history)
        }
        saveHistories()
    }

    /// Get medical history for a client
    func getHistory(for clientId: UUID) -> MedicalHistory? {
        histories.first { $0.clientId == clientId }
    }

    /// Delete medical history
    func deleteHistory(for clientId: UUID) {
        histories.removeAll { $0.clientId == clientId }
        saveHistories()
    }

    // MARK: - Health Conditions

    /// Add health condition
    func addHealthCondition(_ condition: HealthCondition, to clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.healthConditions.append(condition)
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Update health condition
    func updateHealthCondition(_ condition: HealthCondition, for clientId: UUID) {
        guard var history = getHistory(for: clientId),
              let index = history.healthConditions.firstIndex(where: { $0.id == condition.id }) else { return }
        history.healthConditions[index] = condition
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Remove health condition
    func removeHealthCondition(_ conditionId: UUID, from clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.healthConditions.removeAll { $0.id == conditionId }
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    // MARK: - Medications

    /// Add medication
    func addMedication(_ medication: Medication, to clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.medications.append(medication)
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Update medication
    func updateMedication(_ medication: Medication, for clientId: UUID) {
        guard var history = getHistory(for: clientId),
              let index = history.medications.firstIndex(where: { $0.id == medication.id }) else { return }
        history.medications[index] = medication
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Remove medication
    func removeMedication(_ medicationId: UUID, from clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.medications.removeAll { $0.id == medicationId }
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    // MARK: - Allergies

    /// Add allergy
    func addAllergy(_ allergy: Allergy, to clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.allergies.append(allergy)
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Remove allergy
    func removeAllergy(_ allergyId: UUID, from clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.allergies.removeAll { $0.id == allergyId }
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    // MARK: - Contraindications

    /// Add contraindication
    func addContraindication(_ contraindication: Contraindication, to clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.contraindications.append(contraindication)
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Remove contraindication
    func removeContraindication(_ contraindicationId: UUID, from clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.contraindications.removeAll { $0.id == contraindicationId }
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    // MARK: - Surgeries

    /// Add surgery
    func addSurgery(_ surgery: Surgery, to clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.surgeries.append(surgery)
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    /// Remove surgery
    func removeSurgery(_ surgeryId: UUID, from clientId: UUID) {
        guard var history = getHistory(for: clientId) else { return }
        history.surgeries.removeAll { $0.id == surgeryId }
        history.lastUpdated = Date()
        saveMedicalHistory(history)
    }

    // MARK: - Safety Checks

    /// Get all clients with contraindications
    func getClientsWithContraindications() -> [MedicalHistory] {
        histories.filter { !$0.contraindications.isEmpty }
    }

    /// Get clients with absolute contraindications
    func getClientsWithAbsoluteContraindications() -> [MedicalHistory] {
        histories.filter { history in
            history.contraindications.contains { $0.severity == .absolute }
        }
    }

    /// Get clients with severe allergies
    func getClientsWithSevereAllergies() -> [MedicalHistory] {
        histories.filter { history in
            history.allergies.contains { $0.severity == .severe }
        }
    }

    /// Check for medication interactions
    func checkMedicationInteractions(for clientId: UUID) -> [String] {
        guard let history = getHistory(for: clientId) else { return [] }

        var warnings: [String] = []

        // Check for blood thinners
        let bloodThinnerNames = ["warfarin", "aspirin", "heparin", "eliquis", "xarelto", "coumadin"]
        let hasBloodThinners = history.medications.contains { medication in
            bloodThinnerNames.contains(where: { medication.name.localizedCaseInsensitiveContains($0) })
        }

        if hasBloodThinners {
            warnings.append("Client is on blood thinners - avoid deep tissue work and vigorous techniques")
        }

        // Check for corticosteroids
        let steroidNames = ["prednisone", "cortisone", "prednisolone"]
        let hasSteroids = history.medications.contains { medication in
            steroidNames.contains(where: { medication.name.localizedCaseInsensitiveContains($0) })
        }

        if hasSteroids {
            warnings.append("Client is on corticosteroids - tissue may be fragile, use gentle pressure")
        }

        // Check for muscle relaxants
        let muscleRelaxants = ["flexeril", "soma", "robaxin"]
        let hasMuscleRelaxants = history.medications.contains { medication in
            muscleRelaxants.contains(where: { medication.name.localizedCaseInsensitiveContains($0) })
        }

        if hasMuscleRelaxants {
            warnings.append("Client is on muscle relaxants - be cautious with depth and duration")
        }

        return warnings
    }

    /// Get pregnancy precautions
    func getPregnancyPrecautions(for clientId: UUID) -> [String]? {
        guard let history = getHistory(for: clientId),
              let pregnancy = history.pregnancyStatus,
              pregnancy.isPregnant else { return nil }

        var precautions: [String] = []

        if pregnancy.trimester == 1 {
            precautions.append("First trimester - avoid deep abdominal work")
            precautions.append("Avoid certain pressure points (SP6, LI4, BL67)")
            precautions.append("Limit session time to 45-60 minutes")
        }

        if pregnancy.trimester >= 2 {
            precautions.append("Position client side-lying or semi-reclined")
            precautions.append("Avoid supine position for extended periods")
        }

        if !pregnancy.clearanceForMassage {
            precautions.append("IMPORTANT: Client needs physician clearance before treatment")
        }

        if !pregnancy.complications.isEmpty {
            precautions.append("Complications noted: \(pregnancy.complications)")
        }

        return precautions.isEmpty ? nil : precautions
    }

    /// Generate safety summary for a client
    func getSafetySummary(for clientId: UUID) -> SafetySummary {
        guard let history = getHistory(for: clientId) else {
            return SafetySummary(
                clientId: clientId,
                hasCriticalAlerts: false,
                alerts: [],
                contraindications: [],
                medicationWarnings: [],
                pregnancyPrecautions: nil,
                severeAllergies: [],
                isSafeForTreatment: true
            )
        }

        let criticalAlerts = history.criticalAlerts
        let hasCriticalAlerts = !criticalAlerts.isEmpty

        let absoluteContraindications = history.contraindications.filter { $0.severity == .absolute }
        let isSafeForTreatment = absoluteContraindications.isEmpty

        return SafetySummary(
            clientId: clientId,
            hasCriticalAlerts: hasCriticalAlerts,
            alerts: criticalAlerts,
            contraindications: history.contraindications,
            medicationWarnings: checkMedicationInteractions(for: clientId),
            pregnancyPrecautions: getPregnancyPrecautions(for: clientId),
            severeAllergies: history.allergies.filter { $0.severity == .severe },
            isSafeForTreatment: isSafeForTreatment
        )
    }

    // MARK: - Statistics

    /// Get medical history statistics
    func getStatistics() -> MedicalHistoryStatistics {
        MedicalHistoryStatistics(
            totalHistories: histories.count,
            clientsWithContraindications: getClientsWithContraindications().count,
            clientsWithAllergies: histories.filter { !$0.allergies.isEmpty }.count,
            clientsOnMedications: histories.filter { !$0.medications.isEmpty }.count,
            clientsWithChronicConditions: histories.filter { !$0.chronicConditions.isEmpty }.count,
            pregnantClients: histories.filter { $0.pregnancyStatus?.isPregnant == true }.count,
            clientsWithCriticalAlerts: histories.filter { !$0.criticalAlerts.isEmpty }.count
        )
    }

    // MARK: - Persistence

    private func loadHistories() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MedicalHistory].self, from: data) {
            histories = decoded
        }
    }

    private func saveHistories() {
        if let encoded = try? JSONEncoder().encode(histories) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Supporting Types

struct SafetySummary {
    let clientId: UUID
    let hasCriticalAlerts: Bool
    let alerts: [String]
    let contraindications: [Contraindication]
    let medicationWarnings: [String]
    let pregnancyPrecautions: [String]?
    let severeAllergies: [Allergy]
    let isSafeForTreatment: Bool

    var allWarnings: [String] {
        var warnings: [String] = []
        warnings.append(contentsOf: alerts)
        warnings.append(contentsOf: medicationWarnings)
        if let pregnancy = pregnancyPrecautions {
            warnings.append(contentsOf: pregnancy)
        }
        return warnings
    }
}

struct MedicalHistoryStatistics {
    let totalHistories: Int
    let clientsWithContraindications: Int
    let clientsWithAllergies: Int
    let clientsOnMedications: Int
    let clientsWithChronicConditions: Int
    let pregnantClients: Int
    let clientsWithCriticalAlerts: Int
}

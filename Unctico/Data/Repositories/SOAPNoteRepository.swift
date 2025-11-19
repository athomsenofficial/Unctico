import Foundation
import Combine

class SOAPNoteRepository: ObservableObject {
    static let shared = SOAPNoteRepository()

    @Published private(set) var soapNotes: [SOAPNote] = []

    private let storage = LocalStorageManager.shared
    private let fileName = "soapNotes"

    private init() {
        loadSOAPNotes()
    }

    // MARK: - CRUD Operations

    func loadSOAPNotes() {
        soapNotes = storage.load(from: fileName)

        // If no SOAP notes exist, generate mock data for testing
        if soapNotes.isEmpty {
            print("📦 No SOAP notes found, generating mock data...")
            let clients = ClientRepository.shared.clients
            let appointments = AppointmentRepository.shared.appointments
            soapNotes = MockDataGenerator.shared.generateSOAPNotes(
                for: clients,
                appointments: appointments,
                count: 30
            )
            saveSOAPNotes()
        }
    }

    func saveSOAPNotes() {
        storage.save(soapNotes, to: fileName)
    }

    func addSOAPNote(_ note: SOAPNote) {
        soapNotes.append(note)
        saveSOAPNotes()
    }

    func updateSOAPNote(_ note: SOAPNote) {
        if let index = soapNotes.firstIndex(where: { $0.id == note.id }) {
            soapNotes[index] = note
            saveSOAPNotes()
        }
    }

    func deleteSOAPNote(_ note: SOAPNote) {
        soapNotes.removeAll { $0.id == note.id }
        saveSOAPNotes()
    }

    func getSOAPNote(by id: UUID) -> SOAPNote? {
        return soapNotes.first { $0.id == id }
    }

    // MARK: - Query Methods

    func getSOAPNotes(for clientId: UUID) -> [SOAPNote] {
        return soapNotes
            .filter { $0.clientId == clientId }
            .sorted { $0.date > $1.date }
    }

    func getSOAPNote(for sessionId: UUID) -> SOAPNote? {
        return soapNotes.first { $0.sessionId == sessionId }
    }

    func getRecentSOAPNotes(limit: Int = 10) -> [SOAPNote] {
        return soapNotes
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func getSOAPNotes(in dateRange: ClosedRange<Date>) -> [SOAPNote] {
        return soapNotes.filter { note in
            dateRange.contains(note.date)
        }
    }

    // MARK: - Analytics

    func getAveragePainLevel(for clientId: UUID) -> Double {
        let clientNotes = getSOAPNotes(for: clientId)
        guard !clientNotes.isEmpty else { return 0 }

        let total = clientNotes.reduce(0) { $0 + $1.subjective.painLevel }
        return Double(total) / Double(clientNotes.count)
    }

    func getTreatmentProgressSummary(for clientId: UUID) -> [String] {
        return getSOAPNotes(for: clientId)
            .compactMap { $0.assessment.progressNotes }
            .filter { !$0.isEmpty }
    }

    // MARK: - Test Helpers

    func resetWithMockData(clients: [Client], appointments: [Appointment], count: Int = 30) {
        soapNotes = MockDataGenerator.shared.generateSOAPNotes(
            for: clients,
            appointments: appointments,
            count: count
        )
        saveSOAPNotes()
    }

    func clearAll() {
        soapNotes = []
        storage.delete(fileName: fileName)
    }
}

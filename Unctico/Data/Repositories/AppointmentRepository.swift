import Foundation
import Combine

class AppointmentRepository: ObservableObject {
    static let shared = AppointmentRepository()

    @Published private(set) var appointments: [Appointment] = []

    private let storage = LocalStorageManager.shared
    private let fileName = "appointments"

    private init() {
        loadAppointments()
    }

    // MARK: - CRUD Operations

    func loadAppointments() {
        appointments = storage.load(from: fileName)

        // If no appointments exist, generate mock data for testing
        if appointments.isEmpty {
            print("📦 No appointments found, generating mock data...")
            let clients = ClientRepository.shared.clients
            appointments = MockDataGenerator.shared.generateAppointments(for: clients, count: 50)
            saveAppointments()
        }
    }

    func saveAppointments() {
        storage.save(appointments, to: fileName)
    }

    func addAppointment(_ appointment: Appointment) {
        appointments.append(appointment)
        saveAppointments()
    }

    func updateAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
            saveAppointments()
        }
    }

    func deleteAppointment(_ appointment: Appointment) {
        appointments.removeAll { $0.id == appointment.id }
        saveAppointments()
    }

    func getAppointment(by id: UUID) -> Appointment? {
        return appointments.first { $0.id == id }
    }

    // MARK: - Query Methods

    func getAppointments(for date: Date) -> [Appointment] {
        return appointments.filter { appointment in
            Calendar.current.isDate(appointment.startTime, inSameDayAs: date)
        }
    }

    func getAppointments(for clientId: UUID) -> [Appointment] {
        return appointments.filter { $0.clientId == clientId }
    }

    func getAppointments(with status: AppointmentStatus) -> [Appointment] {
        return appointments.filter { $0.status == status }
    }

    func getTodaysAppointments() -> [Appointment] {
        return getAppointments(for: Date())
    }

    func getUpcomingAppointments(limit: Int = 10) -> [Appointment] {
        let now = Date()
        return appointments
            .filter { $0.startTime >= now }
            .sorted { $0.startTime < $1.startTime }
            .prefix(limit)
            .map { $0 }
    }

    func getAppointments(in dateRange: ClosedRange<Date>) -> [Appointment] {
        return appointments.filter { appointment in
            dateRange.contains(appointment.startTime)
        }
    }

    // MARK: - Statistics

    func getCompletedCount(for date: Date) -> Int {
        return getAppointments(for: date).filter { $0.status == .completed }.count
    }

    func getScheduledCount(for date: Date) -> Int {
        return getAppointments(for: date).filter { $0.status == .scheduled }.count
    }

    // MARK: - Test Helpers

    func resetWithMockData(clients: [Client], count: Int = 50) {
        appointments = MockDataGenerator.shared.generateAppointments(for: clients, count: count)
        saveAppointments()
    }

    func clearAll() {
        appointments = []
        storage.delete(fileName: fileName)
    }
}

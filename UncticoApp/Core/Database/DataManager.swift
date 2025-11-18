// DataManager.swift
// Central database manager for all data operations
// QA Note: This handles ALL data saving and loading - one place to manage everything

import Foundation
import Combine

/// Main data manager - handles all database operations
/// This is a centralized component used throughout the app
class DataManager: ObservableObject {

    // MARK: - Published Properties (UI automatically updates when these change)

    @Published var clients: [Client] = []
    @Published var appointments: [Appointment] = []
    @Published var soapNotes: [SOAPNote] = []
    @Published var therapists: [Therapist] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let storage: DataStorage
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(storage: DataStorage = LocalDataStorage()) {
        self.storage = storage
        loadAllData()
    }

    // MARK: - Load Data

    /// Load all data from storage
    /// QA Note: This runs when app starts
    private func loadAllData() {
        isLoading = true

        // Load clients
        storage.loadClients { [weak self] result in
            switch result {
            case .success(let clients):
                self?.clients = clients
            case .failure(let error):
                self?.errorMessage = "Failed to load clients: \(error.localizedDescription)"
            }
        }

        // Load appointments
        storage.loadAppointments { [weak self] result in
            switch result {
            case .success(let appointments):
                self?.appointments = appointments
            case .failure(let error):
                self?.errorMessage = "Failed to load appointments: \(error.localizedDescription)"
            }
        }

        // Load SOAP notes
        storage.loadSOAPNotes { [weak self] result in
            switch result {
            case .success(let notes):
                self?.soapNotes = notes
            case .failure(let error):
                self?.errorMessage = "Failed to load SOAP notes: \(error.localizedDescription)"
            }
        }

        // Load therapists
        storage.loadTherapists { [weak self] result in
            switch result {
            case .success(let therapists):
                self?.therapists = therapists
            case .failure(let error):
                self?.errorMessage = "Failed to load therapists: \(error.localizedDescription)"
            }
            self?.isLoading = false
        }
    }

    // MARK: - Client Operations

    /// Add a new client
    /// QA Note: Call this to create a new client
    func addClient(_ client: Client) {
        storage.saveClient(client) { [weak self] result in
            switch result {
            case .success:
                self?.clients.append(client)
            case .failure(let error):
                self?.errorMessage = "Failed to save client: \(error.localizedDescription)"
            }
        }
    }

    /// Update existing client
    /// QA Note: Call this after editing client information
    func updateClient(_ client: Client) {
        storage.updateClient(client) { [weak self] result in
            switch result {
            case .success:
                if let index = self?.clients.firstIndex(where: { $0.id == client.id }) {
                    self?.clients[index] = client
                }
            case .failure(let error):
                self?.errorMessage = "Failed to update client: \(error.localizedDescription)"
            }
        }
    }

    /// Delete a client
    /// QA Note: This removes client and all their data
    func deleteClient(_ client: Client) {
        storage.deleteClient(client) { [weak self] result in
            switch result {
            case .success:
                self?.clients.removeAll { $0.id == client.id }
                // Also remove their appointments and SOAP notes
                self?.appointments.removeAll { $0.clientId == client.id }
                self?.soapNotes.removeAll { $0.clientId == client.id }
            case .failure(let error):
                self?.errorMessage = "Failed to delete client: \(error.localizedDescription)"
            }
        }
    }

    /// Get client by ID
    func getClient(id: UUID) -> Client? {
        clients.first { $0.id == id }
    }

    /// Search clients by name
    /// QA Note: Used in search functionality
    func searchClients(query: String) -> [Client] {
        if query.isEmpty {
            return clients
        }
        let lowercasedQuery = query.lowercased()
        return clients.filter {
            $0.firstName.lowercased().contains(lowercasedQuery) ||
            $0.lastName.lowercased().contains(lowercasedQuery) ||
            $0.email.lowercased().contains(lowercasedQuery) ||
            $0.phone.contains(query)
        }
    }

    // MARK: - Appointment Operations

    /// Add new appointment
    func addAppointment(_ appointment: Appointment) {
        storage.saveAppointment(appointment) { [weak self] result in
            switch result {
            case .success:
                self?.appointments.append(appointment)
                self?.appointments.sort { $0.startTime < $1.startTime }
            case .failure(let error):
                self?.errorMessage = "Failed to save appointment: \(error.localizedDescription)"
            }
        }
    }

    /// Update appointment
    func updateAppointment(_ appointment: Appointment) {
        storage.updateAppointment(appointment) { [weak self] result in
            switch result {
            case .success:
                if let index = self?.appointments.firstIndex(where: { $0.id == appointment.id }) {
                    self?.appointments[index] = appointment
                }
            case .failure(let error):
                self?.errorMessage = "Failed to update appointment: \(error.localizedDescription)"
            }
        }
    }

    /// Delete appointment
    func deleteAppointment(_ appointment: Appointment) {
        storage.deleteAppointment(appointment) { [weak self] result in
            switch result {
            case .success:
                self?.appointments.removeAll { $0.id == appointment.id }
            case .failure(let error):
                self?.errorMessage = "Failed to delete appointment: \(error.localizedDescription)"
            }
        }
    }

    /// Get appointments for a specific date
    /// QA Note: Used in calendar view
    func getAppointments(for date: Date) -> [Appointment] {
        appointments.filter {
            Calendar.current.isDate($0.startTime, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
    }

    /// Get appointments for a specific client
    func getAppointments(forClient clientId: UUID) -> [Appointment] {
        appointments.filter { $0.clientId == clientId }
            .sorted { $0.startTime > $1.startTime }  // Most recent first
    }

    /// Get upcoming appointments
    func getUpcomingAppointments() -> [Appointment] {
        let now = Date()
        return appointments.filter { $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - SOAP Note Operations

    /// Add new SOAP note
    func addSOAPNote(_ note: SOAPNote) {
        storage.saveSOAPNote(note) { [weak self] result in
            switch result {
            case .success:
                self?.soapNotes.append(note)
            case .failure(let error):
                self?.errorMessage = "Failed to save SOAP note: \(error.localizedDescription)"
            }
        }
    }

    /// Update SOAP note
    func updateSOAPNote(_ note: SOAPNote) {
        var updatedNote = note
        updatedNote.lastModifiedDate = Date()

        storage.updateSOAPNote(updatedNote) { [weak self] result in
            switch result {
            case .success:
                if let index = self?.soapNotes.firstIndex(where: { $0.id == note.id }) {
                    self?.soapNotes[index] = updatedNote
                }
            case .failure(let error):
                self?.errorMessage = "Failed to update SOAP note: \(error.localizedDescription)"
            }
        }
    }

    /// Get SOAP notes for a client
    func getSOAPNotes(forClient clientId: UUID) -> [SOAPNote] {
        soapNotes.filter { $0.clientId == clientId }
            .sorted { $0.createdDate > $1.createdDate }  // Most recent first
    }

    // MARK: - Therapist Operations

    /// Add therapist
    func addTherapist(_ therapist: Therapist) {
        storage.saveTherapist(therapist) { [weak self] result in
            switch result {
            case .success:
                self?.therapists.append(therapist)
            case .failure(let error):
                self?.errorMessage = "Failed to save therapist: \(error.localizedDescription)"
            }
        }
    }

    /// Update therapist
    func updateTherapist(_ therapist: Therapist) {
        storage.updateTherapist(therapist) { [weak self] result in
            switch result {
            case .success:
                if let index = self?.therapists.firstIndex(where: { $0.id == therapist.id }) {
                    self?.therapists[index] = therapist
                }
            case .failure(let error):
                self?.errorMessage = "Failed to update therapist: \(error.localizedDescription)"
            }
        }
    }

    /// Get therapist by ID
    func getTherapist(id: UUID) -> Therapist? {
        therapists.first { $0.id == id }
    }
}

// MARK: - DataStorage Protocol

/// Protocol defining data storage operations
/// QA Note: This allows us to swap storage methods (local, cloud, etc.)
protocol DataStorage {
    // Client operations
    func loadClients(completion: @escaping (Result<[Client], Error>) -> Void)
    func saveClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void)
    func updateClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void)

    // Appointment operations
    func loadAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void)
    func saveAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void)
    func updateAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void)

    // SOAP note operations
    func loadSOAPNotes(completion: @escaping (Result<[SOAPNote], Error>) -> Void)
    func saveSOAPNote(_ note: SOAPNote, completion: @escaping (Result<Void, Error>) -> Void)
    func updateSOAPNote(_ note: SOAPNote, completion: @escaping (Result<Void, Error>) -> Void)

    // Therapist operations
    func loadTherapists(completion: @escaping (Result<[Therapist], Error>) -> Void)
    func saveTherapist(_ therapist: Therapist, completion: @escaping (Result<Void, Error>) -> Void)
    func updateTherapist(_ therapist: Therapist, completion: @escaping (Result<Void, Error>) -> Void)
}

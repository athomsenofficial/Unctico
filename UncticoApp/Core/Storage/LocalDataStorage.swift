// LocalDataStorage.swift
// Local file-based encrypted data storage
// QA Note: This saves data to device with encryption

import Foundation

/// Local storage implementation with encryption
class LocalDataStorage: DataStorage {

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let encryptionKey: String
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - File Names

    private let clientsFile = "clients.json"
    private let appointmentsFile = "appointments.json"
    private let soapNotesFile = "soapnotes.json"
    private let therapistsFile = "therapists.json"

    // MARK: - Initialization

    init(encryptionKey: String = "unctico_default_key_change_in_production") {
        self.encryptionKey = encryptionKey
        createDirectoryIfNeeded()
    }

    /// Create documents directory if it doesn't exist
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Generic Save/Load Methods

    /// Save any Codable object to file
    /// QA Note: This is a reusable method for saving ANY type of data
    private func save<T: Codable>(_ object: T, to filename: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        do {
            // Convert object to JSON data
            let data = try JSONEncoder().encode(object)

            // Encrypt if enabled
            let finalData = AppConfig.enableEncryption ? encrypt(data) : data

            // Write to file
            try finalData.write(to: fileURL, options: .atomic)
            completion(.success(()))

        } catch {
            completion(.failure(error))
        }
    }

    /// Load any Codable object from file
    /// QA Note: This is a reusable method for loading ANY type of data
    private func load<T: Codable>(from filename: String, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // File doesn't exist yet - return empty result based on type
            if let emptyArray = [] as? T {
                completion(.success(emptyArray))
            } else {
                completion(.failure(StorageError.fileNotFound))
            }
            return
        }

        do {
            // Read file data
            let data = try Data(contentsOf: fileURL)

            // Decrypt if enabled
            let finalData = AppConfig.enableEncryption ? decrypt(data) : data

            // Decode JSON to object
            let object = try JSONDecoder().decode(type, from: finalData)
            completion(.success(object))

        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Client Operations

    func loadClients(completion: @escaping (Result<[Client], Error>) -> Void) {
        load(from: clientsFile, as: [Client].self, completion: completion)
    }

    func saveClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void) {
        // Load existing clients
        loadClients { result in
            switch result {
            case .success(var clients):
                // Add new client
                clients.append(client)
                // Save all clients
                self.save(clients, to: self.clientsFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void) {
        loadClients { result in
            switch result {
            case .success(var clients):
                // Find and replace client
                if let index = clients.firstIndex(where: { $0.id == client.id }) {
                    clients[index] = client
                    self.save(clients, to: self.clientsFile, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteClient(_ client: Client, completion: @escaping (Result<Void, Error>) -> Void) {
        loadClients { result in
            switch result {
            case .success(var clients):
                // Remove client
                clients.removeAll { $0.id == client.id }
                self.save(clients, to: self.clientsFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Appointment Operations

    func loadAppointments(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        load(from: appointmentsFile, as: [Appointment].self, completion: completion)
    }

    func saveAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void) {
        loadAppointments { result in
            switch result {
            case .success(var appointments):
                appointments.append(appointment)
                self.save(appointments, to: self.appointmentsFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void) {
        loadAppointments { result in
            switch result {
            case .success(var appointments):
                if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                    appointments[index] = appointment
                    self.save(appointments, to: self.appointmentsFile, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteAppointment(_ appointment: Appointment, completion: @escaping (Result<Void, Error>) -> Void) {
        loadAppointments { result in
            switch result {
            case .success(var appointments):
                appointments.removeAll { $0.id == appointment.id }
                self.save(appointments, to: self.appointmentsFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - SOAP Note Operations

    func loadSOAPNotes(completion: @escaping (Result<[SOAPNote], Error>) -> Void) {
        load(from: soapNotesFile, as: [SOAPNote].self, completion: completion)
    }

    func saveSOAPNote(_ note: SOAPNote, completion: @escaping (Result<Void, Error>) -> Void) {
        loadSOAPNotes { result in
            switch result {
            case .success(var notes):
                notes.append(note)
                self.save(notes, to: self.soapNotesFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateSOAPNote(_ note: SOAPNote, completion: @escaping (Result<Void, Error>) -> Void) {
        loadSOAPNotes { result in
            switch result {
            case .success(var notes):
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index] = note
                    self.save(notes, to: self.soapNotesFile, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Therapist Operations

    func loadTherapists(completion: @escaping (Result<[Therapist], Error>) -> Void) {
        load(from: therapistsFile, as: [Therapist].self, completion: completion)
    }

    func saveTherapist(_ therapist: Therapist, completion: @escaping (Result<Void, Error>) -> Void) {
        loadTherapists { result in
            switch result {
            case .success(var therapists):
                therapists.append(therapist)
                self.save(therapists, to: self.therapistsFile, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateTherapist(_ therapist: Therapist, completion: @escaping (Result<Void, Error>) -> Void) {
        loadTherapists { result in
            switch result {
            case .success(var therapists):
                if let index = therapists.firstIndex(where: { $0.id == therapist.id }) {
                    therapists[index] = therapist
                    self.save(therapists, to: self.therapistsFile, completion: completion)
                } else {
                    completion(.failure(StorageError.notFound))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Encryption (Simple XOR - replace with proper encryption in production)

    /// Encrypt data
    /// QA Note: In production, this should use AES encryption
    private func encrypt(_ data: Data) -> Data {
        // Simple XOR encryption for demo
        // TODO: Replace with proper AES encryption in production
        return xor(data, key: encryptionKey)
    }

    /// Decrypt data
    private func decrypt(_ data: Data) -> Data {
        // XOR encryption is symmetric, so decrypt = encrypt
        return xor(data, key: encryptionKey)
    }

    /// XOR data with key
    private func xor(_ data: Data, key: String) -> Data {
        let keyData = key.data(using: .utf8) ?? Data()
        guard !keyData.isEmpty else { return data }

        var result = Data(count: data.count)
        for (index, byte) in data.enumerated() {
            result[index] = byte ^ keyData[index % keyData.count]
        }
        return result
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case fileNotFound
    case notFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Data file not found"
        case .notFound:
            return "Item not found in storage"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}

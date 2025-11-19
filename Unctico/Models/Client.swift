import Foundation

struct Client: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var dateOfBirth: Date?
    var address: Address?
    var medicalHistory: MedicalHistory
    var preferences: ClientPreferences
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String? = nil,
        phone: String? = nil,
        dateOfBirth: Date? = nil,
        address: Address? = nil,
        medicalHistory: MedicalHistory = MedicalHistory(),
        preferences: ClientPreferences = ClientPreferences(),
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.medicalHistory = medicalHistory
        self.preferences = preferences
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
}

struct MedicalHistory: Codable {
    var conditions: [String] = []
    var medications: [String] = []
    var allergies: [String] = []
    var surgeries: [MedicalEvent] = []
    var contraindications: [String] = []

    struct MedicalEvent: Codable, Identifiable {
        let id: UUID
        var description: String
        var date: Date

        init(id: UUID = UUID(), description: String, date: Date) {
            self.id = id
            self.description = description
            self.date = date
        }
    }
}

struct ClientPreferences: Codable {
    var pressureLevel: PressureLevel = .medium
    var temperaturePreference: TemperaturePreference = .neutral
    var musicPreference: String?
    var aromatherapyPreference: [String] = []
    var preferredTherapist: String?
    var communicationMethod: CommunicationMethod = .email
    var appointmentTimePreference: String?

    enum PressureLevel: String, Codable, CaseIterable {
        case light = "Light"
        case medium = "Medium"
        case firm = "Firm"
        case deep = "Deep Tissue"
    }

    enum TemperaturePreference: String, Codable, CaseIterable {
        case cool = "Cool"
        case neutral = "Neutral"
        case warm = "Warm"
    }

    enum CommunicationMethod: String, Codable, CaseIterable {
        case email = "Email"
        case sms = "SMS"
        case phone = "Phone"
        case app = "In-App"
    }
}

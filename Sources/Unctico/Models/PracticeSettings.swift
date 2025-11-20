import Foundation

struct PracticeSettings: Codable {
    var businessInfo: BusinessInfo
    var services: [Service]
    var availability: WeeklyAvailability

    init(
        businessInfo: BusinessInfo = BusinessInfo(),
        services: [Service] = [],
        availability: WeeklyAvailability = WeeklyAvailability()
    ) {
        self.businessInfo = businessInfo
        self.services = services
        self.availability = availability
    }
}

// MARK: - Business Information
struct BusinessInfo: Codable {
    var practiceName: String
    var ownerName: String
    var licenseNumber: String
    var taxId: String
    var phone: String
    var email: String
    var website: String
    var address: BusinessAddress

    init(
        practiceName: String = "",
        ownerName: String = "",
        licenseNumber: String = "",
        taxId: String = "",
        phone: String = "",
        email: String = "",
        website: String = "",
        address: BusinessAddress = BusinessAddress()
    ) {
        self.practiceName = practiceName
        self.ownerName = ownerName
        self.licenseNumber = licenseNumber
        self.taxId = taxId
        self.phone = phone
        self.email = email
        self.website = website
        self.address = address
    }
}

struct BusinessAddress: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String

    init(
        street: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
        country: String = "USA"
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }

    var fullAddress: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
}

// MARK: - Service Type
struct Service: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: TimeInterval
    var price: Double
    var description: String
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        price: Double,
        description: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.price = price
        self.description = description
        self.isActive = isActive
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

// MARK: - Weekly Availability
struct WeeklyAvailability: Codable {
    var monday: DayAvailability
    var tuesday: DayAvailability
    var wednesday: DayAvailability
    var thursday: DayAvailability
    var friday: DayAvailability
    var saturday: DayAvailability
    var sunday: DayAvailability

    init(
        monday: DayAvailability = DayAvailability(),
        tuesday: DayAvailability = DayAvailability(),
        wednesday: DayAvailability = DayAvailability(),
        thursday: DayAvailability = DayAvailability(),
        friday: DayAvailability = DayAvailability(),
        saturday: DayAvailability = DayAvailability(isAvailable: false),
        sunday: DayAvailability = DayAvailability(isAvailable: false)
    ) {
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
    }

    func availability(for weekday: Weekday) -> DayAvailability {
        switch weekday {
        case .monday: return monday
        case .tuesday: return tuesday
        case .wednesday: return wednesday
        case .thursday: return thursday
        case .friday: return friday
        case .saturday: return saturday
        case .sunday: return sunday
        }
    }

    mutating func setAvailability(_ availability: DayAvailability, for weekday: Weekday) {
        switch weekday {
        case .monday: monday = availability
        case .tuesday: tuesday = availability
        case .wednesday: wednesday = availability
        case .thursday: thursday = availability
        case .friday: friday = availability
        case .saturday: saturday = availability
        case .sunday: sunday = availability
        }
    }

    enum Weekday: String, CaseIterable {
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case .saturday = "Saturday"
        case sunday = "Sunday"
    }
}

struct DayAvailability: Codable {
    var isAvailable: Bool
    var startTime: String
    var endTime: String
    var breakStart: String?
    var breakEnd: String?

    init(
        isAvailable: Bool = true,
        startTime: String = "09:00",
        endTime: String = "17:00",
        breakStart: String? = nil,
        breakEnd: String? = nil
    ) {
        self.isAvailable = isAvailable
        self.startTime = startTime
        self.endTime = endTime
        self.breakStart = breakStart
        self.breakEnd = breakEnd
    }
}

// MARK: - Practice Settings Repository
class PracticeSettingsRepository: ObservableObject {
    static let shared = PracticeSettingsRepository()

    @Published var settings: PracticeSettings

    private let storageKey = "practice_settings"
    private let storage = LocalStorageManager.shared

    private init() {
        self.settings = PracticeSettingsRepository.loadSettings()
    }

    private static func loadSettings() -> PracticeSettings {
        if let data = try? LocalStorageManager.shared.load(key: "practice_settings", as: PracticeSettings.self) {
            return data
        }
        return PracticeSettings()
    }

    func save() {
        do {
            try storage.save(settings, key: storageKey)
            print("✅ Practice settings saved successfully")
        } catch {
            print("❌ Failed to save practice settings: \(error)")
        }
    }

    func updateBusinessInfo(_ info: BusinessInfo) {
        settings.businessInfo = info
        save()
    }

    func addService(_ service: Service) {
        settings.services.append(service)
        save()
    }

    func updateService(_ service: Service) {
        if let index = settings.services.firstIndex(where: { $0.id == service.id }) {
            settings.services[index] = service
            save()
        }
    }

    func deleteService(_ service: Service) {
        settings.services.removeAll { $0.id == service.id }
        save()
    }

    func updateAvailability(_ availability: WeeklyAvailability) {
        settings.availability = availability
        save()
    }
}

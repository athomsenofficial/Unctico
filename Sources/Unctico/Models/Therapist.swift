import Foundation

struct Therapist: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var licenseNumber: String
    var licenseState: String
    var licenseExpiry: Date
    var npiNumber: String?
    var specialty: [TherapistSpecialty]
    var employmentType: EmploymentType
    var hireDate: Date
    var terminationDate: Date?
    var status: TherapistStatus
    var commission: CommissionStructure
    var availability: WeeklyAvailability
    var certifications: [Certification]
    var performanceMetrics: PerformanceMetrics
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        licenseNumber: String,
        licenseState: String,
        licenseExpiry: Date,
        npiNumber: String? = nil,
        specialty: [TherapistSpecialty] = [],
        employmentType: EmploymentType = .employee,
        hireDate: Date = Date(),
        terminationDate: Date? = nil,
        status: TherapistStatus = .active,
        commission: CommissionStructure = CommissionStructure(),
        availability: WeeklyAvailability = WeeklyAvailability(),
        certifications: [Certification] = [],
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.licenseState = licenseState
        self.licenseExpiry = licenseExpiry
        self.npiNumber = npiNumber
        self.specialty = specialty
        self.employmentType = employmentType
        self.hireDate = hireDate
        self.terminationDate = terminationDate
        self.status = status
        self.commission = commission
        self.availability = availability
        self.certifications = certifications
        self.performanceMetrics = performanceMetrics
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var isActive: Bool {
        status == .active
    }
}

enum TherapistSpecialty: String, Codable, CaseIterable {
    case swedish = "Swedish"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case prenatal = "Prenatal"
    case geriatric = "Geriatric"
    case pediatric = "Pediatric"
    case medical = "Medical Massage"
    case lymphatic = "Lymphatic Drainage"
    case trigger = "Trigger Point"
    case myofascial = "Myofascial Release"
    case craniosacral = "Craniosacral"
    case shiatsu = "Shiatsu"
    case thai = "Thai Massage"
}

enum EmploymentType: String, Codable, CaseIterable {
    case employee = "Employee"
    case contractor = "Independent Contractor"
    case partner = "Partner"
    case owner = "Owner"
}

enum TherapistStatus: String, Codable, CaseIterable {
    case active = "Active"
    case onLeave = "On Leave"
    case inactive = "Inactive"
    case terminated = "Terminated"
}

struct CommissionStructure: Codable {
    var type: CommissionType
    var baseRate: Double
    var tieredRates: [CommissionTier]
    var productCommissionRate: Double
    var bonusThresholds: [BonusThreshold]

    init(
        type: CommissionType = .percentage,
        baseRate: Double = 0.5,
        tieredRates: [CommissionTier] = [],
        productCommissionRate: Double = 0.1,
        bonusThresholds: [BonusThreshold] = []
    ) {
        self.type = type
        self.baseRate = baseRate
        self.tieredRates = tieredRates
        self.productCommissionRate = productCommissionRate
        self.bonusThresholds = bonusThresholds
    }

    enum CommissionType: String, Codable {
        case percentage = "Percentage"
        case perService = "Per Service"
        case hourly = "Hourly"
        case salary = "Salary"
    }
}

struct CommissionTier: Codable, Identifiable {
    let id: UUID
    var threshold: Double
    var rate: Double

    init(id: UUID = UUID(), threshold: Double, rate: Double) {
        self.id = id
        self.threshold = threshold
        self.rate = rate
    }
}

struct BonusThreshold: Codable, Identifiable {
    let id: UUID
    var name: String
    var threshold: Double
    var bonusAmount: Double

    init(id: UUID = UUID(), name: String, threshold: Double, bonusAmount: Double) {
        self.id = id
        self.name = name
        self.threshold = threshold
        self.bonusAmount = bonusAmount
    }
}

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

struct Certification: Identifiable, Codable {
    let id: UUID
    var name: String
    var issuingOrganization: String
    var certificationNumber: String
    var issueDate: Date
    var expiryDate: Date?
    var requiresRenewal: Bool

    init(
        id: UUID = UUID(),
        name: String,
        issuingOrganization: String,
        certificationNumber: String,
        issueDate: Date,
        expiryDate: Date? = nil,
        requiresRenewal: Bool = true
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.certificationNumber = certificationNumber
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.requiresRenewal = requiresRenewal
    }
}

struct PerformanceMetrics: Codable {
    var totalRevenue: Double
    var totalAppointments: Int
    var averageRating: Double
    var clientRetentionRate: Double
    var averageSessionDuration: Double
    var rebookingRate: Double
    var productSales: Double
    var tipTotal: Double

    init(
        totalRevenue: Double = 0,
        totalAppointments: Int = 0,
        averageRating: Double = 0,
        clientRetentionRate: Double = 0,
        rebookingRate: Double = 0,
        averageSessionDuration: Double = 0,
        productSales: Double = 0,
        tipTotal: Double = 0
    ) {
        self.totalRevenue = totalRevenue
        self.totalAppointments = totalAppointments
        self.averageRating = averageRating
        self.clientRetentionRate = clientRetentionRate
        self.rebookingRate = rebookingRate
        self.averageSessionDuration = averageSessionDuration
        self.productSales = productSales
        self.tipTotal = tipTotal
    }

    var averageRevenuePerAppointment: Double {
        guard totalAppointments > 0 else { return 0 }
        return totalRevenue / Double(totalAppointments)
    }
}

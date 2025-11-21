import Foundation

/// Team and staff management models for multi-therapist practices

// MARK: - Staff Member

struct StaffMember: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var role: StaffRole
    var licenseNumber: String?
    var licenseExpiration: Date?
    var specializations: [String]
    var employmentType: EmploymentType
    var hireDate: Date
    var terminationDate: Date?
    var isActive: Bool
    var photo: String? // URL or asset name
    var address: Address
    var emergencyContact: EmergencyContact?
    var compensation: CompensationModel
    var availability: WeeklyAvailability
    var assignedRooms: [String] // Room IDs or names
    var notes: String

    // Certifications and training
    var certifications: [Certification]
    var continuingEducation: [CECredit]

    // Performance tracking
    var performanceMetrics: PerformanceMetrics?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        role: StaffRole,
        licenseNumber: String? = nil,
        licenseExpiration: Date? = nil,
        specializations: [String] = [],
        employmentType: EmploymentType,
        hireDate: Date = Date(),
        terminationDate: Date? = nil,
        isActive: Bool = true,
        photo: String? = nil,
        address: Address = Address(),
        emergencyContact: EmergencyContact? = nil,
        compensation: CompensationModel,
        availability: WeeklyAvailability = WeeklyAvailability(),
        assignedRooms: [String] = [],
        notes: String = "",
        certifications: [Certification] = [],
        continuingEducation: [CECredit] = [],
        performanceMetrics: PerformanceMetrics? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.role = role
        self.licenseNumber = licenseNumber
        self.licenseExpiration = licenseExpiration
        self.specializations = specializations
        self.employmentType = employmentType
        self.hireDate = hireDate
        self.terminationDate = terminationDate
        self.isActive = isActive
        self.photo = photo
        self.address = address
        self.emergencyContact = emergencyContact
        self.compensation = compensation
        self.availability = availability
        self.assignedRooms = assignedRooms
        self.notes = notes
        self.certifications = certifications
        self.continuingEducation = continuingEducation
        self.performanceMetrics = performanceMetrics
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var isLicenseExpiringSoon: Bool {
        guard let expiration = licenseExpiration else { return false }
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return daysUntilExpiration <= 30 && daysUntilExpiration > 0
    }

    var isLicenseExpired: Bool {
        guard let expiration = licenseExpiration else { return false }
        return Date() > expiration
    }

    var canProvideServices: Bool {
        isActive && !isLicenseExpired && role.canProvideServices
    }
}

enum StaffRole: String, Codable, CaseIterable {
    case owner = "Owner/Therapist"
    case massageTherapist = "Massage Therapist"
    case leadTherapist = "Lead Therapist"
    case receptionist = "Receptionist"
    case manager = "Practice Manager"
    case assistant = "Assistant"
    case other = "Other"

    var canProvideServices: Bool {
        switch self {
        case .owner, .massageTherapist, .leadTherapist:
            return true
        case .receptionist, .manager, .assistant, .other:
            return false
        }
    }

    var permissions: Set<Permission> {
        switch self {
        case .owner:
            return Set(Permission.allCases)
        case .manager:
            return [.viewClients, .editClients, .viewSchedule, .editSchedule, .viewReports, .viewFinancials, .manageStaff]
        case .leadTherapist:
            return [.viewClients, .editClients, .viewSchedule, .editSchedule, .viewReports, .provideServices]
        case .massageTherapist:
            return [.viewClients, .editClients, .viewSchedule, .provideServices]
        case .receptionist:
            return [.viewClients, .editClients, .viewSchedule, .editSchedule]
        case .assistant:
            return [.viewClients, .viewSchedule]
        case .other:
            return []
        }
    }
}

enum Permission: String, Codable, CaseIterable {
    case viewClients = "View Clients"
    case editClients = "Edit Clients"
    case viewSchedule = "View Schedule"
    case editSchedule = "Edit Schedule"
    case viewReports = "View Reports"
    case viewFinancials = "View Financials"
    case editFinancials = "Edit Financials"
    case manageStaff = "Manage Staff"
    case provideServices = "Provide Services"
    case manageInventory = "Manage Inventory"
    case systemSettings = "System Settings"
}

enum EmploymentType: String, Codable, CaseIterable {
    case fullTime = "Full-Time"
    case partTime = "Part-Time"
    case contractor = "Independent Contractor"
    case intern = "Intern"
    case temporary = "Temporary"
}

// MARK: - Emergency Contact

struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phone: String
    var alternatePhone: String?

    init(
        name: String = "",
        relationship: String = "",
        phone: String = "",
        alternatePhone: String? = nil
    ) {
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.alternatePhone = alternatePhone
    }
}

// MARK: - Compensation

struct CompensationModel: Codable {
    var type: CompensationType
    var baseRate: Double // Hourly rate or base salary
    var commissionRate: Double? // Percentage (0-100)
    var commissionStructure: CommissionStructure?
    var benefits: [String]
    var notes: String

    init(
        type: CompensationType,
        baseRate: Double,
        commissionRate: Double? = nil,
        commissionStructure: CommissionStructure? = nil,
        benefits: [String] = [],
        notes: String = ""
    ) {
        self.type = type
        self.baseRate = baseRate
        self.commissionRate = commissionRate
        self.commissionStructure = commissionStructure
        self.benefits = benefits
        self.notes = notes
    }
}

enum CompensationType: String, Codable {
    case hourly = "Hourly"
    case salary = "Salary"
    case commission = "Commission Only"
    case hourlyPlusCommission = "Hourly + Commission"
    case perService = "Per Service"
}

struct CommissionStructure: Codable {
    var tiers: [CommissionTier]
    var basedOn: CommissionBase

    init(tiers: [CommissionTier] = [], basedOn: CommissionBase = .revenue) {
        self.tiers = tiers
        self.basedOn = basedOn
    }
}

struct CommissionTier: Codable, Identifiable {
    let id: UUID
    var threshold: Double // Monthly revenue/appointments
    var rate: Double // Percentage

    init(id: UUID = UUID(), threshold: Double, rate: Double) {
        self.id = id
        self.threshold = threshold
        self.rate = rate
    }
}

enum CommissionBase: String, Codable {
    case revenue = "Revenue"
    case appointments = "Number of Appointments"
    case newClients = "New Clients"
}

// MARK: - Certifications

struct Certification: Identifiable, Codable {
    let id: UUID
    var name: String
    var issuingOrganization: String
    var certificationNumber: String
    var issueDate: Date
    var expirationDate: Date?
    var renewalRequired: Bool
    var documentUrl: String?
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        issuingOrganization: String,
        certificationNumber: String = "",
        issueDate: Date = Date(),
        expirationDate: Date? = nil,
        renewalRequired: Bool = false,
        documentUrl: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.issuingOrganization = issuingOrganization
        self.certificationNumber = certificationNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.renewalRequired = renewalRequired
        self.documentUrl = documentUrl
        self.notes = notes
    }

    var isExpiringSoon: Bool {
        guard let expiration = expirationDate else { return false }
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return daysUntilExpiration <= 30 && daysUntilExpiration > 0
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }
}

struct CECredit: Identifiable, Codable {
    let id: UUID
    var courseName: String
    var provider: String
    var credits: Double
    var completionDate: Date
    var category: String
    var certificateUrl: String?
    var notes: String

    init(
        id: UUID = UUID(),
        courseName: String,
        provider: String,
        credits: Double,
        completionDate: Date = Date(),
        category: String = "",
        certificateUrl: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.courseName = courseName
        self.provider = provider
        self.credits = credits
        self.completionDate = completionDate
        self.category = category
        self.certificateUrl = certificateUrl
        self.notes = notes
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics: Codable {
    var period: DateRange
    var totalAppointments: Int
    var totalRevenue: Double
    var averageRating: Double
    var clientRetentionRate: Double
    var rebookingRate: Double
    var cancellationRate: Double
    var noShowRate: Double
    var averageServiceDuration: TimeInterval
    var newClients: Int
    var repeatClients: Int

    init(
        period: DateRange = DateRange(start: Date(), end: Date()),
        totalAppointments: Int = 0,
        totalRevenue: Double = 0,
        averageRating: Double = 0,
        clientRetentionRate: Double = 0,
        rebookingRate: Double = 0,
        cancellationRate: Double = 0,
        noShowRate: Double = 0,
        averageServiceDuration: TimeInterval = 0,
        newClients: Int = 0,
        repeatClients: Int = 0
    ) {
        self.period = period
        self.totalAppointments = totalAppointments
        self.totalRevenue = totalRevenue
        self.averageRating = averageRating
        self.clientRetentionRate = clientRetentionRate
        self.rebookingRate = rebookingRate
        self.cancellationRate = cancellationRate
        self.noShowRate = noShowRate
        self.averageServiceDuration = averageServiceDuration
        self.newClients = newClients
        self.repeatClients = repeatClients
    }

    var averageRevenuePerAppointment: Double {
        guard totalAppointments > 0 else { return 0 }
        return totalRevenue / Double(totalAppointments)
    }
}

// MARK: - Time Off Requests

struct TimeOffRequest: Identifiable, Codable {
    let id: UUID
    let staffId: UUID
    let staffName: String
    var requestType: TimeOffType
    var startDate: Date
    var endDate: Date
    var status: RequestStatus
    var reason: String
    var notes: String
    var requestedDate: Date
    var reviewedBy: UUID?
    var reviewedDate: Date?
    var reviewNotes: String

    init(
        id: UUID = UUID(),
        staffId: UUID,
        staffName: String,
        requestType: TimeOffType,
        startDate: Date,
        endDate: Date,
        status: RequestStatus = .pending,
        reason: String = "",
        notes: String = "",
        requestedDate: Date = Date(),
        reviewedBy: UUID? = nil,
        reviewedDate: Date? = nil,
        reviewNotes: String = ""
    ) {
        self.id = id
        self.staffId = staffId
        self.staffName = staffName
        self.requestType = requestType
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.reason = reason
        self.notes = notes
        self.requestedDate = requestedDate
        self.reviewedBy = reviewedBy
        self.reviewedDate = reviewedDate
        self.reviewNotes = reviewNotes
    }

    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var isPending: Bool {
        status == .pending
    }
}

enum TimeOffType: String, Codable, CaseIterable {
    case vacation = "Vacation"
    case sick = "Sick Leave"
    case personal = "Personal Day"
    case continuing_education = "Continuing Education"
    case unpaid = "Unpaid Leave"
    case other = "Other"

    var icon: String {
        switch self {
        case .vacation: return "airplane"
        case .sick: return "cross.case.fill"
        case .personal: return "person.fill"
        case .continuing_education: return "book.fill"
        case .unpaid: return "dollarsign.circle"
        case .other: return "calendar"
        }
    }
}

enum RequestStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case denied = "Denied"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .denied: return "red"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Room/Resource Management

struct TreatmentRoom: Identifiable, Codable {
    let id: UUID
    var name: String
    var roomNumber: String
    var capacity: Int
    var equipment: [String]
    var features: [String]
    var isActive: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        roomNumber: String = "",
        capacity: Int = 1,
        equipment: [String] = [],
        features: [String] = [],
        isActive: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.roomNumber = roomNumber
        self.capacity = capacity
        self.equipment = equipment
        self.features = features
        self.isActive = isActive
        self.notes = notes
    }
}

struct RoomAssignment: Identifiable, Codable {
    let id: UUID
    let staffId: UUID
    let roomId: UUID
    var isPrimary: Bool
    var startDate: Date
    var endDate: Date?
    var notes: String

    init(
        id: UUID = UUID(),
        staffId: UUID,
        roomId: UUID,
        isPrimary: Bool = false,
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.staffId = staffId
        self.roomId = roomId
        self.isPrimary = isPrimary
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }

    var isActive: Bool {
        if let end = endDate {
            return Date() < end
        }
        return true
    }
}

// MARK: - Staff Schedule

struct StaffScheduleEntry: Identifiable, Codable {
    let id: UUID
    let staffId: UUID
    let date: Date
    var startTime: Date
    var endTime: Date
    var isAvailable: Bool
    var breakStart: Date?
    var breakEnd: Date?
    var notes: String

    init(
        id: UUID = UUID(),
        staffId: UUID,
        date: Date,
        startTime: Date,
        endTime: Date,
        isAvailable: Bool = true,
        breakStart: Date? = nil,
        breakEnd: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.staffId = staffId
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
        self.breakStart = breakStart
        self.breakEnd = breakEnd
        self.notes = notes
    }

    var totalHours: Double {
        let totalMinutes = endTime.timeIntervalSince(startTime) / 60
        var breakMinutes: Double = 0
        if let breakStart = breakStart, let breakEnd = breakEnd {
            breakMinutes = breakEnd.timeIntervalSince(breakStart) / 60
        }
        return (totalMinutes - breakMinutes) / 60
    }
}

// MARK: - Team Statistics

struct TeamStatistics {
    let totalStaff: Int
    let activeStaff: Int
    let therapistCount: Int
    let supportStaffCount: Int
    let pendingTimeOffRequests: Int
    let expiringLicenses: Int
    let totalHoursScheduled: Double
    let averagePerformanceRating: Double
    let totalTeamRevenue: Double

    init(
        totalStaff: Int = 0,
        activeStaff: Int = 0,
        therapistCount: Int = 0,
        supportStaffCount: Int = 0,
        pendingTimeOffRequests: Int = 0,
        expiringLicenses: Int = 0,
        totalHoursScheduled: Double = 0,
        averagePerformanceRating: Double = 0,
        totalTeamRevenue: Double = 0
    ) {
        self.totalStaff = totalStaff
        self.activeStaff = activeStaff
        self.therapistCount = therapistCount
        self.supportStaffCount = supportStaffCount
        self.pendingTimeOffRequests = pendingTimeOffRequests
        self.expiringLicenses = expiringLicenses
        self.totalHoursScheduled = totalHoursScheduled
        self.averagePerformanceRating = averagePerformanceRating
        self.totalTeamRevenue = totalTeamRevenue
    }
}

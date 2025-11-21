import Foundation

/// Staff member (therapist, receptionist, manager) model
struct StaffMember: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    let role: StaffRole
    var credentials: [String]
    var licenseNumber: String?
    var licenseExpiration: Date?
    var specialties: [String]
    var availability: StaffAvailability
    var compensation: StaffCompensation
    var startDate: Date
    var endDate: Date?
    var status: EmploymentStatus
    var profilePhoto: Data?
    var bio: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        role: StaffRole,
        credentials: [String] = [],
        licenseNumber: String? = nil,
        licenseExpiration: Date? = nil,
        specialties: [String] = [],
        availability: StaffAvailability = StaffAvailability(),
        compensation: StaffCompensation,
        startDate: Date = Date(),
        endDate: Date? = nil,
        status: EmploymentStatus = .active,
        profilePhoto: Data? = nil,
        bio: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.role = role
        self.credentials = credentials
        self.licenseNumber = licenseNumber
        self.licenseExpiration = licenseExpiration
        self.specialties = specialties
        self.availability = availability
        self.compensation = compensation
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.profilePhoto = profilePhoto
        self.bio = bio
        self.notes = notes
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var credentialsString: String {
        credentials.joined(separator: ", ")
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
}

// MARK: - Staff Role

enum StaffRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case manager = "Practice Manager"
    case therapist = "Massage Therapist"
    case leadTherapist = "Lead Therapist"
    case receptionist = "Receptionist"
    case bookkeeper = "Bookkeeper"
    case marketingCoordinator = "Marketing Coordinator"
    case intern = "Intern"
    case contractor = "Independent Contractor"

    var permissions: [Permission] {
        switch self {
        case .owner:
            return Permission.allCases
        case .manager:
            return [
                .viewAllClients, .editClients, .viewSchedule, .editSchedule,
                .viewAppointments, .editAppointments, .viewPayments, .processPayments,
                .viewReports, .viewStaff, .editStaff, .manageInventory,
                .sendCommunications, .accessSettings
            ]
        case .therapist, .leadTherapist:
            return [
                .viewOwnClients, .editOwnClients, .viewOwnSchedule, .editOwnSchedule,
                .viewOwnAppointments, .editOwnAppointments, .createSOAPNotes,
                .viewOwnPayments, .accessTreatmentTools
            ]
        case .receptionist:
            return [
                .viewAllClients, .editClients, .viewSchedule, .editSchedule,
                .viewAppointments, .editAppointments, .processPayments, .sendCommunications
            ]
        case .bookkeeper:
            return [
                .viewPayments, .processPayments, .viewReports, .manageExpenses
            ]
        case .marketingCoordinator:
            return [
                .viewAllClients, .sendCommunications, .viewReports, .manageCampaigns
            ]
        case .intern:
            return [
                .viewOwnClients, .viewOwnSchedule, .viewOwnAppointments, .createSOAPNotes
            ]
        case .contractor:
            return [
                .viewOwnClients, .editOwnClients, .viewOwnSchedule, .editOwnSchedule,
                .viewOwnAppointments, .editOwnAppointments, .createSOAPNotes, .viewOwnPayments
            ]
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .manager: return "person.crop.circle.badge.checkmark"
        case .therapist: return "hand.raised.fill"
        case .leadTherapist: return "star.fill"
        case .receptionist: return "person.crop.circle"
        case .bookkeeper: return "dollarsign.circle.fill"
        case .marketingCoordinator: return "megaphone.fill"
        case .intern: return "graduationcap.fill"
        case .contractor: return "briefcase.fill"
        }
    }

    var color: String {
        switch self {
        case .owner: return "purple"
        case .manager: return "blue"
        case .therapist, .leadTherapist: return "green"
        case .receptionist: return "orange"
        case .bookkeeper: return "teal"
        case .marketingCoordinator: return "pink"
        case .intern: return "yellow"
        case .contractor: return "indigo"
        }
    }
}

// MARK: - Permissions

enum Permission: String, Codable, CaseIterable {
    case viewAllClients = "View All Clients"
    case viewOwnClients = "View Own Clients"
    case editClients = "Edit Clients"
    case editOwnClients = "Edit Own Clients"
    case viewSchedule = "View Schedule"
    case viewOwnSchedule = "View Own Schedule"
    case editSchedule = "Edit Schedule"
    case editOwnSchedule = "Edit Own Schedule"
    case viewAppointments = "View Appointments"
    case viewOwnAppointments = "View Own Appointments"
    case editAppointments = "Edit Appointments"
    case editOwnAppointments = "Edit Own Appointments"
    case createSOAPNotes = "Create SOAP Notes"
    case viewPayments = "View Payments"
    case viewOwnPayments = "View Own Payments"
    case processPayments = "Process Payments"
    case manageExpenses = "Manage Expenses"
    case viewReports = "View Reports"
    case viewStaff = "View Staff"
    case editStaff = "Edit Staff"
    case manageInventory = "Manage Inventory"
    case sendCommunications = "Send Communications"
    case manageCampaigns = "Manage Campaigns"
    case accessSettings = "Access Settings"
    case accessTreatmentTools = "Access Treatment Tools"
}

// MARK: - Employment Status

enum EmploymentStatus: String, Codable {
    case active = "Active"
    case onLeave = "On Leave"
    case suspended = "Suspended"
    case terminated = "Terminated"

    var color: String {
        switch self {
        case .active: return "green"
        case .onLeave: return "yellow"
        case .suspended: return "orange"
        case .terminated: return "red"
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .onLeave: return "pause.circle.fill"
        case .suspended: return "exclamationmark.triangle.fill"
        case .terminated: return "xmark.circle.fill"
        }
    }
}

// MARK: - Staff Availability

struct StaffAvailability: Codable {
    var weeklySchedule: [Int: [TimeBlock]] // Day of week (1-7) to time blocks
    var exceptions: [AvailabilityException] // Holidays, time off, etc.
    var maxAppointmentsPerDay: Int?
    var bufferTimeBetweenAppointments: TimeInterval // in seconds

    init(
        weeklySchedule: [Int: [TimeBlock]] = [:],
        exceptions: [AvailabilityException] = [],
        maxAppointmentsPerDay: Int? = nil,
        bufferTimeBetweenAppointments: TimeInterval = 900 // 15 minutes
    ) {
        self.weeklySchedule = weeklySchedule
        self.exceptions = exceptions
        self.maxAppointmentsPerDay = maxAppointmentsPerDay
        self.bufferTimeBetweenAppointments = bufferTimeBetweenAppointments
    }

    struct TimeBlock: Codable, Identifiable {
        let id: UUID
        let startTime: Date // Time component only
        let endTime: Date
        let availabilityType: AvailabilityType

        init(
            id: UUID = UUID(),
            startTime: Date,
            endTime: Date,
            availabilityType: AvailabilityType = .available
        ) {
            self.id = id
            self.startTime = startTime
            self.endTime = endTime
            self.availabilityType = availabilityType
        }

        enum AvailabilityType: String, Codable {
            case available = "Available"
            case preferredHours = "Preferred Hours"
            case limitedAvailability = "Limited Availability"
        }
    }

    struct AvailabilityException: Codable, Identifiable {
        let id: UUID
        let startDate: Date
        let endDate: Date
        let reason: ExceptionReason
        let notes: String?

        init(
            id: UUID = UUID(),
            startDate: Date,
            endDate: Date,
            reason: ExceptionReason,
            notes: String? = nil
        ) {
            self.id = id
            self.startDate = startDate
            self.endDate = endDate
            self.reason = reason
            self.notes = notes
        }

        enum ExceptionReason: String, Codable {
            case vacation = "Vacation"
            case sickLeave = "Sick Leave"
            case personalDay = "Personal Day"
            case training = "Training/Conference"
            case holiday = "Holiday"
            case other = "Other"
        }
    }

    /// Check if staff member is available at a specific time
    func isAvailable(at date: Date) -> Bool {
        // Check exceptions first
        for exception in exceptions {
            if date >= exception.startDate && date <= exception.endDate {
                return false
            }
        }

        // Check weekly schedule
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        guard let blocks = weeklySchedule[dayOfWeek] else { return false }

        let timeOfDay = calendar.date(from: calendar.dateComponents([.hour, .minute], from: date))!

        for block in blocks {
            let blockStart = calendar.date(from: calendar.dateComponents([.hour, .minute], from: block.startTime))!
            let blockEnd = calendar.date(from: calendar.dateComponents([.hour, .minute], from: block.endTime))!

            if timeOfDay >= blockStart && timeOfDay <= blockEnd {
                return true
            }
        }

        return false
    }
}

// MARK: - Staff Compensation

struct StaffCompensation: Codable {
    let compensationType: CompensationType
    let payRate: Double
    let commissionRate: Double? // For service-based commission
    let benefits: [Benefit]
    let paySchedule: PaySchedule

    enum CompensationType: String, Codable {
        case hourly = "Hourly"
        case salary = "Salary"
        case commission = "Commission Only"
        case hourlyPlusCommission = "Hourly + Commission"
        case perService = "Per Service"
    }

    enum PaySchedule: String, Codable {
        case weekly = "Weekly"
        case biweekly = "Bi-Weekly"
        case semimonthly = "Semi-Monthly"
        case monthly = "Monthly"
    }

    struct Benefit: Codable, Identifiable {
        let id: UUID
        let name: String
        let description: String
        let value: Double?

        init(
            id: UUID = UUID(),
            name: String,
            description: String,
            value: Double? = nil
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.value = value
        }
    }

    init(
        compensationType: CompensationType,
        payRate: Double,
        commissionRate: Double? = nil,
        benefits: [Benefit] = [],
        paySchedule: PaySchedule = .biweekly
    ) {
        self.compensationType = compensationType
        self.payRate = payRate
        self.commissionRate = commissionRate
        self.benefits = benefits
        self.paySchedule = paySchedule
    }
}

// MARK: - Staff Performance

struct StaffPerformance: Codable {
    let staffId: UUID
    let periodStart: Date
    let periodEnd: Date
    var appointmentsCompleted: Int
    var clientSatisfactionScore: Double
    var revenue Generated: Double
    var hoursWorked: Double
    var noShows: Int
    var cancellations: Int
    var lateArrivals: Int
    var newClientsAcquired: Int
    var productsSold: Int

    var averageRevenuePerHour: Double {
        guard hoursWorked > 0 else { return 0 }
        return revenueGenerated / hoursWorked
    }

    var completionRate: Double {
        let total = Double(appointmentsCompleted + noShows + cancellations)
        guard total > 0 else { return 0 }
        return Double(appointmentsCompleted) / total
    }

    init(
        staffId: UUID,
        periodStart: Date,
        periodEnd: Date,
        appointmentsCompleted: Int = 0,
        clientSatisfactionScore: Double = 0.0,
        revenueGenerated: Double = 0.0,
        hoursWorked: Double = 0.0,
        noShows: Int = 0,
        cancellations: Int = 0,
        lateArrivals: Int = 0,
        newClientsAcquired: Int = 0,
        productsSold: Int = 0
    ) {
        self.staffId = staffId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.appointmentsCompleted = appointmentsCompleted
        self.clientSatisfactionScore = clientSatisfactionScore
        self.revenueGenerated = revenueGenerated
        self.hoursWorked = hoursWorked
        self.noShows = noShows
        self.cancellations = cancellations
        self.lateArrivals = lateArrivals
        self.newClientsAcquired = newClientsAcquired
        self.productsSold = productsSold
    }
}

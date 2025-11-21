import Foundation

/// Client portal and online booking models

// MARK: - Client Portal Account

struct ClientPortalAccount: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var email: String
    var passwordHash: String
    var isActive: Bool
    var isEmailVerified: Bool
    var createdDate: Date
    var lastLoginDate: Date?
    var settings: PortalSettings
    var accessLevel: AccessLevel
    var twoFactorEnabled: Bool

    init(
        id: UUID = UUID(),
        clientId: UUID,
        email: String,
        passwordHash: String,
        isActive: Bool = true,
        isEmailVerified: Bool = false,
        createdDate: Date = Date(),
        lastLoginDate: Date? = nil,
        settings: PortalSettings = PortalSettings(),
        accessLevel: AccessLevel = .full,
        twoFactorEnabled: Bool = false
    ) {
        self.id = id
        self.clientId = clientId
        self.email = email
        self.passwordHash = passwordHash
        self.isActive = isActive
        self.isEmailVerified = isEmailVerified
        self.createdDate = createdDate
        self.lastLoginDate = lastLoginDate
        self.settings = settings
        self.accessLevel = accessLevel
        self.twoFactorEnabled = twoFactorEnabled
    }
}

enum AccessLevel: String, Codable {
    case full = "Full Access"
    case limited = "Limited Access"
    case bookingOnly = "Booking Only"
    case viewOnly = "View Only"
}

struct PortalSettings: Codable {
    var emailNotifications: Bool
    var smsNotifications: Bool
    var marketingEmails: Bool
    var appointmentReminders: Bool
    var bookingConfirmations: Bool
    var theme: PortalTheme

    init(
        emailNotifications: Bool = true,
        smsNotifications: Bool = true,
        marketingEmails: Bool = true,
        appointmentReminders: Bool = true,
        bookingConfirmations: Bool = true,
        theme: PortalTheme = .calming
    ) {
        self.emailNotifications = emailNotifications
        self.smsNotifications = smsNotifications
        self.marketingEmails = marketingEmails
        self.appointmentReminders = appointmentReminders
        self.bookingConfirmations = bookingConfirmations
        self.theme = theme
    }
}

enum PortalTheme: String, Codable {
    case calming = "Calming"
    case professional = "Professional"
    case warm = "Warm"
}

// MARK: - Portal Session

struct ClientPortalSession: Identifiable, Codable {
    let id: UUID
    let accountId: UUID
    let clientId: UUID
    var sessionToken: String
    var deviceInfo: String
    var ipAddress: String
    var startDate: Date
    var lastActivityDate: Date
    var expirationDate: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        accountId: UUID,
        clientId: UUID,
        sessionToken: String,
        deviceInfo: String = "",
        ipAddress: String = "",
        startDate: Date = Date(),
        lastActivityDate: Date = Date(),
        expirationDate: Date = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!,
        isActive: Bool = true
    ) {
        self.id = id
        self.accountId = accountId
        self.clientId = clientId
        self.sessionToken = sessionToken
        self.deviceInfo = deviceInfo
        self.ipAddress = ipAddress
        self.startDate = startDate
        self.lastActivityDate = lastActivityDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }

    var isExpired: Bool {
        Date() > expirationDate
    }
}

// MARK: - Online Booking Request

struct OnlineBookingRequest: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var serviceId: UUID
    var serviceName: String
    var therapistId: UUID?
    var therapistName: String?
    var preferredDate: Date
    var preferredTime: Date
    var duration: TimeInterval
    var status: BookingRequestStatus
    var notes: String
    var createdDate: Date
    var processedDate: Date?
    var processedBy: UUID?
    var appointmentId: UUID?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        serviceId: UUID,
        serviceName: String,
        therapistId: UUID? = nil,
        therapistName: String? = nil,
        preferredDate: Date,
        preferredTime: Date,
        duration: TimeInterval,
        status: BookingRequestStatus = .pending,
        notes: String = "",
        createdDate: Date = Date(),
        processedDate: Date? = nil,
        processedBy: UUID? = nil,
        appointmentId: UUID? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.therapistId = therapistId
        self.therapistName = therapistName
        self.preferredDate = preferredDate
        self.preferredTime = preferredTime
        self.duration = duration
        self.status = status
        self.notes = notes
        self.createdDate = createdDate
        self.processedDate = processedDate
        self.processedBy = processedBy
        self.appointmentId = appointmentId
    }

    var isPending: Bool {
        status == .pending
    }
}

enum BookingRequestStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case declined = "Declined"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "green"
        case .declined: return "red"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Booking Availability

struct BookingAvailability: Codable {
    let date: Date
    let therapistId: UUID?
    let availableSlots: [TimeSlot]

    init(date: Date, therapistId: UUID? = nil, availableSlots: [TimeSlot] = []) {
        self.date = date
        self.therapistId = therapistId
        self.availableSlots = availableSlots
    }
}

struct TimeSlot: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    var isAvailable: Bool

    init(id: UUID = UUID(), startTime: Date, endTime: Date, isAvailable: Bool = true) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Client Notifications

struct ClientNotification: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var notificationType: NotificationType
    var title: String
    var message: String
    var createdDate: Date
    var isRead: Bool
    var actionUrl: String?
    var expirationDate: Date?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        notificationType: NotificationType,
        title: String,
        message: String,
        createdDate: Date = Date(),
        isRead: Bool = false,
        actionUrl: String? = nil,
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.notificationType = notificationType
        self.title = title
        self.message = message
        self.createdDate = createdDate
        self.isRead = isRead
        self.actionUrl = actionUrl
        self.expirationDate = expirationDate
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }
}

enum NotificationType: String, Codable {
    case appointmentConfirmed = "Appointment Confirmed"
    case appointmentReminder = "Appointment Reminder"
    case appointmentCancelled = "Appointment Cancelled"
    case appointmentRescheduled = "Appointment Rescheduled"
    case paymentReceived = "Payment Received"
    case formRequired = "Form Required"
    case promotionalOffer = "Promotional Offer"
    case systemAnnouncement = "System Announcement"

    var icon: String {
        switch self {
        case .appointmentConfirmed: return "checkmark.circle.fill"
        case .appointmentReminder: return "bell.fill"
        case .appointmentCancelled: return "xmark.circle.fill"
        case .appointmentRescheduled: return "arrow.triangle.2.circlepath"
        case .paymentReceived: return "dollarsign.circle.fill"
        case .formRequired: return "doc.text.fill"
        case .promotionalOffer: return "tag.fill"
        case .systemAnnouncement: return "megaphone.fill"
        }
    }

    var color: String {
        switch self {
        case .appointmentConfirmed: return "green"
        case .appointmentReminder: return "blue"
        case .appointmentCancelled: return "red"
        case .appointmentRescheduled: return "orange"
        case .paymentReceived: return "green"
        case .formRequired: return "orange"
        case .promotionalOffer: return "purple"
        case .systemAnnouncement: return "blue"
        }
    }
}

// MARK: - Client Documents

struct ClientDocument: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var documentType: DocumentType
    var title: String
    var description: String
    var fileUrl: String
    var uploadDate: Date
    var expirationDate: Date?
    var isSharedWithClient: Bool
    var requiresSignature: Bool
    var signedDate: Date?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        documentType: DocumentType,
        title: String,
        description: String = "",
        fileUrl: String,
        uploadDate: Date = Date(),
        expirationDate: Date? = nil,
        isSharedWithClient: Bool = false,
        requiresSignature: Bool = false,
        signedDate: Date? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.documentType = documentType
        self.title = title
        self.description = description
        self.fileUrl = fileUrl
        self.uploadDate = uploadDate
        self.expirationDate = expirationDate
        self.isSharedWithClient = isSharedWithClient
        self.requiresSignature = requiresSignature
        self.signedDate = signedDate
    }

    var isSigned: Bool {
        signedDate != nil
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case consentForm = "Consent Form"
    case intakeForm = "Intake Form"
    case medicalHistory = "Medical History"
    case treatmentPlan = "Treatment Plan"
    case invoice = "Invoice"
    case receipt = "Receipt"
    case insurance = "Insurance Document"
    case other = "Other"

    var icon: String {
        switch self {
        case .consentForm: return "checkmark.seal.fill"
        case .intakeForm: return "list.clipboard.fill"
        case .medicalHistory: return "cross.case.fill"
        case .treatmentPlan: return "doc.text.fill"
        case .invoice: return "doc.plaintext.fill"
        case .receipt: return "receipt.fill"
        case .insurance: return "cross.fill"
        case .other: return "doc.fill"
        }
    }
}

// MARK: - Client Packages

struct ClientPackage: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var packageName: String
    var packageType: PackageType
    var totalSessions: Int
    var remainingSessions: Int
    var purchaseDate: Date
    var expirationDate: Date?
    var price: Double
    var discountPercentage: Double
    var services: [UUID] // Service IDs included
    var isActive: Bool

    init(
        id: UUID = UUID(),
        clientId: UUID,
        packageName: String,
        packageType: PackageType,
        totalSessions: Int,
        remainingSessions: Int,
        purchaseDate: Date = Date(),
        expirationDate: Date? = nil,
        price: Double,
        discountPercentage: Double = 0,
        services: [UUID] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.clientId = clientId
        self.packageName = packageName
        self.packageType = packageType
        self.totalSessions = totalSessions
        self.remainingSessions = remainingSessions
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.price = price
        self.discountPercentage = discountPercentage
        self.services = services
        self.isActive = isActive
    }

    var usedSessions: Int {
        totalSessions - remainingSessions
    }

    var progressPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(usedSessions) / Double(totalSessions) * 100
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }

    var isExpiringSoon: Bool {
        guard let expiration = expirationDate else { return false }
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return daysUntilExpiration <= 30 && daysUntilExpiration > 0
    }
}

enum PackageType: String, Codable, CaseIterable {
    case sessionPackage = "Session Package"
    case membership = "Membership"
    case unlimited = "Unlimited"

    var icon: String {
        switch self {
        case .sessionPackage: return "square.stack.fill"
        case .membership: return "crown.fill"
        case .unlimited: return "infinity"
        }
    }
}

// MARK: - Client Referrals

struct ClientReferral: Identifiable, Codable {
    let id: UUID
    let referrerId: UUID // Client who made the referral
    let referredClientId: UUID? // New client (nil if not converted yet)
    var referredName: String
    var referredEmail: String
    var referredPhone: String
    var status: ReferralStatus
    var referralDate: Date
    var convertedDate: Date?
    var rewardType: ReferralRewardType
    var rewardAmount: Double
    var rewardIssued: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        referrerId: UUID,
        referredClientId: UUID? = nil,
        referredName: String,
        referredEmail: String,
        referredPhone: String = "",
        status: ReferralStatus = .pending,
        referralDate: Date = Date(),
        convertedDate: Date? = nil,
        rewardType: ReferralRewardType = .discount,
        rewardAmount: Double = 0,
        rewardIssued: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.referrerId = referrerId
        self.referredClientId = referredClientId
        self.referredName = referredName
        self.referredEmail = referredEmail
        self.referredPhone = referredPhone
        self.status = status
        self.referralDate = referralDate
        self.convertedDate = convertedDate
        self.rewardType = rewardType
        self.rewardAmount = rewardAmount
        self.rewardIssued = rewardIssued
        self.notes = notes
    }
}

enum ReferralStatus: String, Codable {
    case pending = "Pending"
    case contacted = "Contacted"
    case converted = "Converted"
    case declined = "Declined"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .contacted: return "blue"
        case .converted: return "green"
        case .declined: return "gray"
        }
    }
}

enum ReferralRewardType: String, Codable, CaseIterable {
    case discount = "Discount"
    case credit = "Account Credit"
    case freeService = "Free Service"
    case giftCard = "Gift Card"

    var icon: String {
        switch self {
        case .discount: return "percent"
        case .credit: return "dollarsign.circle.fill"
        case .freeService: return "gift.fill"
        case .giftCard: return "giftcard.fill"
        }
    }
}

// MARK: - Portal Statistics

struct ClientPortalStatistics {
    let totalAccounts: Int
    let activeAccounts: Int
    let totalSessions: Int
    let activeSessions: Int
    let onlineBookings: Int
    let pendingBookings: Int
    let formCompletions: Int
    let averageSessionDuration: TimeInterval

    init(
        totalAccounts: Int = 0,
        activeAccounts: Int = 0,
        totalSessions: Int = 0,
        activeSessions: Int = 0,
        onlineBookings: Int = 0,
        pendingBookings: Int = 0,
        formCompletions: Int = 0,
        averageSessionDuration: TimeInterval = 0
    ) {
        self.totalAccounts = totalAccounts
        self.activeAccounts = activeAccounts
        self.totalSessions = totalSessions
        self.activeSessions = activeSessions
        self.onlineBookings = onlineBookings
        self.pendingBookings = pendingBookings
        self.formCompletions = formCompletions
        self.averageSessionDuration = averageSessionDuration
    }

    var accountActivationRate: Double {
        guard totalAccounts > 0 else { return 0 }
        return Double(activeAccounts) / Double(totalAccounts) * 100
    }
}

// MARK: - Client Portal Configuration

struct ClientPortalConfiguration: Codable {
    var isEnabled: Bool
    var allowSelfRegistration: Bool
    var requireEmailVerification: Bool
    var allowOnlineBooking: Bool
    var allowCancellations: Bool
    var cancellationHoursNotice: Int
    var allowRescheduling: Bool
    var showPricing: Bool
    var showTherapistProfiles: Bool
    var bookingAdvanceDays: Int // How far in advance clients can book
    var customWelcomeMessage: String
    var customBookingInstructions: String

    init(
        isEnabled: Bool = true,
        allowSelfRegistration: Bool = true,
        requireEmailVerification: Bool = true,
        allowOnlineBooking: Bool = true,
        allowCancellations: Bool = true,
        cancellationHoursNotice: Int = 24,
        allowRescheduling: Bool = true,
        showPricing: Bool = true,
        showTherapistProfiles: Bool = true,
        bookingAdvanceDays: Int = 30,
        customWelcomeMessage: String = "",
        customBookingInstructions: String = ""
    ) {
        self.isEnabled = isEnabled
        self.allowSelfRegistration = allowSelfRegistration
        self.requireEmailVerification = requireEmailVerification
        self.allowOnlineBooking = allowOnlineBooking
        self.allowCancellations = allowCancellations
        self.cancellationHoursNotice = cancellationHoursNotice
        self.allowRescheduling = allowRescheduling
        self.showPricing = showPricing
        self.showTherapistProfiles = showTherapistProfiles
        self.bookingAdvanceDays = bookingAdvanceDays
        self.customWelcomeMessage = customWelcomeMessage
        self.customBookingInstructions = customBookingInstructions
    }
}

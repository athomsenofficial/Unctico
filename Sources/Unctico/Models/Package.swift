import Foundation

/// Service packages and memberships for clients
struct Package: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    let packageType: PackageType
    var services: [PackageService]
    var pricing: PackagePricing
    var validity: PackageValidity
    var restrictions: PackageRestrictions?
    var isActive: Bool
    var createdDate: Date
    var modifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        packageType: PackageType,
        services: [PackageService],
        pricing: PackagePricing,
        validity: PackageValidity,
        restrictions: PackageRestrictions? = nil,
        isActive: Bool = true,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.packageType = packageType
        self.services = services
        self.pricing = pricing
        self.validity = validity
        self.restrictions = restrictions
        self.isActive = isActive
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

// MARK: - Package Types

enum PackageType: String, Codable, CaseIterable {
    case sessionPackage = "Session Package"
    case membership = "Monthly Membership"
    case classPass = "Class Pass"
    case giftCertificate = "Gift Certificate"
    case introductoryOffer = "Introductory Offer"
    case corporatePackage = "Corporate Package"

    var icon: String {
        switch self {
        case .sessionPackage: return "square.stack.3d.up.fill"
        case .membership: return "star.circle.fill"
        case .classPass: return "ticket.fill"
        case .giftCertificate: return "gift.fill"
        case .introductoryOffer: return "sparkles"
        case .corporatePackage: return "building.2.fill"
        }
    }

    var color: String {
        switch self {
        case .sessionPackage: return "blue"
        case .membership: return "purple"
        case .classPass: return "orange"
        case .giftCertificate: return "pink"
        case .introductoryOffer: return "green"
        case .corporatePackage: return "indigo"
        }
    }
}

// MARK: - Package Service

struct PackageService: Identifiable, Codable {
    let id: UUID
    let serviceName: String
    let serviceDuration: TimeInterval // in seconds
    let quantity: Int // Number of sessions included
    let allowedTherapists: [String]? // nil = all therapists allowed

    init(
        id: UUID = UUID(),
        serviceName: String,
        serviceDuration: TimeInterval,
        quantity: Int,
        allowedTherapists: [String]? = nil
    ) {
        self.id = id
        self.serviceName = serviceName
        self.serviceDuration = serviceDuration
        self.quantity = quantity
        self.allowedTherapists = allowedTherapists
    }

    var formattedDuration: String {
        let minutes = Int(serviceDuration) / 60
        return "\(minutes) min"
    }
}

// MARK: - Package Pricing

struct PackagePricing: Codable {
    let totalPrice: Double
    let retailValue: Double // Original value if purchased individually
    let paymentOptions: [PaymentOption]
    let taxable: Bool
    let refundable: Bool

    var savings: Double {
        retailValue - totalPrice
    }

    var savingsPercentage: Double {
        guard retailValue > 0 else { return 0 }
        return (savings / retailValue) * 100
    }

    enum PaymentOption: String, Codable {
        case fullPaymentUpfront = "Full Payment Upfront"
        case monthlyInstallments = "Monthly Installments"
        case perSession = "Pay Per Session"
        case autoRenewal = "Auto-Renewal"
    }

    init(
        totalPrice: Double,
        retailValue: Double,
        paymentOptions: [PaymentOption] = [.fullPaymentUpfront],
        taxable: Bool = true,
        refundable: Bool = false
    ) {
        self.totalPrice = totalPrice
        self.retailValue = retailValue
        self.paymentOptions = paymentOptions
        self.taxable = taxable
        self.refundable = refundable
    }
}

// MARK: - Package Validity

struct PackageValidity: Codable {
    let validityType: ValidityType
    let validityValue: Int // Days, months, or sessions depending on type
    let expirationPolicy: ExpirationPolicy
    let transferable: Bool
    let shareable: Bool // Can be used by family members

    enum ValidityType: String, Codable {
        case days = "Days"
        case months = "Months"
        case year = "Year"
        case unlimited = "Unlimited"
        case untilUsed = "Until Sessions Used"
    }

    enum ExpirationPolicy: String, Codable {
        case strict = "No Extensions"
        case grace = "7-Day Grace Period"
        case flexible = "Flexible Extension"
        case noExpiration = "No Expiration"
    }

    init(
        validityType: ValidityType,
        validityValue: Int,
        expirationPolicy: ExpirationPolicy = .strict,
        transferable: Bool = false,
        shareable: Bool = false
    ) {
        self.validityType = validityType
        self.validityValue = validityValue
        self.expirationPolicy = expirationPolicy
        self.transferable = transferable
        self.shareable = shareable
    }

    var description: String {
        switch validityType {
        case .days:
            return "\(validityValue) days from purchase"
        case .months:
            return "\(validityValue) months from purchase"
        case .year:
            return "1 year from purchase"
        case .unlimited:
            return "No expiration"
        case .untilUsed:
            return "Until all sessions are used"
        }
    }
}

// MARK: - Package Restrictions

struct PackageRestrictions: Codable {
    let minimumAdvanceBooking: Int? // Hours
    let maximumAdvanceBooking: Int? // Days
    let blockoutDates: [Date]
    let allowedDaysOfWeek: [Int]? // 1-7, nil = all days
    let allowedTimeSlots: [TimeSlot]?
    let maxSessionsPerWeek: Int?
    let maxSessionsPerMonth: Int?
    let requiresMembership: Bool
    let newClientsOnly: Bool

    struct TimeSlot: Codable {
        let startTime: Date
        let endTime: Date
    }

    init(
        minimumAdvanceBooking: Int? = nil,
        maximumAdvanceBooking: Int? = nil,
        blockoutDates: [Date] = [],
        allowedDaysOfWeek: [Int]? = nil,
        allowedTimeSlots: [TimeSlot]? = nil,
        maxSessionsPerWeek: Int? = nil,
        maxSessionsPerMonth: Int? = nil,
        requiresMembership: Bool = false,
        newClientsOnly: Bool = false
    ) {
        self.minimumAdvanceBooking = minimumAdvanceBooking
        self.maximumAdvanceBooking = maximumAdvanceBooking
        self.blockoutDates = blockoutDates
        self.allowedDaysOfWeek = allowedDaysOfWeek
        self.allowedTimeSlots = allowedTimeSlots
        self.maxSessionsPerWeek = maxSessionsPerWeek
        self.maxSessionsPerMonth = maxSessionsPerMonth
        self.requiresMembership = requiresMembership
        self.newClientsOnly = newClientsOnly
    }
}

// MARK: - Client Package Purchase

struct ClientPackagePurchase: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let packageId: UUID
    let packageName: String
    let purchaseDate: Date
    let expirationDate: Date?
    let purchasePrice: Double
    let paymentMethod: String
    var remainingSessions: [RemainingSession]
    var status: PurchaseStatus
    var autoRenew: Bool
    var notes: String?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        packageId: UUID,
        packageName: String,
        purchaseDate: Date = Date(),
        expirationDate: Date?,
        purchasePrice: Double,
        paymentMethod: String,
        remainingSessions: [RemainingSession],
        status: PurchaseStatus = .active,
        autoRenew: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.packageId = packageId
        self.packageName = packageName
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.purchasePrice = purchasePrice
        self.paymentMethod = paymentMethod
        self.remainingSessions = remainingSessions
        self.status = status
        self.autoRenew = autoRenew
        self.notes = notes
    }

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }

    var totalSessionsUsed: Int {
        remainingSessions.reduce(0) { $0 + $1.used }
    }

    var totalSessionsRemaining: Int {
        remainingSessions.reduce(0) { $0 + ($1.total - $1.used) }
    }

    var utilizationRate: Double {
        let total = remainingSessions.reduce(0) { $0 + $1.total }
        guard total > 0 else { return 0 }
        return Double(totalSessionsUsed) / Double(total)
    }
}

struct RemainingSession: Identifiable, Codable {
    let id: UUID
    let serviceName: String
    let total: Int
    var used: Int

    init(
        id: UUID = UUID(),
        serviceName: String,
        total: Int,
        used: Int = 0
    ) {
        self.id = id
        self.serviceName = serviceName
        self.total = total
        self.used = used
    }

    var remaining: Int {
        total - used
    }
}

enum PurchaseStatus: String, Codable {
    case active = "Active"
    case expired = "Expired"
    case exhausted = "Exhausted"
    case suspended = "Suspended"
    case cancelled = "Cancelled"
    case refunded = "Refunded"

    var color: String {
        switch self {
        case .active: return "green"
        case .expired: return "orange"
        case .exhausted: return "gray"
        case .suspended: return "yellow"
        case .cancelled: return "red"
        case .refunded: return "purple"
        }
    }

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .expired: return "clock.fill"
        case .exhausted: return "slash.circle.fill"
        case .suspended: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .refunded: return "arrow.uturn.left.circle.fill"
        }
    }
}

// MARK: - Pre-Built Package Templates

extension Package {
    static let packageTemplates: [Package] = [
        // Session Packages
        Package(
            name: "5-Session Package",
            description: "Five 60-minute massage sessions. Save 10% compared to individual pricing.",
            packageType: .sessionPackage,
            services: [
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 5
                )
            ],
            pricing: PackagePricing(
                totalPrice: 450.0,
                retailValue: 500.0
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 6
            )
        ),

        Package(
            name: "10-Session Wellness Package",
            description: "Ten 60-minute sessions. Save 15% and commit to your wellness journey.",
            packageType: .sessionPackage,
            services: [
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 10
                )
            ],
            pricing: PackagePricing(
                totalPrice: 850.0,
                retailValue: 1000.0
            ),
            validity: PackageValidity(
                validityType: .year,
                validityValue: 1
            )
        ),

        // Membership
        Package(
            name: "Monthly Wellness Membership",
            description: "One 60-minute massage per month plus 10% off additional services. Auto-renews monthly.",
            packageType: .membership,
            services: [
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 1
                )
            ],
            pricing: PackagePricing(
                totalPrice: 85.0,
                retailValue: 100.0,
                paymentOptions: [.autoRenewal]
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 1,
                expirationPolicy: .noExpiration
            ),
            restrictions: PackageRestrictions(
                maxSessionsPerMonth: 1
            )
        ),

        Package(
            name: "Premium Monthly Membership",
            description: "Two 60-minute massages per month plus 15% off all services and products.",
            packageType: .membership,
            services: [
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 2
                )
            ],
            pricing: PackagePricing(
                totalPrice: 160.0,
                retailValue: 200.0,
                paymentOptions: [.autoRenewal]
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 1,
                expirationPolicy: .noExpiration
            ),
            restrictions: PackageRestrictions(
                maxSessionsPerMonth: 2
            )
        ),

        // Introductory Offers
        Package(
            name: "New Client Special",
            description: "Three 60-minute sessions for first-time clients. Discover the benefits of regular massage.",
            packageType: .introductoryOffer,
            services: [
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 3
                )
            ],
            pricing: PackagePricing(
                totalPrice: 210.0,
                retailValue: 300.0
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 3
            ),
            restrictions: PackageRestrictions(
                newClientsOnly: true
            )
        ),

        // Class Pass
        Package(
            name: "Yoga & Massage Combo",
            description: "5 yoga classes plus 2 massage sessions. Perfect wellness combination.",
            packageType: .classPass,
            services: [
                PackageService(
                    serviceName: "Yoga Class",
                    serviceDuration: 3600,
                    quantity: 5
                ),
                PackageService(
                    serviceName: "60-min Massage",
                    serviceDuration: 3600,
                    quantity: 2
                )
            ],
            pricing: PackagePricing(
                totalPrice: 250.0,
                retailValue: 300.0
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 2
            )
        ),

        // Gift Certificate
        Package(
            name: "$100 Gift Certificate",
            description: "Perfect gift for any occasion. Can be used toward any service.",
            packageType: .giftCertificate,
            services: [
                PackageService(
                    serviceName: "Gift Certificate Value",
                    serviceDuration: 0,
                    quantity: 1
                )
            ],
            pricing: PackagePricing(
                totalPrice: 100.0,
                retailValue: 100.0,
                refundable: false
            ),
            validity: PackageValidity(
                validityType: .year,
                validityValue: 1,
                expirationPolicy: .grace,
                transferable: true,
                shareable: true
            )
        ),

        // Corporate Package
        Package(
            name: "Corporate Wellness Package",
            description: "10 employee massage sessions. Boost morale and productivity with workplace wellness.",
            packageType: .corporatePackage,
            services: [
                PackageService(
                    serviceName: "30-min Chair Massage",
                    serviceDuration: 1800,
                    quantity: 10
                )
            ],
            pricing: PackagePricing(
                totalPrice: 400.0,
                retailValue: 500.0
            ),
            validity: PackageValidity(
                validityType: .months,
                validityValue: 6,
                shareable: true
            )
        )
    ]

    /// Get template by type
    static func getTemplates(for type: PackageType) -> [Package] {
        return packageTemplates.filter { $0.packageType == type }
    }

    /// Search packages
    static func search(_ query: String) -> [Package] {
        let lowercased = query.lowercased()
        return packageTemplates.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }
}

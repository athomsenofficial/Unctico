import Foundation

/// Gift cards and promotional offers models

// MARK: - Gift Card

struct GiftCard: Identifiable, Codable {
    let id: UUID
    var code: String // Unique redemption code
    var purchaserId: UUID? // Client who purchased
    var recipientName: String
    var recipientEmail: String
    var recipientPhone: String
    var initialValue: Double
    var currentBalance: Double
    var purchaseDate: Date
    var activationDate: Date?
    var expirationDate: Date?
    var status: GiftCardStatus
    var message: String
    var design: GiftCardDesign
    var deliveryMethod: DeliveryMethod
    var deliveryDate: Date?
    var isReloadable: Bool
    var transactions: [GiftCardTransaction]

    init(
        id: UUID = UUID(),
        code: String,
        purchaserId: UUID? = nil,
        recipientName: String,
        recipientEmail: String,
        recipientPhone: String = "",
        initialValue: Double,
        currentBalance: Double? = nil,
        purchaseDate: Date = Date(),
        activationDate: Date? = nil,
        expirationDate: Date? = nil,
        status: GiftCardStatus = .pending,
        message: String = "",
        design: GiftCardDesign = .classic,
        deliveryMethod: DeliveryMethod = .email,
        deliveryDate: Date? = nil,
        isReloadable: Bool = false,
        transactions: [GiftCardTransaction] = []
    ) {
        self.id = id
        self.code = code
        self.purchaserId = purchaserId
        self.recipientName = recipientName
        self.recipientEmail = recipientEmail
        self.recipientPhone = recipientPhone
        self.initialValue = initialValue
        self.currentBalance = currentBalance ?? initialValue
        self.purchaseDate = purchaseDate
        self.activationDate = activationDate
        self.expirationDate = expirationDate
        self.status = status
        self.message = message
        self.design = design
        self.deliveryMethod = deliveryMethod
        self.deliveryDate = deliveryDate
        self.isReloadable = isReloadable
        self.transactions = transactions
    }

    var isActive: Bool {
        status == .active && currentBalance > 0 && !isExpired
    }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }

    var totalSpent: Double {
        initialValue - currentBalance
    }

    var redemptionPercentage: Double {
        guard initialValue > 0 else { return 0 }
        return (totalSpent / initialValue) * 100
    }
}

enum GiftCardStatus: String, Codable {
    case pending = "Pending"
    case active = "Active"
    case redeemed = "Fully Redeemed"
    case expired = "Expired"
    case cancelled = "Cancelled"
    case suspended = "Suspended"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .active: return "green"
        case .redeemed: return "blue"
        case .expired: return "gray"
        case .cancelled: return "red"
        case .suspended: return "orange"
        }
    }
}

enum GiftCardDesign: String, Codable, CaseIterable {
    case classic = "Classic"
    case spa = "Spa & Wellness"
    case birthday = "Birthday"
    case holiday = "Holiday"
    case thankyou = "Thank You"
    case custom = "Custom"

    var imageName: String {
        switch self {
        case .classic: return "gift.fill"
        case .spa: return "sparkles"
        case .birthday: return "gift.circle.fill"
        case .holiday: return "snowflake"
        case .thankyou: return "heart.fill"
        case .custom: return "photo.fill"
        }
    }
}

enum DeliveryMethod: String, Codable, CaseIterable {
    case email = "Email"
    case sms = "SMS"
    case physical = "Physical Card"
    case inPerson = "In-Person"

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .physical: return "creditcard.fill"
        case .inPerson: return "person.fill"
        }
    }
}

// MARK: - Gift Card Transaction

struct GiftCardTransaction: Identifiable, Codable {
    let id: UUID
    let giftCardId: UUID
    var transactionType: GiftCardTransactionType
    var amount: Double
    var balanceBefore: Double
    var balanceAfter: Double
    var date: Date
    var appointmentId: UUID?
    var notes: String

    init(
        id: UUID = UUID(),
        giftCardId: UUID,
        transactionType: GiftCardTransactionType,
        amount: Double,
        balanceBefore: Double,
        balanceAfter: Double,
        date: Date = Date(),
        appointmentId: UUID? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.giftCardId = giftCardId
        self.transactionType = transactionType
        self.amount = amount
        self.balanceBefore = balanceBefore
        self.balanceAfter = balanceAfter
        self.date = date
        self.appointmentId = appointmentId
        self.notes = notes
    }
}

enum GiftCardTransactionType: String, Codable {
    case purchase = "Purchase"
    case reload = "Reload"
    case redemption = "Redemption"
    case refund = "Refund"
    case adjustment = "Adjustment"
    case cancellation = "Cancellation"
}

// MARK: - Promotion

struct Promotion: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var promoCode: String
    var promotionType: PromotionType
    var discountType: DiscountType
    var discountValue: Double // Percentage or fixed amount
    var minimumPurchase: Double
    var maximumDiscount: Double?
    var startDate: Date
    var endDate: Date
    var usageLimit: Int? // Total uses allowed
    var usagePerClient: Int // Max uses per client
    var currentUsageCount: Int
    var applicableServices: [UUID] // Empty = all services
    var applicableProducts: [UUID] // For retail products
    var isActive: Bool
    var requiresCode: Bool
    var autoApply: Bool
    var targetAudience: PromotionAudience
    var terms: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        promoCode: String,
        promotionType: PromotionType,
        discountType: DiscountType,
        discountValue: Double,
        minimumPurchase: Double = 0,
        maximumDiscount: Double? = nil,
        startDate: Date = Date(),
        endDate: Date,
        usageLimit: Int? = nil,
        usagePerClient: Int = 1,
        currentUsageCount: Int = 0,
        applicableServices: [UUID] = [],
        applicableProducts: [UUID] = [],
        isActive: Bool = true,
        requiresCode: Bool = true,
        autoApply: Bool = false,
        targetAudience: PromotionAudience = .allClients,
        terms: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.promoCode = promoCode
        self.promotionType = promotionType
        self.discountType = discountType
        self.discountValue = discountValue
        self.minimumPurchase = minimumPurchase
        self.maximumDiscount = maximumDiscount
        self.startDate = startDate
        self.endDate = endDate
        self.usageLimit = usageLimit
        self.usagePerClient = usagePerClient
        self.currentUsageCount = currentUsageCount
        self.applicableServices = applicableServices
        self.applicableProducts = applicableProducts
        self.isActive = isActive
        self.requiresCode = requiresCode
        self.autoApply = autoApply
        self.targetAudience = targetAudience
        self.terms = terms
    }

    var isCurrentlyActive: Bool {
        let now = Date()
        return isActive && now >= startDate && now <= endDate && !hasReachedUsageLimit
    }

    var hasReachedUsageLimit: Bool {
        guard let limit = usageLimit else { return false }
        return currentUsageCount >= limit
    }

    var remainingUses: Int? {
        guard let limit = usageLimit else { return nil }
        return max(0, limit - currentUsageCount)
    }

    var isExpired: Bool {
        Date() > endDate
    }

    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
}

enum PromotionType: String, Codable, CaseIterable {
    case seasonal = "Seasonal"
    case newClient = "New Client"
    case referral = "Referral"
    case birthday = "Birthday"
    case loyalty = "Loyalty"
    case packageDeal = "Package Deal"
    case limitedTime = "Limited Time"
    case bulkDiscount = "Bulk Discount"
    case clearance = "Clearance"

    var icon: String {
        switch self {
        case .seasonal: return "calendar"
        case .newClient: return "person.badge.plus"
        case .referral: return "person.2.fill"
        case .birthday: return "gift.fill"
        case .loyalty: return "star.fill"
        case .packageDeal: return "square.stack.fill"
        case .limitedTime: return "timer"
        case .bulkDiscount: return "cart.fill"
        case .clearance: return "tag.fill"
        }
    }
}

enum DiscountType: String, Codable, CaseIterable {
    case percentage = "Percentage"
    case fixedAmount = "Fixed Amount"
    case buyOneGetOne = "BOGO"
    case freeService = "Free Service"

    var symbol: String {
        switch self {
        case .percentage: return "%"
        case .fixedAmount: return "$"
        case .buyOneGetOne: return "BOGO"
        case .freeService: return "FREE"
        }
    }
}

enum PromotionAudience: String, Codable {
    case allClients = "All Clients"
    case newClients = "New Clients Only"
    case existingClients = "Existing Clients"
    case vipClients = "VIP Clients"
    case dormantClients = "Dormant Clients"
    case specificClients = "Specific Clients"
}

// MARK: - Promotion Usage

struct PromotionUsage: Identifiable, Codable {
    let id: UUID
    let promotionId: UUID
    let promotionName: String
    let clientId: UUID
    let clientName: String
    var usageDate: Date
    var discountAmount: Double
    var originalAmount: Double
    var finalAmount: Double
    var appointmentId: UUID?
    var transactionId: UUID?

    init(
        id: UUID = UUID(),
        promotionId: UUID,
        promotionName: String,
        clientId: UUID,
        clientName: String,
        usageDate: Date = Date(),
        discountAmount: Double,
        originalAmount: Double,
        finalAmount: Double,
        appointmentId: UUID? = nil,
        transactionId: UUID? = nil
    ) {
        self.id = id
        self.promotionId = promotionId
        self.promotionName = promotionName
        self.clientId = clientId
        self.clientName = clientName
        self.usageDate = usageDate
        self.discountAmount = discountAmount
        self.originalAmount = originalAmount
        self.finalAmount = finalAmount
        self.appointmentId = appointmentId
        self.transactionId = transactionId
    }

    var discountPercentage: Double {
        guard originalAmount > 0 else { return 0 }
        return (discountAmount / originalAmount) * 100
    }
}

// MARK: - Loyalty Program

struct LoyaltyProgram: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var isActive: Bool
    var pointsPerDollar: Double
    var pointsExpireDays: Int?
    var tiers: [LoyaltyTier]
    var rewards: [LoyaltyReward]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isActive: Bool = true,
        pointsPerDollar: Double = 1.0,
        pointsExpireDays: Int? = nil,
        tiers: [LoyaltyTier] = [],
        rewards: [LoyaltyReward] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isActive = isActive
        self.pointsPerDollar = pointsPerDollar
        self.pointsExpireDays = pointsExpireDays
        self.tiers = tiers
        self.rewards = rewards
    }
}

struct LoyaltyTier: Identifiable, Codable {
    let id: UUID
    var name: String
    var pointsRequired: Int
    var benefits: [String]
    var discountPercentage: Double

    init(
        id: UUID = UUID(),
        name: String,
        pointsRequired: Int,
        benefits: [String] = [],
        discountPercentage: Double = 0
    ) {
        self.id = id
        self.name = name
        self.pointsRequired = pointsRequired
        self.benefits = benefits
        self.discountPercentage = discountPercentage
    }
}

struct LoyaltyReward: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var pointsCost: Int
    var rewardType: RewardType
    var value: Double
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        pointsCost: Int,
        rewardType: RewardType,
        value: Double,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.pointsCost = pointsCost
        self.rewardType = rewardType
        self.value = value
        self.isActive = isActive
    }
}

enum RewardType: String, Codable {
    case discount = "Discount"
    case freeService = "Free Service"
    case upgrade = "Service Upgrade"
    case giftCard = "Gift Card"
}

struct ClientLoyaltyAccount: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var totalPoints: Int
    var availablePoints: Int
    var currentTier: LoyaltyTier?
    var pointsToNextTier: Int
    var lifetimePoints: Int
    var joinDate: Date
    var lastActivityDate: Date?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        totalPoints: Int = 0,
        availablePoints: Int = 0,
        currentTier: LoyaltyTier? = nil,
        pointsToNextTier: Int = 0,
        lifetimePoints: Int = 0,
        joinDate: Date = Date(),
        lastActivityDate: Date? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.totalPoints = totalPoints
        self.availablePoints = availablePoints
        self.currentTier = currentTier
        self.pointsToNextTier = pointsToNextTier
        self.lifetimePoints = lifetimePoints
        self.joinDate = joinDate
        self.lastActivityDate = lastActivityDate
    }
}

// MARK: - Statistics

struct GiftCardStatistics {
    let totalSold: Int
    let totalRevenue: Double
    let totalRedeemed: Double
    let redemptionRate: Double
    let averageValue: Double
    let activeCards: Int
    let expiredCards: Int
    let averageDaysToRedemption: Double

    init(
        totalSold: Int = 0,
        totalRevenue: Double = 0,
        totalRedeemed: Double = 0,
        redemptionRate: Double = 0,
        averageValue: Double = 0,
        activeCards: Int = 0,
        expiredCards: Int = 0,
        averageDaysToRedemption: Double = 0
    ) {
        self.totalSold = totalSold
        self.totalRevenue = totalRevenue
        self.totalRedeemed = totalRedeemed
        self.redemptionRate = redemptionRate
        self.averageValue = averageValue
        self.activeCards = activeCards
        self.expiredCards = expiredCards
        self.averageDaysToRedemption = averageDaysToRedemption
    }
}

struct PromotionStatistics {
    let totalPromotions: Int
    let activePromotions: Int
    let totalUsages: Int
    let totalDiscountGiven: Double
    let totalRevenue: Double
    let averageDiscountPercentage: Double
    let conversionRate: Double
    let roi: Double // Return on investment

    init(
        totalPromotions: Int = 0,
        activePromotions: Int = 0,
        totalUsages: Int = 0,
        totalDiscountGiven: Double = 0,
        totalRevenue: Double = 0,
        averageDiscountPercentage: Double = 0,
        conversionRate: Double = 0,
        roi: Double = 0
    ) {
        self.totalPromotions = totalPromotions
        self.activePromotions = activePromotions
        self.totalUsages = totalUsages
        self.totalDiscountGiven = totalDiscountGiven
        self.totalRevenue = totalRevenue
        self.averageDiscountPercentage = averageDiscountPercentage
        self.conversionRate = conversionRate
        self.roi = roi
    }
}

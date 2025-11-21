import Foundation

/// Service for gift cards and promotional offers
@MainActor
class GiftCardPromotionService: ObservableObject {
    static let shared = GiftCardPromotionService()

    init() {
        // Initialize service
    }

    // MARK: - Gift Card Operations

    /// Generate unique gift card code
    func generateGiftCardCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding confusing characters
        let length = 12
        let code = (0..<length).map { _ in characters.randomElement()! }
        let codeString = String(code)

        // Format as XXXX-XXXX-XXXX
        let formatted = stride(from: 0, to: codeString.count, by: 4).map {
            let start = codeString.index(codeString.startIndex, offsetBy: $0)
            let end = codeString.index(start, offsetBy: min(4, codeString.count - $0))
            return String(codeString[start..<end])
        }.joined(separator: "-")

        return formatted
    }

    /// Create new gift card
    func createGiftCard(
        purchaserId: UUID?,
        recipientName: String,
        recipientEmail: String,
        recipientPhone: String = "",
        value: Double,
        message: String = "",
        design: GiftCardDesign = .classic,
        deliveryMethod: DeliveryMethod = .email,
        deliveryDate: Date? = nil,
        expirationMonths: Int? = 12
    ) -> GiftCard {
        let code = generateGiftCardCode()

        let expirationDate: Date?
        if let months = expirationMonths {
            expirationDate = Calendar.current.date(byAdding: .month, value: months, to: Date())
        } else {
            expirationDate = nil
        }

        return GiftCard(
            code: code,
            purchaserId: purchaserId,
            recipientName: recipientName,
            recipientEmail: recipientEmail,
            recipientPhone: recipientPhone,
            initialValue: value,
            expirationDate: expirationDate,
            message: message,
            design: design,
            deliveryMethod: deliveryMethod,
            deliveryDate: deliveryDate
        )
    }

    /// Activate gift card
    func activateGiftCard(_ giftCard: GiftCard) -> GiftCard {
        var activated = giftCard
        activated.status = .active
        activated.activationDate = Date()
        return activated
    }

    /// Validate gift card for use
    func validateGiftCard(_ giftCard: GiftCard, amount: Double) -> GiftCardValidation {
        // Check if card is active
        guard giftCard.status == .active else {
            return GiftCardValidation(isValid: false, reason: "Gift card is not active")
        }

        // Check expiration
        if giftCard.isExpired {
            return GiftCardValidation(isValid: false, reason: "Gift card has expired")
        }

        // Check balance
        if giftCard.currentBalance <= 0 {
            return GiftCardValidation(isValid: false, reason: "Gift card has no remaining balance")
        }

        // Check if amount exceeds balance
        if amount > giftCard.currentBalance {
            return GiftCardValidation(
                isValid: true,
                reason: "Amount exceeds balance. \(String(format: "$%.2f", giftCard.currentBalance)) will be applied.",
                maxAmount: giftCard.currentBalance
            )
        }

        return GiftCardValidation(isValid: true, reason: "Valid")
    }

    /// Redeem gift card
    func redeemGiftCard(
        giftCard: GiftCard,
        amount: Double,
        appointmentId: UUID? = nil,
        notes: String = ""
    ) -> (updatedCard: GiftCard, transaction: GiftCardTransaction) {
        let actualAmount = min(amount, giftCard.currentBalance)
        let balanceBefore = giftCard.currentBalance
        let balanceAfter = max(0, giftCard.currentBalance - actualAmount)

        var updatedCard = giftCard
        updatedCard.currentBalance = balanceAfter

        // Update status if fully redeemed
        if balanceAfter <= 0 {
            updatedCard.status = .redeemed
        }

        let transaction = GiftCardTransaction(
            giftCardId: giftCard.id,
            transactionType: .redemption,
            amount: actualAmount,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            appointmentId: appointmentId,
            notes: notes
        )

        updatedCard.transactions.append(transaction)

        return (updatedCard, transaction)
    }

    /// Reload gift card (add value)
    func reloadGiftCard(
        giftCard: GiftCard,
        amount: Double,
        notes: String = ""
    ) -> (updatedCard: GiftCard, transaction: GiftCardTransaction) {
        guard giftCard.isReloadable else {
            return (giftCard, GiftCardTransaction(
                giftCardId: giftCard.id,
                transactionType: .reload,
                amount: 0,
                balanceBefore: giftCard.currentBalance,
                balanceAfter: giftCard.currentBalance,
                notes: "Card is not reloadable"
            ))
        }

        let balanceBefore = giftCard.currentBalance
        let balanceAfter = giftCard.currentBalance + amount

        var updatedCard = giftCard
        updatedCard.currentBalance = balanceAfter

        if updatedCard.status == .redeemed {
            updatedCard.status = .active
        }

        let transaction = GiftCardTransaction(
            giftCardId: giftCard.id,
            transactionType: .reload,
            amount: amount,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            notes: notes
        )

        updatedCard.transactions.append(transaction)

        return (updatedCard, transaction)
    }

    /// Refund to gift card
    func refundToGiftCard(
        giftCard: GiftCard,
        amount: Double,
        appointmentId: UUID? = nil,
        notes: String = ""
    ) -> (updatedCard: GiftCard, transaction: GiftCardTransaction) {
        let balanceBefore = giftCard.currentBalance
        let balanceAfter = giftCard.currentBalance + amount

        var updatedCard = giftCard
        updatedCard.currentBalance = balanceAfter

        if updatedCard.status == .redeemed {
            updatedCard.status = .active
        }

        let transaction = GiftCardTransaction(
            giftCardId: giftCard.id,
            transactionType: .refund,
            amount: amount,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            appointmentId: appointmentId,
            notes: notes
        )

        updatedCard.transactions.append(transaction)

        return (updatedCard, transaction)
    }

    // MARK: - Promotion Operations

    /// Validate promotion code
    func validatePromotion(
        promotion: Promotion,
        clientId: UUID,
        amount: Double,
        serviceIds: [UUID] = [],
        clientUsageCount: Int = 0
    ) -> PromotionValidation {
        // Check if active
        guard promotion.isCurrentlyActive else {
            if promotion.isExpired {
                return PromotionValidation(isValid: false, reason: "Promotion has expired")
            }
            return PromotionValidation(isValid: false, reason: "Promotion is not active")
        }

        // Check usage limit
        if promotion.hasReachedUsageLimit {
            return PromotionValidation(isValid: false, reason: "Promotion has reached usage limit")
        }

        // Check per-client usage
        if clientUsageCount >= promotion.usagePerClient {
            return PromotionValidation(isValid: false, reason: "You have already used this promotion")
        }

        // Check minimum purchase
        if amount < promotion.minimumPurchase {
            return PromotionValidation(
                isValid: false,
                reason: "Minimum purchase of \(String(format: "$%.2f", promotion.minimumPurchase)) required"
            )
        }

        // Check applicable services
        if !promotion.applicableServices.isEmpty {
            let hasApplicableService = serviceIds.contains { promotion.applicableServices.contains($0) }
            if !hasApplicableService {
                return PromotionValidation(isValid: false, reason: "Promotion not applicable to selected services")
            }
        }

        return PromotionValidation(isValid: true, reason: "Valid")
    }

    /// Calculate discount from promotion
    func calculateDiscount(
        promotion: Promotion,
        amount: Double
    ) -> Double {
        var discount: Double = 0

        switch promotion.discountType {
        case .percentage:
            discount = amount * (promotion.discountValue / 100)

        case .fixedAmount:
            discount = promotion.discountValue

        case .buyOneGetOne:
            // For BOGO, discount is 50% of amount (one item free)
            discount = amount * 0.5

        case .freeService:
            // Full discount up to the amount
            discount = amount
        }

        // Apply maximum discount if specified
        if let maxDiscount = promotion.maximumDiscount {
            discount = min(discount, maxDiscount)
        }

        // Ensure discount doesn't exceed amount
        discount = min(discount, amount)

        return discount
    }

    /// Apply promotion to amount
    func applyPromotion(
        promotion: Promotion,
        clientId: UUID,
        clientName: String,
        originalAmount: Double,
        appointmentId: UUID? = nil
    ) -> (discountAmount: Double, finalAmount: Double, usage: PromotionUsage) {
        let discountAmount = calculateDiscount(promotion: promotion, amount: originalAmount)
        let finalAmount = max(0, originalAmount - discountAmount)

        let usage = PromotionUsage(
            promotionId: promotion.id,
            promotionName: promotion.name,
            clientId: clientId,
            clientName: clientName,
            discountAmount: discountAmount,
            originalAmount: originalAmount,
            finalAmount: finalAmount,
            appointmentId: appointmentId
        )

        return (discountAmount, finalAmount, usage)
    }

    /// Find applicable auto-apply promotions
    func findAutoApplyPromotions(
        promotions: [Promotion],
        clientId: UUID,
        amount: Double,
        serviceIds: [UUID] = []
    ) -> [Promotion] {
        return promotions.filter { promotion in
            promotion.autoApply &&
            promotion.isCurrentlyActive &&
            validatePromotion(
                promotion: promotion,
                clientId: clientId,
                amount: amount,
                serviceIds: serviceIds
            ).isValid
        }.sorted { promotion1, promotion2 in
            // Sort by best discount
            let discount1 = calculateDiscount(promotion: promotion1, amount: amount)
            let discount2 = calculateDiscount(promotion: promotion2, amount: amount)
            return discount1 > discount2
        }
    }

    // MARK: - Loyalty Program Operations

    /// Calculate points earned
    func calculatePointsEarned(
        amount: Double,
        pointsPerDollar: Double
    ) -> Int {
        return Int(amount * pointsPerDollar)
    }

    /// Add loyalty points
    func addLoyaltyPoints(
        account: ClientLoyaltyAccount,
        points: Int,
        program: LoyaltyProgram
    ) -> ClientLoyaltyAccount {
        var updated = account
        updated.totalPoints += points
        updated.availablePoints += points
        updated.lifetimePoints += points
        updated.lastActivityDate = Date()

        // Check for tier upgrade
        let sortedTiers = program.tiers.sorted { $0.pointsRequired < $1.pointsRequired }
        for tier in sortedTiers.reversed() {
            if updated.totalPoints >= tier.pointsRequired {
                updated.currentTier = tier

                // Calculate points to next tier
                if let nextTier = sortedTiers.first(where: { $0.pointsRequired > tier.pointsRequired }) {
                    updated.pointsToNextTier = nextTier.pointsRequired - updated.totalPoints
                } else {
                    updated.pointsToNextTier = 0 // At highest tier
                }
                break
            }
        }

        return updated
    }

    /// Redeem loyalty reward
    func redeemLoyaltyReward(
        account: ClientLoyaltyAccount,
        reward: LoyaltyReward
    ) -> ClientLoyaltyAccount? {
        guard account.availablePoints >= reward.pointsCost else {
            return nil // Insufficient points
        }

        var updated = account
        updated.availablePoints -= reward.pointsCost
        updated.lastActivityDate = Date()

        return updated
    }

    // MARK: - Statistics

    /// Calculate gift card statistics
    func calculateGiftCardStatistics(
        giftCards: [GiftCard]
    ) -> GiftCardStatistics {
        let totalSold = giftCards.count
        let totalRevenue = giftCards.reduce(0) { $0 + $1.initialValue }
        let totalRedeemed = giftCards.reduce(0) { $0 + $1.totalSpent }

        let redemptionRate = totalRevenue > 0 ? (totalRedeemed / totalRevenue) * 100 : 0
        let averageValue = totalSold > 0 ? totalRevenue / Double(totalSold) : 0

        let activeCards = giftCards.filter { $0.isActive }.count
        let expiredCards = giftCards.filter { $0.isExpired }.count

        // Calculate average days to redemption
        let redeemedCards = giftCards.filter { !$0.transactions.isEmpty }
        let redemptionDays = redeemedCards.compactMap { card -> Double? in
            guard let firstRedemption = card.transactions.first(where: { $0.transactionType == .redemption }) else {
                return nil
            }
            return firstRedemption.date.timeIntervalSince(card.purchaseDate) / 86400 // Days
        }
        let averageDaysToRedemption = redemptionDays.isEmpty ? 0 : redemptionDays.reduce(0, +) / Double(redemptionDays.count)

        return GiftCardStatistics(
            totalSold: totalSold,
            totalRevenue: totalRevenue,
            totalRedeemed: totalRedeemed,
            redemptionRate: redemptionRate,
            averageValue: averageValue,
            activeCards: activeCards,
            expiredCards: expiredCards,
            averageDaysToRedemption: averageDaysToRedemption
        )
    }

    /// Calculate promotion statistics
    func calculatePromotionStatistics(
        promotions: [Promotion],
        usages: [PromotionUsage]
    ) -> PromotionStatistics {
        let totalPromotions = promotions.count
        let activePromotions = promotions.filter { $0.isCurrentlyActive }.count
        let totalUsages = usages.count
        let totalDiscountGiven = usages.reduce(0) { $0 + $1.discountAmount }
        let totalRevenue = usages.reduce(0) { $0 + $1.finalAmount }

        let averageDiscountPercentage = usages.isEmpty ? 0 :
            usages.reduce(0) { $0 + $1.discountPercentage } / Double(usages.count)

        // Calculate ROI: (Revenue - Discounts) / Discounts * 100
        let roi = totalDiscountGiven > 0 ? ((totalRevenue - totalDiscountGiven) / totalDiscountGiven) * 100 : 0

        // Conversion rate would need additional data (views vs uses)
        let conversionRate = 0.0

        return PromotionStatistics(
            totalPromotions: totalPromotions,
            activePromotions: activePromotions,
            totalUsages: totalUsages,
            totalDiscountGiven: totalDiscountGiven,
            totalRevenue: totalRevenue,
            averageDiscountPercentage: averageDiscountPercentage,
            conversionRate: conversionRate,
            roi: roi
        )
    }

    /// Get top performing promotions
    func getTopPromotions(
        usages: [PromotionUsage],
        by metric: PromotionMetric,
        limit: Int = 5
    ) -> [PromotionPerformance] {
        // Group usages by promotion
        let grouped = Dictionary(grouping: usages, by: { $0.promotionId })

        var performances: [PromotionPerformance] = []

        for (promotionId, usagesList) in grouped {
            guard let firstUsage = usagesList.first else { continue }

            let totalUsages = usagesList.count
            let totalRevenue = usagesList.reduce(0) { $0 + $1.finalAmount }
            let totalDiscount = usagesList.reduce(0) { $0 + $1.discountAmount }
            let averageDiscountPercentage = usagesList.reduce(0) { $0 + $1.discountPercentage } / Double(totalUsages)

            performances.append(PromotionPerformance(
                promotionId: promotionId,
                promotionName: firstUsage.promotionName,
                totalUsages: totalUsages,
                totalRevenue: totalRevenue,
                totalDiscount: totalDiscount,
                averageDiscountPercentage: averageDiscountPercentage
            ))
        }

        // Sort by specified metric
        let sorted = performances.sorted { perf1, perf2 in
            switch metric {
            case .usages:
                return perf1.totalUsages > perf2.totalUsages
            case .revenue:
                return perf1.totalRevenue > perf2.totalRevenue
            case .discount:
                return perf1.totalDiscount > perf2.totalDiscount
            }
        }

        return Array(sorted.prefix(limit))
    }
}

// MARK: - Supporting Types

struct GiftCardValidation {
    let isValid: Bool
    let reason: String
    var maxAmount: Double?
}

struct PromotionValidation {
    let isValid: Bool
    let reason: String
}

enum PromotionMetric {
    case usages
    case revenue
    case discount
}

struct PromotionPerformance {
    let promotionId: UUID
    let promotionName: String
    let totalUsages: Int
    let totalRevenue: Double
    let totalDiscount: Double
    let averageDiscountPercentage: Double
}

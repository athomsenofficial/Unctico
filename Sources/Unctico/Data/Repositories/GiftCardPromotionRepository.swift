import Foundation
import Combine

/// Repository for gift cards and promotions data
@MainActor
class GiftCardPromotionRepository: ObservableObject {
    static let shared = GiftCardPromotionRepository()

    @Published var giftCards: [GiftCard] = []
    @Published var promotions: [Promotion] = []
    @Published var promotionUsages: [PromotionUsage] = []
    @Published var loyaltyProgram: LoyaltyProgram?
    @Published var loyaltyAccounts: [ClientLoyaltyAccount] = []

    private let giftCardsKey = "gift_cards"
    private let promotionsKey = "promotions"
    private let promotionUsagesKey = "promotion_usages"
    private let loyaltyProgramKey = "loyalty_program"
    private let loyaltyAccountsKey = "loyalty_accounts"

    init() {
        loadData()
        if promotions.isEmpty {
            initializeSampleData()
        }
    }

    // MARK: - Gift Card Management

    func addGiftCard(_ giftCard: GiftCard) {
        giftCards.append(giftCard)
        saveGiftCards()
    }

    func updateGiftCard(_ giftCard: GiftCard) {
        if let index = giftCards.firstIndex(where: { $0.id == giftCard.id }) {
            giftCards[index] = giftCard
            saveGiftCards()
        }
    }

    func deleteGiftCard(_ giftCard: GiftCard) {
        giftCards.removeAll { $0.id == giftCard.id }
        saveGiftCards()
    }

    func getGiftCard(id: UUID) -> GiftCard? {
        giftCards.first { $0.id == id }
    }

    func getGiftCard(code: String) -> GiftCard? {
        giftCards.first { $0.code.uppercased() == code.uppercased() }
    }

    func getActiveGiftCards() -> [GiftCard] {
        giftCards.filter { $0.isActive }
    }

    func getGiftCardsByPurchaser(clientId: UUID) -> [GiftCard] {
        giftCards.filter { $0.purchaserId == clientId }.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    func getGiftCardsByRecipient(email: String) -> [GiftCard] {
        giftCards.filter { $0.recipientEmail.lowercased() == email.lowercased() }
            .sorted { $0.purchaseDate > $1.purchaseDate }
    }

    func getExpiringGiftCards(daysAhead: Int = 30) -> [GiftCard] {
        let targetDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!
        return giftCards.filter { card in
            guard let expiration = card.expirationDate else { return false }
            return expiration <= targetDate && expiration > Date() && card.isActive
        }
    }

    func searchGiftCards(query: String) -> [GiftCard] {
        let lowercased = query.lowercased()
        return giftCards.filter {
            $0.code.lowercased().contains(lowercased) ||
            $0.recipientName.lowercased().contains(lowercased) ||
            $0.recipientEmail.lowercased().contains(lowercased)
        }
    }

    // MARK: - Promotion Management

    func addPromotion(_ promotion: Promotion) {
        promotions.append(promotion)
        savePromotions()
    }

    func updatePromotion(_ promotion: Promotion) {
        if let index = promotions.firstIndex(where: { $0.id == promotion.id }) {
            promotions[index] = promotion
            savePromotions()
        }
    }

    func deletePromotion(_ promotion: Promotion) {
        promotions.removeAll { $0.id == promotion.id }
        savePromotions()
    }

    func getPromotion(id: UUID) -> Promotion? {
        promotions.first { $0.id == id }
    }

    func getPromotion(code: String) -> Promotion? {
        promotions.first { $0.promoCode.uppercased() == code.uppercased() }
    }

    func getActivePromotions() -> [Promotion] {
        promotions.filter { $0.isCurrentlyActive }
    }

    func getAutoApplyPromotions() -> [Promotion] {
        promotions.filter { $0.autoApply && $0.isCurrentlyActive }
    }

    func getPromotionsByType(_ type: PromotionType) -> [Promotion] {
        promotions.filter { $0.promotionType == type }
    }

    func getExpiringPromotions(daysAhead: Int = 7) -> [Promotion] {
        let targetDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!
        return promotions.filter { promotion in
            promotion.endDate <= targetDate && promotion.endDate > Date() && promotion.isActive
        }
    }

    func searchPromotions(query: String) -> [Promotion] {
        let lowercased = query.lowercased()
        return promotions.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.promoCode.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased)
        }
    }

    // MARK: - Promotion Usage Tracking

    func addPromotionUsage(_ usage: PromotionUsage) {
        promotionUsages.append(usage)

        // Increment promotion usage count
        if let index = promotions.firstIndex(where: { $0.id == usage.promotionId }) {
            promotions[index].currentUsageCount += 1
            savePromotions()
        }

        savePromotionUsages()
    }

    func getPromotionUsages(promotionId: UUID) -> [PromotionUsage] {
        promotionUsages.filter { $0.promotionId == promotionId }
            .sorted { $0.usageDate > $1.usageDate }
    }

    func getClientPromotionUsages(clientId: UUID) -> [PromotionUsage] {
        promotionUsages.filter { $0.clientId == clientId }
            .sorted { $0.usageDate > $1.usageDate }
    }

    func getClientUsageCount(clientId: UUID, promotionId: UUID) -> Int {
        promotionUsages.filter {
            $0.clientId == clientId && $0.promotionId == promotionId
        }.count
    }

    func getRecentPromotionUsages(limit: Int = 20) -> [PromotionUsage] {
        Array(promotionUsages.sorted { $0.usageDate > $1.usageDate }.prefix(limit))
    }

    // MARK: - Loyalty Program Management

    func updateLoyaltyProgram(_ program: LoyaltyProgram) {
        loyaltyProgram = program
        saveLoyaltyProgram()
    }

    func getLoyaltyProgram() -> LoyaltyProgram? {
        return loyaltyProgram
    }

    // MARK: - Loyalty Account Management

    func addLoyaltyAccount(_ account: ClientLoyaltyAccount) {
        loyaltyAccounts.append(account)
        saveLoyaltyAccounts()
    }

    func updateLoyaltyAccount(_ account: ClientLoyaltyAccount) {
        if let index = loyaltyAccounts.firstIndex(where: { $0.id == account.id }) {
            loyaltyAccounts[index] = account
            saveLoyaltyAccounts()
        }
    }

    func getLoyaltyAccount(clientId: UUID) -> ClientLoyaltyAccount? {
        loyaltyAccounts.first { $0.clientId == clientId }
    }

    func getTopLoyaltyAccounts(limit: Int = 10) -> [ClientLoyaltyAccount] {
        Array(loyaltyAccounts.sorted { $0.totalPoints > $1.totalPoints }.prefix(limit))
    }

    // MARK: - Combined Operations

    /// Purchase and activate gift card
    func purchaseGiftCard(
        purchaserId: UUID?,
        recipientName: String,
        recipientEmail: String,
        recipientPhone: String = "",
        value: Double,
        message: String = "",
        design: GiftCardDesign = .classic,
        deliveryMethod: DeliveryMethod = .email,
        deliveryDate: Date? = nil
    ) -> GiftCard {
        let service = GiftCardPromotionService.shared

        var giftCard = service.createGiftCard(
            purchaserId: purchaserId,
            recipientName: recipientName,
            recipientEmail: recipientEmail,
            recipientPhone: recipientPhone,
            value: value,
            message: message,
            design: design,
            deliveryMethod: deliveryMethod,
            deliveryDate: deliveryDate
        )

        // Auto-activate if delivery is immediate
        if deliveryDate == nil || deliveryDate! <= Date() {
            giftCard = service.activateGiftCard(giftCard)
        }

        addGiftCard(giftCard)
        return giftCard
    }

    /// Redeem gift card and record transaction
    func redeemGiftCard(
        code: String,
        amount: Double,
        appointmentId: UUID? = nil,
        notes: String = ""
    ) -> (success: Bool, updatedCard: GiftCard?, transaction: GiftCardTransaction?, message: String) {
        guard let giftCard = getGiftCard(code: code) else {
            return (false, nil, nil, "Gift card not found")
        }

        let service = GiftCardPromotionService.shared
        let validation = service.validateGiftCard(giftCard, amount: amount)

        guard validation.isValid else {
            return (false, giftCard, nil, validation.reason)
        }

        let (updatedCard, transaction) = service.redeemGiftCard(
            giftCard: giftCard,
            amount: amount,
            appointmentId: appointmentId,
            notes: notes
        )

        updateGiftCard(updatedCard)

        return (true, updatedCard, transaction, "Gift card redeemed successfully")
    }

    /// Apply promotion and record usage
    func applyPromotion(
        code: String,
        clientId: UUID,
        clientName: String,
        amount: Double,
        serviceIds: [UUID] = [],
        appointmentId: UUID? = nil
    ) -> (success: Bool, discountAmount: Double, finalAmount: Double, message: String) {
        guard let promotion = getPromotion(code: code) else {
            return (false, 0, amount, "Promotion code not found")
        }

        let service = GiftCardPromotionService.shared
        let clientUsageCount = getClientUsageCount(clientId: clientId, promotionId: promotion.id)

        let validation = service.validatePromotion(
            promotion: promotion,
            clientId: clientId,
            amount: amount,
            serviceIds: serviceIds,
            clientUsageCount: clientUsageCount
        )

        guard validation.isValid else {
            return (false, 0, amount, validation.reason)
        }

        let (discountAmount, finalAmount, usage) = service.applyPromotion(
            promotion: promotion,
            clientId: clientId,
            clientName: clientName,
            originalAmount: amount,
            appointmentId: appointmentId
        )

        addPromotionUsage(usage)

        return (true, discountAmount, finalAmount, "Promotion applied successfully")
    }

    /// Award loyalty points for purchase
    func awardLoyaltyPoints(
        clientId: UUID,
        amount: Double
    ) {
        guard let program = loyaltyProgram, program.isActive else { return }

        let service = GiftCardPromotionService.shared
        let points = service.calculatePointsEarned(
            amount: amount,
            pointsPerDollar: program.pointsPerDollar
        )

        if let account = getLoyaltyAccount(clientId: clientId) {
            let updatedAccount = service.addLoyaltyPoints(
                account: account,
                points: points,
                program: program
            )
            updateLoyaltyAccount(updatedAccount)
        } else {
            // Create new account
            var newAccount = ClientLoyaltyAccount(clientId: clientId)
            newAccount = service.addLoyaltyPoints(
                account: newAccount,
                points: points,
                program: program
            )
            addLoyaltyAccount(newAccount)
        }
    }

    // MARK: - Statistics

    func getGiftCardStatistics() -> GiftCardStatistics {
        let service = GiftCardPromotionService.shared
        return service.calculateGiftCardStatistics(giftCards: giftCards)
    }

    func getPromotionStatistics() -> PromotionStatistics {
        let service = GiftCardPromotionService.shared
        return service.calculatePromotionStatistics(
            promotions: promotions,
            usages: promotionUsages
        )
    }

    func getTopPromotions(by metric: PromotionMetric, limit: Int = 5) -> [PromotionPerformance] {
        let service = GiftCardPromotionService.shared
        return service.getTopPromotions(usages: promotionUsages, by: metric, limit: limit)
    }

    // MARK: - Persistence

    private func loadData() {
        if let giftCardsData = UserDefaults.standard.data(forKey: giftCardsKey),
           let decodedGiftCards = try? JSONDecoder().decode([GiftCard].self, from: giftCardsData) {
            giftCards = decodedGiftCards
        }

        if let promotionsData = UserDefaults.standard.data(forKey: promotionsKey),
           let decodedPromotions = try? JSONDecoder().decode([Promotion].self, from: promotionsData) {
            promotions = decodedPromotions
        }

        if let usagesData = UserDefaults.standard.data(forKey: promotionUsagesKey),
           let decodedUsages = try? JSONDecoder().decode([PromotionUsage].self, from: usagesData) {
            promotionUsages = decodedUsages
        }

        if let programData = UserDefaults.standard.data(forKey: loyaltyProgramKey),
           let decodedProgram = try? JSONDecoder().decode(LoyaltyProgram.self, from: programData) {
            loyaltyProgram = decodedProgram
        }

        if let accountsData = UserDefaults.standard.data(forKey: loyaltyAccountsKey),
           let decodedAccounts = try? JSONDecoder().decode([ClientLoyaltyAccount].self, from: accountsData) {
            loyaltyAccounts = decodedAccounts
        }
    }

    private func saveGiftCards() {
        if let encoded = try? JSONEncoder().encode(giftCards) {
            UserDefaults.standard.set(encoded, forKey: giftCardsKey)
        }
    }

    private func savePromotions() {
        if let encoded = try? JSONEncoder().encode(promotions) {
            UserDefaults.standard.set(encoded, forKey: promotionsKey)
        }
    }

    private func savePromotionUsages() {
        if let encoded = try? JSONEncoder().encode(promotionUsages) {
            UserDefaults.standard.set(encoded, forKey: promotionUsagesKey)
        }
    }

    private func saveLoyaltyProgram() {
        if let encoded = try? JSONEncoder().encode(loyaltyProgram) {
            UserDefaults.standard.set(encoded, forKey: loyaltyProgramKey)
        }
    }

    private func saveLoyaltyAccounts() {
        if let encoded = try? JSONEncoder().encode(loyaltyAccounts) {
            UserDefaults.standard.set(encoded, forKey: loyaltyAccountsKey)
        }
    }

    // MARK: - Sample Data

    private func initializeSampleData() {
        // Sample promotions
        let newClientPromo = Promotion(
            name: "New Client Special",
            description: "20% off your first massage",
            promoCode: "WELCOME20",
            promotionType: .newClient,
            discountType: .percentage,
            discountValue: 20,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
            targetAudience: .newClients
        )

        let birthdayPromo = Promotion(
            name: "Birthday Treat",
            description: "$25 off any service during your birthday month",
            promoCode: "BIRTHDAY25",
            promotionType: .birthday,
            discountType: .fixedAmount,
            discountValue: 25,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            targetAudience: .allClients
        )

        let summerPromo = Promotion(
            name: "Summer Refresh",
            description: "15% off all services this summer",
            promoCode: "SUMMER15",
            promotionType: .seasonal,
            discountType: .percentage,
            discountValue: 15,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
            usageLimit: 100,
            autoApply: false,
            targetAudience: .allClients
        )

        promotions = [newClientPromo, birthdayPromo, summerPromo]
        savePromotions()

        // Sample loyalty program
        let bronzeTier = LoyaltyTier(
            name: "Bronze",
            pointsRequired: 0,
            benefits: ["Points on every purchase", "Birthday bonus"],
            discountPercentage: 0
        )

        let silverTier = LoyaltyTier(
            name: "Silver",
            pointsRequired: 500,
            benefits: ["5% discount", "Priority booking", "Birthday bonus"],
            discountPercentage: 5
        )

        let goldTier = LoyaltyTier(
            name: "Gold",
            pointsRequired: 1000,
            benefits: ["10% discount", "Priority booking", "Free add-ons", "Birthday bonus"],
            discountPercentage: 10
        )

        let reward1 = LoyaltyReward(
            name: "$10 Off",
            description: "$10 off any service",
            pointsCost: 100,
            rewardType: .discount,
            value: 10
        )

        let reward2 = LoyaltyReward(
            name: "$25 Off",
            description: "$25 off any service",
            pointsCost: 250,
            rewardType: .discount,
            value: 25
        )

        let reward3 = LoyaltyReward(
            name: "Free 30-Min Massage",
            description: "Complimentary 30-minute massage",
            pointsCost: 500,
            rewardType: .freeService,
            value: 50
        )

        loyaltyProgram = LoyaltyProgram(
            name: "Wellness Rewards",
            description: "Earn points with every visit and redeem for rewards",
            pointsPerDollar: 1.0,
            pointsExpireDays: 365,
            tiers: [bronzeTier, silverTier, goldTier],
            rewards: [reward1, reward2, reward3]
        )
        saveLoyaltyProgram()
    }
}

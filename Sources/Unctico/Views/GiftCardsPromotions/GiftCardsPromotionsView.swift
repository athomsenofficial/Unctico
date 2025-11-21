import SwiftUI

struct GiftCardsPromotionsView: View {
    @StateObject private var repository = GiftCardPromotionRepository.shared
    @StateObject private var service = GiftCardPromotionService.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                GiftCardsListView()
                    .tabItem {
                        Label("Gift Cards", systemImage: "giftcard.fill")
                    }
                    .tag(0)

                PromotionsListView()
                    .tabItem {
                        Label("Promotions", systemImage: "tag.fill")
                    }
                    .tag(1)

                LoyaltyProgramView()
                    .tabItem {
                        Label("Loyalty", systemImage: "star.fill")
                    }
                    .tag(2)

                GiftCardPromotionStatsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
            }
            .navigationTitle("Gift Cards & Promotions")
        }
    }
}

// MARK: - Gift Cards List View

struct GiftCardsListView: View {
    @StateObject private var repository = GiftCardPromotionRepository.shared
    @State private var searchText = ""
    @State private var selectedStatus: GiftCardStatus?
    @State private var showingNewGiftCard = false

    var filteredGiftCards: [GiftCard] {
        var cards = repository.giftCards

        if let status = selectedStatus {
            cards = cards.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            cards = repository.searchGiftCards(query: searchText)
        }

        return cards.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedStatus == nil,
                        action: { selectedStatus = nil }
                    )

                    ForEach([GiftCardStatus.pending, .active, .redeemed, .expired], id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: selectedStatus == status,
                            action: { selectedStatus = selectedStatus == status ? nil : status }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))

            List {
                if filteredGiftCards.isEmpty {
                    ContentUnavailableView(
                        "No Gift Cards",
                        systemImage: "giftcard",
                        description: Text("Create gift cards to sell to clients")
                    )
                } else {
                    ForEach(filteredGiftCards) { giftCard in
                        NavigationLink(destination: GiftCardDetailView(giftCard: giftCard)) {
                            GiftCardRow(giftCard: giftCard)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search gift cards")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewGiftCard = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewGiftCard) {
            Text("New Gift Card")
        }
    }
}

struct GiftCardRow: View {
    let giftCard: GiftCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: giftCard.design.imageName)
                    .foregroundColor(.purple)

                Text(giftCard.code)
                    .font(.headline)
                    .fontDesign(.monospaced)

                Spacer()

                GiftCardStatusBadge(status: giftCard.status)
            }

            HStack {
                Text("Recipient: \(giftCard.recipientName)")
                    .font(.subheadline)

                Spacer()

                Text(String(format: "$%.2f", giftCard.currentBalance))
                    .font(.headline)
                    .foregroundColor(.green)
            }

            HStack {
                Text("Purchased: \(giftCard.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let expiration = giftCard.expirationDate {
                    Text("•")
                        .foregroundColor(.secondary)

                    Text("Expires: \(expiration.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(giftCard.isExpired ? .red : .secondary)
                }
            }

            if giftCard.redemptionPercentage > 0 {
                ProgressView(value: giftCard.redemptionPercentage, total: 100)
                    .tint(.green)
                    .frame(height: 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GiftCardStatusBadge: View {
    let status: GiftCardStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

struct GiftCardDetailView: View {
    let giftCard: GiftCard

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: giftCard.design.imageName)
                        .font(.system(size: 60))
                        .foregroundColor(.purple)

                    Text(giftCard.code)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)

                    GiftCardStatusBadge(status: giftCard.status)

                    Text(String(format: "$%.2f", giftCard.currentBalance))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text("of \(String(format: "$%.2f", giftCard.initialValue)) original value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailSection(title: "Recipient", items: [
                        ("Name", giftCard.recipientName),
                        ("Email", giftCard.recipientEmail),
                        ("Phone", giftCard.recipientPhone.isEmpty ? "Not provided" : giftCard.recipientPhone)
                    ])

                    DetailSection(title: "Purchase Details", items: [
                        ("Purchased", giftCard.purchaseDate.formatted(date: .long, time: .omitted)),
                        ("Delivery", giftCard.deliveryMethod.rawValue),
                        ("Design", giftCard.design.rawValue)
                    ])

                    if let expiration = giftCard.expirationDate {
                        DetailSection(title: "Expiration", items: [
                            ("Expires", expiration.formatted(date: .long, time: .omitted)),
                            ("Status", giftCard.isExpired ? "Expired" : "Valid")
                        ])
                    }

                    if !giftCard.message.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.headline)

                            Text(giftCard.message)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }

                    // Transactions
                    if !giftCard.transactions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transaction History")
                                .font(.headline)

                            ForEach(giftCard.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Gift Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TransactionRow: View {
    let transaction: GiftCardTransaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.transactionType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", transaction.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.transactionType == .redemption ? .red : .green)

                Text("Balance: \(String(format: "$%.2f", transaction.balanceAfter))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DetailSection: View {
    let title: String
    let items: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.1)
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Promotions List View

struct PromotionsListView: View {
    @StateObject private var repository = GiftCardPromotionRepository.shared
    @State private var searchText = ""
    @State private var showingNewPromotion = false

    var filteredPromotions: [Promotion] {
        if searchText.isEmpty {
            return repository.promotions.sorted { $0.startDate > $1.startDate }
        } else {
            return repository.searchPromotions(query: searchText).sorted { $0.startDate > $1.startDate }
        }
    }

    var body: some View {
        List {
            if filteredPromotions.isEmpty {
                ContentUnavailableView(
                    "No Promotions",
                    systemImage: "tag",
                    description: Text("Create promotions to attract clients")
                )
            } else {
                ForEach(filteredPromotions) { promotion in
                    NavigationLink(destination: PromotionDetailView(promotion: promotion)) {
                        PromotionRow(promotion: promotion)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search promotions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewPromotion = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewPromotion) {
            Text("New Promotion")
        }
    }
}

struct PromotionRow: View {
    let promotion: Promotion
    @StateObject private var repository = GiftCardPromotionRepository.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: promotion.promotionType.icon)
                    .foregroundColor(.orange)

                Text(promotion.name)
                    .font(.headline)

                Spacer()

                PromotionStatusBadge(promotion: promotion)
            }

            HStack {
                Text(promotion.promoCode)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(.monospaced)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Text("\(promotion.discountValue, specifier: "%.0f")\(promotion.discountType.symbol) off")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            HStack {
                Text("Used: \(promotion.currentUsageCount) times")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let remaining = promotion.remainingUses {
                    Text("• \(remaining) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if promotion.isExpired {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    let daysLeft = promotion.daysUntilExpiration
                    if daysLeft <= 7 {
                        Text("\(daysLeft) days left")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Toggle("Active", isOn: Binding(
                get: { promotion.isActive },
                set: { newValue in
                    var updated = promotion
                    updated.isActive = newValue
                    repository.updatePromotion(updated)
                }
            ))
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct PromotionStatusBadge: View {
    let promotion: Promotion

    var body: some View {
        if promotion.isCurrentlyActive {
            Text("Active")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(4)
        } else if promotion.isExpired {
            Text("Expired")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.gray)
                .cornerRadius(4)
        } else {
            Text("Inactive")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(4)
        }
    }
}

struct PromotionDetailView: View {
    let promotion: Promotion

    var body: some View {
        Form {
            Section("Promotion Details") {
                DetailRow(label: "Name", value: promotion.name)
                DetailRow(label: "Code", value: promotion.promoCode)
                DetailRow(label: "Type", value: promotion.promotionType.rawValue)
                DetailRow(label: "Discount", value: "\(promotion.discountValue, specifier: "%.0f")\(promotion.discountType.symbol)")
            }

            Section("Status") {
                DetailRow(label: "Active", value: promotion.isCurrentlyActive ? "Yes" : "No")
                DetailRow(label: "Times Used", value: "\(promotion.currentUsageCount)")
                if let limit = promotion.usageLimit {
                    DetailRow(label: "Usage Limit", value: "\(limit)")
                }
                DetailRow(label: "Per Client", value: "\(promotion.usagePerClient)")
            }

            Section("Validity") {
                DetailRow(label: "Start Date", value: promotion.startDate.formatted(date: .long, time: .omitted))
                DetailRow(label: "End Date", value: promotion.endDate.formatted(date: .long, time: .omitted))
                if promotion.isExpired {
                    DetailRow(label: "Status", value: "Expired")
                } else {
                    DetailRow(label: "Days Remaining", value: "\(promotion.daysUntilExpiration)")
                }
            }

            if promotion.minimumPurchase > 0 {
                Section("Requirements") {
                    DetailRow(label: "Minimum Purchase", value: String(format: "$%.2f", promotion.minimumPurchase))
                }
            }

            if !promotion.description.isEmpty {
                Section("Description") {
                    Text(promotion.description)
                        .font(.body)
                }
            }
        }
        .navigationTitle(promotion.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Loyalty Program View

struct LoyaltyProgramView: View {
    @StateObject private var repository = GiftCardPromotionRepository.shared

    var loyaltyProgram: LoyaltyProgram? {
        repository.loyaltyProgram
    }

    var body: some View {
        ScrollView {
            if let program = loyaltyProgram {
                VStack(spacing: 20) {
                    // Program Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)

                        Text(program.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(program.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("\(program.pointsPerDollar, specifier: "%.1f") point per dollar spent")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding()

                    // Tiers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Membership Tiers")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(program.tiers.sorted { $0.pointsRequired < $1.pointsRequired }) { tier in
                            LoyaltyTierCard(tier: tier)
                        }
                    }

                    // Rewards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Rewards")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(program.rewards.filter { $0.isActive }) { reward in
                            LoyaltyRewardCard(reward: reward)
                        }
                    }

                    // Top Members
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Members")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(repository.getTopLoyaltyAccounts(limit: 5)) { account in
                            LoyaltyAccountRow(account: account)
                        }
                    }
                }
                .padding(.vertical)
            } else {
                ContentUnavailableView(
                    "No Loyalty Program",
                    systemImage: "star",
                    description: Text("Set up a loyalty program to reward repeat clients")
                )
            }
        }
    }
}

struct LoyaltyTierCard: View {
    let tier: LoyaltyTier

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tier.name)
                    .font(.headline)

                Spacer()

                if tier.discountPercentage > 0 {
                    Text("\(tier.discountPercentage, specifier: "%.0f")% off")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }

            Text("\(tier.pointsRequired)+ points required")
                .font(.caption)
                .foregroundColor(.secondary)

            if !tier.benefits.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tier.benefits, id: \.self) { benefit in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(benefit)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LoyaltyRewardCard: View {
    let reward: LoyaltyReward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(reward.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(reward.pointsCost) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text(String(format: "$%.0f value", reward.value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct LoyaltyAccountRow: View {
    let account: ClientLoyaltyAccount

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let tier = account.currentTier {
                    Text(tier.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Member")
                        .font(.subheadline)
                }

                Text("\(account.totalPoints) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let tier = account.currentTier {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Stats View

struct GiftCardPromotionStatsView: View {
    @StateObject private var repository = GiftCardPromotionRepository.shared

    var giftCardStats: GiftCardStatistics {
        repository.getGiftCardStatistics()
    }

    var promotionStats: PromotionStatistics {
        repository.getPromotionStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Gift Card Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gift Card Performance")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatsCard(
                            title: "Total Sold",
                            value: "\(giftCardStats.totalSold)",
                            icon: "giftcard.fill",
                            color: .purple
                        )

                        StatsCard(
                            title: "Revenue",
                            value: String(format: "$%.0f", giftCardStats.totalRevenue),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )

                        StatsCard(
                            title: "Redeemed",
                            value: String(format: "$%.0f", giftCardStats.totalRedeemed),
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )

                        StatsCard(
                            title: "Redemption Rate",
                            value: String(format: "%.1f%%", giftCardStats.redemptionRate),
                            icon: "percent",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }

                // Promotion Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Promotion Performance")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatsCard(
                            title: "Active Promos",
                            value: "\(promotionStats.activePromotions)",
                            icon: "tag.fill",
                            color: .orange
                        )

                        StatsCard(
                            title: "Total Uses",
                            value: "\(promotionStats.totalUsages)",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )

                        StatsCard(
                            title: "Discounts Given",
                            value: String(format: "$%.0f", promotionStats.totalDiscountGiven),
                            icon: "arrow.down.circle.fill",
                            color: .red
                        )

                        StatsCard(
                            title: "ROI",
                            value: String(format: "%.0f%%", promotionStats.roi),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                }

                // Top Promotions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Promotions by Usage")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(repository.getTopPromotions(by: .usages, limit: 5)) { performance in
                        TopPromotionRow(performance: performance)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct TopPromotionRow: View {
    let performance: PromotionPerformance

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.promotionName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(performance.totalUsages) uses • \(String(format: "$%.0f revenue", performance.totalRevenue))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "$%.0f", performance.totalDiscount))
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    GiftCardsPromotionsView()
}

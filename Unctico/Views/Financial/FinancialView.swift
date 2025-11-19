import SwiftUI

struct FinancialView: View {
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var totalRevenue: Double = 0
    @State private var totalExpenses: Double = 0
    @State private var transactions: [Transaction] = []

    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case custom = "Custom"
    }

    var netIncome: Double {
        totalRevenue - totalExpenses
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PeriodSelector(selectedPeriod: $selectedPeriod)

                    FinancialSummaryCard(
                        revenue: totalRevenue,
                        expenses: totalExpenses,
                        netIncome: netIncome
                    )

                    QuickFinancialActions()

                    RecentTransactionsSection(transactions: transactions)
                }
                .padding()
            }
            .navigationTitle("Financial")
            .background(Color.massageBackground.opacity(0.3))
        }
        .onAppear(perform: loadFinancialData)
    }

    private func loadFinancialData() {
        // Load financial data
    }
}

struct PeriodSelector: View {
    @Binding var selectedPeriod: FinancialView.TimePeriod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FinancialView.TimePeriod.allCases, id: \.self) { period in
                    PeriodButton(
                        title: period.rawValue,
                        isSelected: selectedPeriod == period
                    ) {
                        selectedPeriod = period
                    }
                }
            }
        }
    }
}

struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.tranquilTeal : Color(.systemGray6))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct FinancialSummaryCard: View {
    let revenue: Double
    let expenses: Double
    let netIncome: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FinancialMetric(
                    title: "Revenue",
                    amount: revenue,
                    color: .soothingGreen,
                    icon: "arrow.up.circle.fill"
                )

                FinancialMetric(
                    title: "Expenses",
                    amount: expenses,
                    color: .orange,
                    icon: "arrow.down.circle.fill"
                )
            }

            Divider()

            VStack(spacing: 8) {
                Text("Net Income")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(netIncome, format: .currency(code: "USD"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(netIncome >= 0 ? .soothingGreen : .red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct FinancialMetric: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(amount, format: .currency(code: "USD"))
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickFinancialActions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ActionCard(
                    title: "Record Payment",
                    icon: "dollarsign.circle.fill",
                    color: .soothingGreen
                ) {
                    // Record payment
                }

                ActionCard(
                    title: "Add Expense",
                    icon: "cart.fill",
                    color: .orange
                ) {
                    // Add expense
                }

                ActionCard(
                    title: "View Reports",
                    icon: "chart.bar.fill",
                    color: .calmingBlue
                ) {
                    // View reports
                }

                ActionCard(
                    title: "Invoice Client",
                    icon: "doc.text.fill",
                    color: .tranquilTeal
                ) {
                    // Invoice client
                }
            }
        }
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

struct RecentTransactionsSection: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    // View all transactions
                }
                .font(.subheadline)
                .foregroundColor(.tranquilTeal)
            }

            if transactions.isEmpty {
                EmptyStateView(message: "No transactions yet")
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Circle()
                .fill(transaction.type == .income ? Color.soothingGreen : Color.orange)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: transaction.type == .income ? "arrow.down" : "arrow.up")
                        .foregroundColor(.white)
                        .font(.caption)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(transaction.type == .income ? .soothingGreen : .orange)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 3)
    }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    var description: String
    var amount: Double
    var date: Date
    var type: TransactionType
    var category: String

    init(
        id: UUID = UUID(),
        description: String,
        amount: Double,
        date: Date = Date(),
        type: TransactionType,
        category: String
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
    }

    enum TransactionType: String, Codable {
        case income = "Income"
        case expense = "Expense"
    }
}

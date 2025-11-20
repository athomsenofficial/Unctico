import Combine
import SwiftUI

struct FinancialView: View {
    @ObservedObject private var repository = TransactionRepository.shared
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var showingAddExpense = false
    @State private var showingRecordPayment = false

    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case custom = "Custom"
    }

    var dateRange: ClosedRange<Date> {
        switch selectedPeriod {
        case .thisWeek: return repository.getThisWeekRange()
        case .thisMonth: return repository.getThisMonthRange()
        case .thisYear: return repository.getThisYearRange()
        case .custom: return repository.getThisMonthRange()
        }
    }

    var totalRevenue: Double {
        repository.getTotalRevenue(in: dateRange)
    }

    var totalExpenses: Double {
        repository.getTotalExpenses(in: dateRange)
    }

    var netIncome: Double {
        totalRevenue - totalExpenses
    }

    var transactions: [Transaction] {
        repository.getRecentTransactions(limit: 10)
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

                    QuickFinancialActions(
                        showingRecordPayment: $showingRecordPayment,
                        showingAddExpense: $showingAddExpense
                    )

                    RecentTransactionsSection(transactions: transactions)
                }
                .padding()
            }
            .navigationTitle("Financial")
            .background(Color.massageBackground.opacity(0.3))
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingRecordPayment) {
                RecordPaymentView()
            }
        }
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
    @Binding var showingRecordPayment: Bool
    @Binding var showingAddExpense: Bool

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
                    showingRecordPayment = true
                }

                ActionCard(
                    title: "Add Expense",
                    icon: "cart.fill",
                    color: .orange
                ) {
                    showingAddExpense = true
                }

                ActionCard(
                    title: "View Reports",
                    icon: "chart.bar.fill",
                    color: .calmingBlue
                ) {
                    // View reports - TODO: Navigate to analytics
                }

                ActionCard(
                    title: "Invoice Client",
                    icon: "doc.text.fill",
                    color: .tranquilTeal
                ) {
                    // Invoice client - TODO: Navigate to invoice generator
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

// MARK: - Add Expense View
struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = TransactionRepository.shared

    @State private var description = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var category = ExpenseCategory.supplies

    enum ExpenseCategory: String, CaseIterable {
        case supplies = "Supplies"
        case rent = "Rent"
        case utilities = "Utilities"
        case marketing = "Marketing"
        case insurance = "Insurance"
        case equipment = "Equipment"
        case licenses = "Licenses & Fees"
        case continuing_education = "Continuing Education"
        case professional_dues = "Professional Dues"
        case software = "Software & Subscriptions"
        case travel = "Travel & Mileage"
        case other = "Other"
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    TextField("Description", text: $description)
                        .autocapitalization(.words)

                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section {
                    Text("Track your business expenses for accurate profit calculations and tax deductions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(description.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        let transaction = Transaction(
            description: description,
            amount: amountValue,
            date: date,
            type: .expense,
            category: category.rawValue
        )
        repository.addTransaction(transaction)
        dismiss()
    }
}

// MARK: - Record Payment View
struct RecordPaymentView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = TransactionRepository.shared
    private let clientRepository = ClientRepository.shared

    @State private var selectedClient: Client?
    @State private var amount = ""
    @State private var date = Date()
    @State private var serviceType = "Massage Therapy"
    @State private var paymentMethod = PaymentMethod.cash

    enum PaymentMethod: String, CaseIterable {
        case cash = "Cash"
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case check = "Check"
        case venmo = "Venmo"
        case zelle = "Zelle"
        case other = "Other"
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Client") {
                    if clientRepository.clients.isEmpty {
                        Text("No clients available. Add a client first.")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Picker("Select Client", selection: $selectedClient) {
                            Text("Select a client").tag(nil as Client?)
                            ForEach(clientRepository.clients) { client in
                                Text(client.fullName).tag(client as Client?)
                            }
                        }
                    }
                }

                Section("Payment Details") {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Service", text: $serviceType)
                        .autocapitalization(.words)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }

                Section {
                    Text("Record payments received for services rendered.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePayment()
                    }
                    .disabled(selectedClient == nil || amount.isEmpty)
                }
            }
        }
    }

    private func savePayment() {
        guard let client = selectedClient,
              let amountValue = Double(amount),
              amountValue > 0 else { return }

        let transaction = Transaction(
            description: "\(serviceType) - \(client.fullName)",
            amount: amountValue,
            date: date,
            type: .income,
            category: "Service Revenue"
        )
        repository.addTransaction(transaction)
        dismiss()
    }
}

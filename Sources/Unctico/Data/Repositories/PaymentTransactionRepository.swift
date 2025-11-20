import Foundation

/// Repository for managing payment transactions
@MainActor
class PaymentTransactionRepository: ObservableObject {
    static let shared = PaymentTransactionRepository()

    @Published var transactions: [PaymentTransaction] = []
    @Published var receipts: [Receipt] = []
    @Published var paymentLinks: [PaymentLink] = []
    @Published var disputes: [PaymentDispute] = []

    private let transactionsKey = "unctico_transactions"
    private let receiptsKey = "unctico_receipts"
    private let linksKey = "unctico_payment_links"
    private let disputesKey = "unctico_disputes"

    init() {
        loadData()
    }

    // MARK: - Transaction Management

    func addTransaction(_ transaction: PaymentTransaction) {
        transactions.append(transaction)
        saveTransactions()
    }

    func updateTransaction(_ transaction: PaymentTransaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
        }
    }

    func deleteTransaction(_ id: UUID) {
        transactions.removeAll { $0.id == id }
        saveTransactions()
    }

    func getTransaction(_ id: UUID) -> PaymentTransaction? {
        transactions.first { $0.id == id }
    }

    // MARK: - Query Functions

    func getTransactions(for clientId: UUID) -> [PaymentTransaction] {
        transactions.filter { $0.clientId == clientId }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    func getTransactions(for appointmentId: UUID) -> [PaymentTransaction] {
        transactions.filter { $0.appointmentId == appointmentId }
    }

    func getTransactions(from startDate: Date, to endDate: Date) -> [PaymentTransaction] {
        transactions.filter { transaction in
            transaction.transactionDate >= startDate && transaction.transactionDate <= endDate
        }
    }

    func getTransactionsByStatus(_ status: TransactionStatus) -> [PaymentTransaction] {
        transactions.filter { $0.status == status }
    }

    func getTransactionsByGateway(_ gateway: PaymentGateway) -> [PaymentTransaction] {
        transactions.filter { $0.gateway == gateway }
    }

    func getRecentTransactions(limit: Int = 20) -> [PaymentTransaction] {
        Array(transactions.sorted { $0.transactionDate > $1.transactionDate }.prefix(limit))
    }

    func getPendingTransactions() -> [PaymentTransaction] {
        transactions.filter { $0.status == .pending || $0.status == .processing }
    }

    func getFailedTransactions() -> [PaymentTransaction] {
        transactions.filter { $0.status == .failed }
    }

    func getRefundedTransactions() -> [PaymentTransaction] {
        transactions.filter { $0.isRefunded }
    }

    // MARK: - Statistics

    func getTotalRevenue(from startDate: Date, to endDate: Date) -> Double {
        getTransactions(from: startDate, to: endDate)
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.amount }
    }

    func getTotalRefunds(from startDate: Date, to endDate: Date) -> Double {
        getTransactions(from: startDate, to: endDate)
            .compactMap { $0.refundedAmount }
            .reduce(0, +)
    }

    func getTotalProcessingFees(from startDate: Date, to endDate: Date) -> Double {
        getTransactions(from: startDate, to: endDate)
            .filter { $0.status == .completed }
            .compactMap { $0.processingFee }
            .reduce(0, +)
    }

    func getNetRevenue(from startDate: Date, to endDate: Date) -> Double {
        getTransactions(from: startDate, to: endDate)
            .filter { $0.status == .completed }
            .reduce(0) { sum, transaction in
                let netAmount = transaction.netAmount ?? transaction.amount
                let refunded = transaction.refundedAmount ?? 0
                return sum + netAmount - refunded
            }
    }

    func getAverageTransactionAmount(from startDate: Date, to endDate: Date) -> Double {
        let completedTransactions = getTransactions(from: startDate, to: endDate)
            .filter { $0.status == .completed }

        guard !completedTransactions.isEmpty else { return 0 }

        let total = completedTransactions.reduce(0) { $0 + $1.amount }
        return total / Double(completedTransactions.count)
    }

    func getTransactionStatistics(from startDate: Date, to endDate: Date) -> TransactionStatistics {
        let periodTransactions = getTransactions(from: startDate, to: endDate)
        let completed = periodTransactions.filter { $0.status == .completed }
        let failed = periodTransactions.filter { $0.status == .failed }
        let refunded = periodTransactions.filter { $0.isRefunded }

        let totalRevenue = completed.reduce(0) { $0 + $1.amount }
        let totalRefunds = refunded.compactMap { $0.refundedAmount }.reduce(0, +)
        let totalFees = completed.compactMap { $0.processingFee }.reduce(0, +)
        let netRevenue = totalRevenue - totalRefunds - totalFees

        var gatewayBreakdown: [PaymentGateway: Double] = [:]
        var paymentMethodBreakdown: [PaymentMethod: Int] = [:]

        for transaction in completed {
            gatewayBreakdown[transaction.gateway, default: 0] += transaction.amount
            paymentMethodBreakdown[transaction.paymentMethod, default: 0] += 1
        }

        return TransactionStatistics(
            totalTransactions: periodTransactions.count,
            completedTransactions: completed.count,
            failedTransactions: failed.count,
            refundedTransactions: refunded.count,
            totalRevenue: totalRevenue,
            totalRefunds: totalRefunds,
            totalProcessingFees: totalFees,
            netRevenue: netRevenue,
            averageTransaction: completed.isEmpty ? 0 : totalRevenue / Double(completed.count),
            successRate: periodTransactions.isEmpty ? 0 : Double(completed.count) / Double(periodTransactions.count) * 100,
            gatewayBreakdown: gatewayBreakdown,
            paymentMethodBreakdown: paymentMethodBreakdown
        )
    }

    // MARK: - Receipt Management

    func addReceipt(_ receipt: Receipt) {
        receipts.append(receipt)
        saveReceipts()
    }

    func getReceipt(for transactionId: UUID) -> Receipt? {
        receipts.first { $0.transactionId == transactionId }
    }

    func getReceipts(for clientName: String) -> [Receipt] {
        receipts.filter { $0.clientName == clientName }
    }

    // MARK: - Payment Link Management

    func addPaymentLink(_ link: PaymentLink) {
        paymentLinks.append(link)
        savePaymentLinks()
    }

    func updatePaymentLink(_ link: PaymentLink) {
        if let index = paymentLinks.firstIndex(where: { $0.id == link.id }) {
            paymentLinks[index] = link
            savePaymentLinks()
        }
    }

    func getPaymentLink(by linkId: String) -> PaymentLink? {
        paymentLinks.first { $0.linkId == linkId }
    }

    func getActivePaymentLinks() -> [PaymentLink] {
        paymentLinks.filter { $0.isActive && !$0.isExpired }
    }

    func getPaymentLinks(for clientId: UUID) -> [PaymentLink] {
        paymentLinks.filter { $0.clientId == clientId }
    }

    // MARK: - Dispute Management

    func addDispute(_ dispute: PaymentDispute) {
        disputes.append(dispute)
        saveDisputes()
    }

    func updateDispute(_ dispute: PaymentDispute) {
        if let index = disputes.firstIndex(where: { $0.id == dispute.id }) {
            disputes[index] = dispute
            saveDisputes()
        }
    }

    func getOpenDisputes() -> [PaymentDispute] {
        disputes.filter { $0.status == .open || $0.status == .underReview }
    }

    func getDispute(for transactionId: UUID) -> PaymentDispute? {
        disputes.first { $0.transactionId == transactionId }
    }

    // MARK: - Search

    func searchTransactions(query: String) -> [PaymentTransaction] {
        let lowercaseQuery = query.lowercased()
        return transactions.filter { transaction in
            transaction.clientName.lowercased().contains(lowercaseQuery) ||
            transaction.description.lowercased().contains(lowercaseQuery) ||
            transaction.receiptNumber.lowercased().contains(lowercaseQuery) ||
            (transaction.transactionId?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }

    // MARK: - Export

    func exportTransactions(from startDate: Date, to endDate: Date) -> String {
        let transactionsToExport = getTransactions(from: startDate, to: endDate)

        var csv = "Date,Receipt #,Client,Amount,Status,Gateway,Payment Method,Transaction ID,Notes\n"

        for transaction in transactionsToExport {
            let row = [
                formatDate(transaction.transactionDate),
                transaction.receiptNumber,
                transaction.clientName,
                String(format: "%.2f", transaction.amount),
                transaction.status.rawValue,
                transaction.gateway.rawValue,
                transaction.paymentMethod.rawValue,
                transaction.transactionId ?? "",
                transaction.notes
            ].map { "\"\($0)\"" }.joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([PaymentTransaction].self, from: data) {
            transactions = decoded
        }

        if let data = UserDefaults.standard.data(forKey: receiptsKey),
           let decoded = try? JSONDecoder().decode([Receipt].self, from: data) {
            receipts = decoded
        }

        if let data = UserDefaults.standard.data(forKey: linksKey),
           let decoded = try? JSONDecoder().decode([PaymentLink].self, from: data) {
            paymentLinks = decoded
        }

        if let data = UserDefaults.standard.data(forKey: disputesKey),
           let decoded = try? JSONDecoder().decode([PaymentDispute].self, from: data) {
            disputes = decoded
        }
    }

    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }

    private func saveReceipts() {
        if let encoded = try? JSONEncoder().encode(receipts) {
            UserDefaults.standard.set(encoded, forKey: receiptsKey)
        }
    }

    private func savePaymentLinks() {
        if let encoded = try? JSONEncoder().encode(paymentLinks) {
            UserDefaults.standard.set(encoded, forKey: linksKey)
        }
    }

    private func saveDisputes() {
        if let encoded = try? JSONEncoder().encode(disputes) {
            UserDefaults.standard.set(encoded, forKey: disputesKey)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct TransactionStatistics {
    let totalTransactions: Int
    let completedTransactions: Int
    let failedTransactions: Int
    let refundedTransactions: Int
    let totalRevenue: Double
    let totalRefunds: Double
    let totalProcessingFees: Double
    let netRevenue: Double
    let averageTransaction: Double
    let successRate: Double
    let gatewayBreakdown: [PaymentGateway: Double]
    let paymentMethodBreakdown: [PaymentMethod: Int]
}

import Foundation
import Combine

class TransactionRepository: ObservableObject {
    static let shared = TransactionRepository()

    @Published private(set) var transactions: [Transaction] = []

    private let storage = LocalStorageManager.shared
    private let fileName = "transactions"

    private init() {
        loadTransactions()
    }

    // MARK: - CRUD Operations

    func loadTransactions() {
        transactions = storage.load(from: fileName)

        // If no transactions exist, generate mock data for testing
        if transactions.isEmpty {
            print("📦 No transactions found, generating mock data...")
            transactions = MockDataGenerator.shared.generateTransactions(count: 100)
            saveTransactions()
        }
    }

    func saveTransactions() {
        storage.save(transactions, to: fileName)
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
    }

    func getTransaction(by id: UUID) -> Transaction? {
        return transactions.first { $0.id == id }
    }

    // MARK: - Query Methods

    func getTransactions(in dateRange: ClosedRange<Date>) -> [Transaction] {
        return transactions.filter { transaction in
            dateRange.contains(transaction.date)
        }
    }

    func getTransactions(of type: Transaction.TransactionType) -> [Transaction] {
        return transactions.filter { $0.type == type }
    }

    func getRecentTransactions(limit: Int = 10) -> [Transaction] {
        return transactions
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Financial Analytics

    func getTotalRevenue(in dateRange: ClosedRange<Date>) -> Double {
        return getTransactions(in: dateRange)
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    func getTotalExpenses(in dateRange: ClosedRange<Date>) -> Double {
        return getTransactions(in: dateRange)
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    func getNetIncome(in dateRange: ClosedRange<Date>) -> Double {
        return getTotalRevenue(in: dateRange) - getTotalExpenses(in: dateRange)
    }

    // MARK: - Period Helpers

    func getThisWeekRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1

        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        return startOfWeek...endOfWeek
    }

    func getThisMonthRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = Date()

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return startOfMonth...endOfMonth
    }

    func getThisYearRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = Date()

        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today))!
        let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear)!

        return startOfYear...endOfYear
    }

    // MARK: - Test Helpers

    func resetWithMockData(count: Int = 100) {
        transactions = MockDataGenerator.shared.generateTransactions(count: count)
        saveTransactions()
    }

    func clearAll() {
        transactions = []
        storage.delete(fileName: fileName)
    }
}

// ExpenseManager.swift
// Manages business expenses with categorization and reporting

import Foundation
import Combine

/// Manager for expense operations
class ExpenseManager: ObservableObject {

    @Published var expenses: [Expense] = []
    @Published var errorMessage: String?

    init() {
        // TODO: Load expenses from Core Data
        loadMockData()
    }

    // MARK: - CRUD Operations

    /// Create a new expense
    func createExpense(
        date: Date,
        amount: Decimal,
        category: ExpenseCategory,
        description: String,
        vendor: String,
        paymentMethod: PaymentMethod,
        isTaxDeductible: Bool = true,
        hasReceipt: Bool = false
    ) -> Expense? {
        var expense = Expense(
            date: date,
            amount: amount,
            category: category,
            description: description,
            vendor: vendor,
            paymentMethod: paymentMethod
        )

        expense.isTaxDeductible = isTaxDeductible
        expense.hasReceipt = hasReceipt

        expenses.append(expense)

        // TODO: Save to Core Data
        return expense
    }

    /// Update an existing expense
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            var updated = expense
            updated.updatedAt = Date()
            expenses[index] = updated

            // TODO: Update in Core Data
        }
    }

    /// Delete an expense
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        // TODO: Delete from Core Data
    }

    /// Get expense by ID
    func getExpense(id: UUID) -> Expense? {
        expenses.first { $0.id == id }
    }

    // MARK: - Recurring Expenses

    /// Create recurring expenses
    func createRecurringExpenses(
        firstExpense: Expense,
        pattern: RecurrencePattern
    ) -> [Expense] {
        var created: [Expense] = []

        // Validate first expense
        guard pattern.frequency != .custom else {
            errorMessage = "Custom recurrence not yet supported"
            return []
        }

        // Create first expense
        var parent = firstExpense
        parent.isRecurring = true
        parent.recurrencePattern = pattern
        expenses.append(parent)
        created.append(parent)

        // Generate future occurrences
        let occurrences = pattern.generateOccurrences(from: firstExpense.date)

        for (index, date) in occurrences.enumerated() {
            if index == 0 { continue } // Skip first (already created)

            var newExpense = firstExpense
            newExpense.id = UUID()
            newExpense.date = date
            newExpense.parentExpenseId = parent.id
            newExpense.createdAt = Date()
            newExpense.updatedAt = Date()

            expenses.append(newExpense)
            created.append(newExpense)
        }

        // TODO: Save to Core Data
        return created
    }

    // MARK: - Query Methods

    /// Get all expenses
    func allExpenses(sortedBy sortOrder: ExpenseSortOrder = .dateDescending) -> [Expense] {
        sortExpenses(expenses, by: sortOrder)
    }

    /// Get expenses for a specific date range
    func expenses(from startDate: Date, to endDate: Date) -> [Expense] {
        expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
    }

    /// Get expenses by category
    func expenses(category: ExpenseCategory) -> [Expense] {
        expenses.filter { $0.category == category }
    }

    /// Get expenses by month
    func expenses(month: Int, year: Int) -> [Expense] {
        expenses.filter { expense in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.month, .year], from: expense.date)
            return components.month == month && components.year == year
        }
    }

    /// Get expenses by year
    func expenses(year: Int) -> [Expense] {
        expenses.filter { $0.year == year }
    }

    /// Get tax deductible expenses
    func taxDeductibleExpenses(year: Int? = nil) -> [Expense] {
        var filtered = expenses.filter { $0.isTaxDeductible }

        if let year = year {
            filtered = filtered.filter { $0.year == year }
        }

        return filtered
    }

    /// Get expenses with receipts
    func expensesWithReceipts() -> [Expense] {
        expenses.filter { $0.hasReceipt }
    }

    /// Get expenses without receipts
    func expensesWithoutReceipts() -> [Expense] {
        expenses.filter { !$0.hasReceipt && $0.amount >= 75 } // IRS requires receipts > $75
    }

    /// Get recent expenses
    func recentExpenses(limit: Int = 10) -> [Expense] {
        Array(allExpenses(sortedBy: .dateDescending).prefix(limit))
    }

    // MARK: - Reporting

    /// Calculate total expenses for date range
    func totalExpenses(from startDate: Date, to endDate: Date) -> Decimal {
        expenses(from: startDate, to: endDate)
            .reduce(0) { $0 + $1.amount }
    }

    /// Calculate total expenses for year
    func totalExpenses(year: Int) -> Decimal {
        expenses(year: year)
            .reduce(0) { $0 + $1.amount }
    }

    /// Calculate expenses by category
    func expensesByCategory(from startDate: Date, to endDate: Date) -> [ExpenseCategory: Decimal] {
        let filtered = expenses(from: startDate, to: endDate)
        var byCategory: [ExpenseCategory: Decimal] = [:]

        for expense in filtered {
            byCategory[expense.category, default: 0] += expense.amount
        }

        return byCategory
    }

    /// Calculate tax deductible amount
    func taxDeductibleAmount(year: Int) -> Decimal {
        taxDeductibleExpenses(year: year)
            .reduce(0) { $0 + $1.amount }
    }

    /// Get expense statistics
    func getStatistics(from startDate: Date? = nil, to endDate: Date? = nil) -> ExpenseStatistics {
        var filtered = expenses

        if let startDate = startDate, let endDate = endDate {
            filtered = expenses(from: startDate, to: endDate)
        }

        let totalAmount = filtered.reduce(0) { $0 + $1.amount }
        let taxDeductible = filtered.filter { $0.isTaxDeductible }.reduce(0) { $0 + $1.amount }

        var byCategory: [ExpenseCategory: Decimal] = [:]
        for expense in filtered {
            byCategory[expense.category, default: 0] += expense.amount
        }

        let mostCommon = byCategory.max(by: { $0.value < $1.value })?.key
        let largest = filtered.max(by: { $0.amount < $1.amount })

        return ExpenseStatistics(
            totalExpenses: filtered.count,
            totalAmount: totalAmount,
            byCategory: byCategory,
            taxDeductibleAmount: taxDeductible,
            averageExpenseAmount: filtered.isEmpty ? 0 : totalAmount / Decimal(filtered.count),
            largestExpense: largest,
            mostCommonCategory: mostCommon
        )
    }

    /// Get monthly expense trend
    func monthlyTrend(year: Int) -> [Int: Decimal] {
        var trend: [Int: Decimal] = [:]

        for month in 1...12 {
            let monthExpenses = expenses(month: month, year: year)
            trend[month] = monthExpenses.reduce(0) { $0 + $1.amount }
        }

        return trend
    }

    // MARK: - Helper Methods

    private func sortExpenses(_ expenses: [Expense], by sortOrder: ExpenseSortOrder) -> [Expense] {
        switch sortOrder {
        case .dateDescending:
            return expenses.sorted { $0.date > $1.date }
        case .dateAscending:
            return expenses.sorted { $0.date < $1.date }
        case .amountDescending:
            return expenses.sorted { $0.amount > $1.amount }
        case .amountAscending:
            return expenses.sorted { $0.amount < $1.amount }
        case .category:
            return expenses.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }

    // MARK: - Mock Data

    private func loadMockData() {
        // Sample expenses for testing
        expenses = [
            Expense(
                date: Date().addingTimeInterval(-86400 * 5),
                amount: 1200,
                category: .rent,
                description: "Office rent - March",
                vendor: "Property Management Co"
            ),
            Expense(
                date: Date().addingTimeInterval(-86400 * 3),
                amount: 89.99,
                category: .massageSupplies,
                description: "Massage oil and lotion",
                vendor: "Massage Warehouse"
            ),
            Expense(
                date: Date().addingTimeInterval(-86400 * 2),
                amount: 45.50,
                category: .utilities,
                description: "Electric bill",
                vendor: "Power Company"
            )
        ]
    }
}

// MARK: - Sort Order

enum ExpenseSortOrder {
    case dateDescending
    case dateAscending
    case amountDescending
    case amountAscending
    case category
}

// IncomeManager.swift
// Manages business income with automatic appointment linking

import Foundation
import Combine

/// Manager for income operations
class IncomeManager: ObservableObject {

    @Published var incomes: [Income] = []
    @Published var errorMessage: String?

    init() {
        // TODO: Load incomes from Core Data
        loadMockData()
    }

    // MARK: - CRUD Operations

    /// Create a new income entry
    func createIncome(
        date: Date,
        amount: Decimal,
        category: IncomeCategory,
        description: String,
        source: String,
        paymentMethod: PaymentMethod,
        clientId: UUID? = nil,
        appointmentId: UUID? = nil,
        invoiceId: UUID? = nil,
        isAutomatic: Bool = false
    ) -> Income? {
        var income = Income(
            date: date,
            amount: amount,
            category: category,
            description: description,
            source: source,
            paymentMethod: paymentMethod,
            isAutomatic: isAutomatic
        )

        income.clientId = clientId
        income.appointmentId = appointmentId
        income.invoiceId = invoiceId

        incomes.append(income)

        // TODO: Save to Core Data
        return income
    }

    /// Create income from appointment automatically
    func createIncomeFromAppointment(
        appointment: Appointment,
        amount: Decimal,
        paymentMethod: PaymentMethod
    ) -> Income? {
        createIncome(
            date: appointment.startDateTime,
            amount: amount,
            category: .massageServices,
            description: "\(appointment.serviceType.rawValue) - \(appointment.durationMinutes) min",
            source: "Appointment", // TODO: Get client name from clientId
            paymentMethod: paymentMethod,
            clientId: appointment.clientId,
            appointmentId: appointment.id,
            isAutomatic: true
        )
    }

    /// Create income from invoice payment
    func createIncomeFromInvoice(
        invoice: Invoice,
        payment: Payment
    ) -> Income? {
        createIncome(
            date: payment.paymentDate,
            amount: payment.amount,
            category: .massageServices,
            description: "Invoice \(invoice.invoiceNumber)",
            source: "Invoice Payment",
            paymentMethod: payment.paymentMethod,
            clientId: invoice.clientId,
            invoiceId: invoice.id,
            isAutomatic: true
        )
    }

    /// Update an existing income entry
    func updateIncome(_ income: Income) {
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            var updated = income
            updated.updatedAt = Date()
            incomes[index] = updated

            // TODO: Update in Core Data
        }
    }

    /// Delete an income entry
    func deleteIncome(_ income: Income) {
        incomes.removeAll { $0.id == income.id }
        // TODO: Delete from Core Data
    }

    /// Get income by ID
    func getIncome(id: UUID) -> Income? {
        incomes.first { $0.id == id }
    }

    // MARK: - Query Methods

    /// Get all incomes
    func allIncomes(sortedBy sortOrder: IncomeSortOrder = .dateDescending) -> [Income] {
        sortIncomes(incomes, by: sortOrder)
    }

    /// Get incomes for a specific date range
    func incomes(from startDate: Date, to endDate: Date) -> [Income] {
        incomes.filter { income in
            income.date >= startDate && income.date <= endDate
        }
    }

    /// Get incomes by category
    func incomes(category: IncomeCategory) -> [Income] {
        incomes.filter { $0.category == category }
    }

    /// Get incomes by month
    func incomes(month: Int, year: Int) -> [Income] {
        incomes.filter { income in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.month, .year], from: income.date)
            return components.month == month && components.year == year
        }
    }

    /// Get incomes by year
    func incomes(year: Int) -> [Income] {
        incomes.filter { $0.year == year }
    }

    /// Get incomes for a specific client
    func incomes(clientId: UUID) -> [Income] {
        incomes.filter { $0.clientId == clientId }
    }

    /// Get automatic incomes (from appointments/invoices)
    func automaticIncomes() -> [Income] {
        incomes.filter { $0.isAutomatic }
    }

    /// Get manual incomes
    func manualIncomes() -> [Income] {
        incomes.filter { !$0.isAutomatic }
    }

    /// Get taxable incomes
    func taxableIncomes(year: Int? = nil) -> [Income] {
        var filtered = incomes.filter { $0.isTaxable }

        if let year = year {
            filtered = filtered.filter { $0.year == year }
        }

        return filtered
    }

    /// Get recent incomes
    func recentIncomes(limit: Int = 10) -> [Income] {
        Array(allIncomes(sortedBy: .dateDescending).prefix(limit))
    }

    // MARK: - Reporting

    /// Calculate total income for date range
    func totalIncome(from startDate: Date, to endDate: Date) -> Decimal {
        incomes(from: startDate, to: endDate)
            .reduce(0) { $0 + $1.amount }
    }

    /// Calculate total income for year
    func totalIncome(year: Int) -> Decimal {
        incomes(year: year)
            .reduce(0) { $0 + $1.amount }
    }

    /// Calculate incomes by category
    func incomesByCategory(from startDate: Date, to endDate: Date) -> [IncomeCategory: Decimal] {
        let filtered = incomes(from: startDate, to: endDate)
        var byCategory: [IncomeCategory: Decimal] = [:]

        for income in filtered {
            byCategory[income.category, default: 0] += income.amount
        }

        return byCategory
    }

    /// Calculate incomes by payment method
    func incomesByPaymentMethod(from startDate: Date, to endDate: Date) -> [PaymentMethod: Decimal] {
        let filtered = incomes(from: startDate, to: endDate)
        var byMethod: [PaymentMethod: Decimal] = [:]

        for income in filtered {
            byMethod[income.paymentMethod, default: 0] += income.amount
        }

        return byMethod
    }

    /// Calculate taxable income amount
    func taxableIncomeAmount(year: Int) -> Decimal {
        taxableIncomes(year: year)
            .reduce(0) { $0 + $1.amount }
    }

    /// Get income statistics
    func getStatistics(from startDate: Date? = nil, to endDate: Date? = nil) -> IncomeStatistics {
        var filtered = incomes

        if let startDate = startDate, let endDate = endDate {
            filtered = incomes(from: startDate, to: endDate)
        }

        let totalAmount = filtered.reduce(0) { $0 + $1.amount }
        let automaticAmount = filtered.filter { $0.isAutomatic }.reduce(0) { $0 + $1.amount }
        let manualAmount = filtered.filter { !$0.isAutomatic }.reduce(0) { $0 + $1.amount }

        var byCategory: [IncomeCategory: Decimal] = [:]
        for income in filtered {
            byCategory[income.category, default: 0] += income.amount
        }

        var byPaymentMethod: [PaymentMethod: Decimal] = [:]
        for income in filtered {
            byPaymentMethod[income.paymentMethod, default: 0] += income.amount
        }

        let mostCommon = byCategory.max(by: { $0.value < $1.value })?.key
        let largest = filtered.max(by: { $0.amount < $1.amount })

        return IncomeStatistics(
            totalIncome: filtered.count,
            totalAmount: totalAmount,
            byCategory: byCategory,
            byPaymentMethod: byPaymentMethod,
            automaticIncomeAmount: automaticAmount,
            manualIncomeAmount: manualAmount,
            averageIncomeAmount: filtered.isEmpty ? 0 : totalAmount / Decimal(filtered.count),
            largestIncome: largest,
            mostCommonCategory: mostCommon
        )
    }

    /// Get monthly income trend
    func monthlyTrend(year: Int) -> [Int: Decimal] {
        var trend: [Int: Decimal] = [:]

        for month in 1...12 {
            let monthIncomes = incomes(month: month, year: year)
            trend[month] = monthIncomes.reduce(0) { $0 + $1.amount }
        }

        return trend
    }

    /// Calculate month-over-month growth
    func monthOverMonthGrowth(year: Int) -> [Int: Decimal] {
        let trend = monthlyTrend(year: year)
        var growth: [Int: Decimal] = [:]

        for month in 2...12 {
            let currentMonth = trend[month] ?? 0
            let previousMonth = trend[month - 1] ?? 0

            if previousMonth > 0 {
                let percentageChange = ((currentMonth - previousMonth) / previousMonth) * 100
                growth[month] = percentageChange
            } else {
                growth[month] = 0
            }
        }

        return growth
    }

    // MARK: - Helper Methods

    private func sortIncomes(_ incomes: [Income], by sortOrder: IncomeSortOrder) -> [Income] {
        switch sortOrder {
        case .dateDescending:
            return incomes.sorted { $0.date > $1.date }
        case .dateAscending:
            return incomes.sorted { $0.date < $1.date }
        case .amountDescending:
            return incomes.sorted { $0.amount > $1.amount }
        case .amountAscending:
            return incomes.sorted { $0.amount < $1.amount }
        case .category:
            return incomes.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }

    // MARK: - Mock Data

    private func loadMockData() {
        // Sample incomes for testing
        incomes = [
            Income(
                date: Date().addingTimeInterval(-86400 * 5),
                amount: 120,
                category: .therapeuticMassage,
                description: "60-minute therapeutic massage",
                source: "Jane Smith",
                isAutomatic: true
            ),
            Income(
                date: Date().addingTimeInterval(-86400 * 3),
                amount: 150,
                category: .deepTissue,
                description: "90-minute deep tissue",
                source: "John Doe",
                isAutomatic: true
            ),
            Income(
                date: Date().addingTimeInterval(-86400 * 1),
                amount: 25,
                category: .tips,
                description: "Client tip",
                source: "Jane Smith"
            )
        ]
    }
}

// MARK: - Sort Order

enum IncomeSortOrder {
    case dateDescending
    case dateAscending
    case amountDescending
    case amountAscending
    case category
}

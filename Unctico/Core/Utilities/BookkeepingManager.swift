// BookkeepingManager.swift
// Comprehensive financial reporting and bookkeeping

import Foundation
import Combine

/// Manager for financial reports and bookkeeping
class BookkeepingManager: ObservableObject {

    let expenseManager: ExpenseManager
    let incomeManager: IncomeManager

    init(expenseManager: ExpenseManager, incomeManager: IncomeManager) {
        self.expenseManager = expenseManager
        self.incomeManager = incomeManager
    }

    // MARK: - Profit & Loss Statement

    /// Generate profit and loss statement for date range
    func profitAndLoss(from startDate: Date, to endDate: Date) -> ProfitAndLossStatement {
        let totalIncome = incomeManager.totalIncome(from: startDate, to: endDate)
        let incomeByCategory = incomeManager.incomesByCategory(from: startDate, to: endDate)

        let totalExpenses = expenseManager.totalExpenses(from: startDate, to: endDate)
        let expensesByCategory = expenseManager.expensesByCategory(from: startDate, to: endDate)

        let netIncome = totalIncome - totalExpenses

        return ProfitAndLossStatement(
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            incomeByCategory: incomeByCategory,
            totalExpenses: totalExpenses,
            expensesByCategory: expensesByCategory,
            netIncome: netIncome
        )
    }

    /// Generate profit and loss for a specific month
    func profitAndLoss(month: Int, year: Int) -> ProfitAndLossStatement {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)

        guard let startDate = calendar.date(from: dateComponents),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return ProfitAndLossStatement(
                startDate: Date(),
                endDate: Date(),
                totalIncome: 0,
                incomeByCategory: [:],
                totalExpenses: 0,
                expensesByCategory: [:],
                netIncome: 0
            )
        }

        return profitAndLoss(from: startDate, to: endDate)
    }

    /// Generate profit and loss for a specific year
    func profitAndLoss(year: Int) -> ProfitAndLossStatement {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        return profitAndLoss(from: startDate, to: endDate)
    }

    // MARK: - Cash Flow Report

    /// Generate cash flow statement
    func cashFlow(from startDate: Date, to endDate: Date) -> CashFlowStatement {
        let incomeByMethod = incomeManager.incomesByPaymentMethod(from: startDate, to: endDate)

        let cashIncome = incomeByMethod[.cash] ?? 0
        let checkIncome = incomeByMethod[.check] ?? 0
        let creditCardIncome = incomeByMethod[.creditCard] ?? 0
        let otherIncome = incomeByMethod.values.reduce(0, +) - cashIncome - checkIncome - creditCardIncome

        let totalCashIn = incomeByMethod.values.reduce(0, +)
        let totalCashOut = expenseManager.totalExpenses(from: startDate, to: endDate)
        let netCashFlow = totalCashIn - totalCashOut

        return CashFlowStatement(
            startDate: startDate,
            endDate: endDate,
            cashIncome: cashIncome,
            checkIncome: checkIncome,
            creditCardIncome: creditCardIncome,
            otherIncome: otherIncome,
            totalCashIn: totalCashIn,
            totalCashOut: totalCashOut,
            netCashFlow: netCashFlow
        )
    }

    // MARK: - Tax Preparation Reports

    /// Generate tax preparation report for a year
    func taxReport(year: Int) -> TaxReport {
        let totalIncome = incomeManager.totalIncome(year: year)
        let taxableIncome = incomeManager.taxableIncomeAmount(year: year)

        let totalExpenses = expenseManager.totalExpenses(year: year)
        let deductibleExpenses = expenseManager.taxDeductibleAmount(year: year)

        let netTaxableIncome = taxableIncome - deductibleExpenses

        // Get detailed category breakdowns
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        let incomeByCategory = incomeManager.incomesByCategory(from: startDate, to: endDate)
        let expensesByCategory = expenseManager.expensesByCategory(from: startDate, to: endDate)

        // Identify missing receipts
        let expensesNeedingReceipts = expenseManager.expensesWithoutReceipts()

        return TaxReport(
            year: year,
            totalIncome: totalIncome,
            taxableIncome: taxableIncome,
            incomeByCategory: incomeByCategory,
            totalExpenses: totalExpenses,
            deductibleExpenses: deductibleExpenses,
            expensesByCategory: expensesByCategory,
            netTaxableIncome: netTaxableIncome,
            expensesNeedingReceipts: expensesNeedingReceipts
        )
    }

    // MARK: - Year-End Summary

    /// Generate comprehensive year-end summary
    func yearEndSummary(year: Int) -> YearEndSummary {
        let pl = profitAndLoss(year: year)

        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        let cf = cashFlow(from: startDate, to: endDate)
        let tax = taxReport(year: year)

        // Monthly trends
        let incomeMonthly = incomeManager.monthlyTrend(year: year)
        let expenseMonthly = expenseManager.monthlyTrend(year: year)

        // Highest income month
        let highestIncomeMonth = incomeMonthly.max(by: { $0.value < $1.value })
        let lowestIncomeMonth = incomeMonthly.min(by: { $0.value < $1.value })

        // Income statistics
        let incomeStats = incomeManager.getStatistics(from: startDate, to: endDate)
        let expenseStats = expenseManager.getStatistics(from: startDate, to: endDate)

        return YearEndSummary(
            year: year,
            profitAndLoss: pl,
            cashFlow: cf,
            taxReport: tax,
            incomeMonthlyTrend: incomeMonthly,
            expenseMonthlyTrend: expenseMonthly,
            highestIncomeMonth: highestIncomeMonth?.key,
            highestIncomeAmount: highestIncomeMonth?.value ?? 0,
            lowestIncomeMonth: lowestIncomeMonth?.key,
            lowestIncomeAmount: lowestIncomeMonth?.value ?? 0,
            incomeStatistics: incomeStats,
            expenseStatistics: expenseStats
        )
    }

    // MARK: - Quarterly Reports

    /// Get quarter dates
    private func quarterDates(quarter: Int, year: Int) -> (start: Date, end: Date)? {
        let calendar = Calendar.current

        let startMonth = (quarter - 1) * 3 + 1
        guard let startDate = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1)) else {
            return nil
        }

        guard let endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate) else {
            return nil
        }

        return (startDate, endDate)
    }

    /// Generate quarterly profit and loss
    func profitAndLoss(quarter: Int, year: Int) -> ProfitAndLossStatement? {
        guard let dates = quarterDates(quarter: quarter, year: year) else {
            return nil
        }

        return profitAndLoss(from: dates.start, to: dates.end)
    }

    // MARK: - Financial Health Metrics

    /// Calculate profit margin percentage
    func profitMargin(from startDate: Date, to endDate: Date) -> Decimal {
        let totalIncome = incomeManager.totalIncome(from: startDate, to: endDate)
        let totalExpenses = expenseManager.totalExpenses(from: startDate, to: endDate)

        guard totalIncome > 0 else { return 0 }

        let netIncome = totalIncome - totalExpenses
        return (netIncome / totalIncome) * 100
    }

    /// Calculate expense ratio (expenses as percentage of income)
    func expenseRatio(from startDate: Date, to endDate: Date) -> Decimal {
        let totalIncome = incomeManager.totalIncome(from: startDate, to: endDate)
        let totalExpenses = expenseManager.totalExpenses(from: startDate, to: endDate)

        guard totalIncome > 0 else { return 0 }

        return (totalExpenses / totalIncome) * 100
    }

    /// Calculate average daily income
    func averageDailyIncome(from startDate: Date, to endDate: Date) -> Decimal {
        let totalIncome = incomeManager.totalIncome(from: startDate, to: endDate)
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1

        return totalIncome / Decimal(max(1, days))
    }
}

// MARK: - Report Structures

struct ProfitAndLossStatement {
    let startDate: Date
    let endDate: Date

    // Income
    let totalIncome: Decimal
    let incomeByCategory: [IncomeCategory: Decimal]

    // Expenses
    let totalExpenses: Decimal
    let expensesByCategory: [ExpenseCategory: Decimal]

    // Net
    let netIncome: Decimal

    var profitMarginPercentage: Decimal {
        guard totalIncome > 0 else { return 0 }
        return (netIncome / totalIncome) * 100
    }
}

struct CashFlowStatement {
    let startDate: Date
    let endDate: Date

    // Cash in
    let cashIncome: Decimal
    let checkIncome: Decimal
    let creditCardIncome: Decimal
    let otherIncome: Decimal
    let totalCashIn: Decimal

    // Cash out
    let totalCashOut: Decimal

    // Net
    let netCashFlow: Decimal
}

struct TaxReport {
    let year: Int

    // Income
    let totalIncome: Decimal
    let taxableIncome: Decimal
    let incomeByCategory: [IncomeCategory: Decimal]

    // Expenses
    let totalExpenses: Decimal
    let deductibleExpenses: Decimal
    let expensesByCategory: [ExpenseCategory: Decimal]

    // Net
    let netTaxableIncome: Decimal

    // Issues
    let expensesNeedingReceipts: [Expense]
}

struct YearEndSummary {
    let year: Int

    // Major reports
    let profitAndLoss: ProfitAndLossStatement
    let cashFlow: CashFlowStatement
    let taxReport: TaxReport

    // Trends
    let incomeMonthlyTrend: [Int: Decimal]
    let expenseMonthlyTrend: [Int: Decimal]

    // Highlights
    let highestIncomeMonth: Int?
    let highestIncomeAmount: Decimal
    let lowestIncomeMonth: Int?
    let lowestIncomeAmount: Decimal

    // Statistics
    let incomeStatistics: IncomeStatistics
    let expenseStatistics: ExpenseStatistics
}

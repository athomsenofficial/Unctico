// FinancialReportsView.swift
// Comprehensive financial reporting with P&L, cash flow, and tax reports

import SwiftUI

/// Financial reports view with P&L, cash flow, and tax reporting
struct FinancialReportsView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @StateObject private var incomeManager = IncomeManager()

    @State private var selectedTab: ReportTab = .profitLoss
    @State private var selectedPeriod: ReportingPeriod = .thisMonth
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var bookkeepingManager: BookkeepingManager {
        BookkeepingManager(expenseManager: expenseManager, incomeManager: incomeManager)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Report type selector
            reportTabSelector

            // Period selector
            periodSelector

            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case .profitLoss:
                    profitLossView
                case .cashFlow:
                    cashFlowView
                case .taxReport:
                    taxReportView
                }
            }
        }
        .navigationTitle("Financial Reports")
    }

    // MARK: - View Components

    private var reportTabSelector: some View {
        Picker("Report Type", selection: $selectedTab) {
            ForEach(ReportTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var periodSelector: some View {
        HStack {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(ReportingPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.menu)

            if selectedPeriod == .custom || selectedTab == .taxReport {
                Picker("Year", selection: $selectedYear) {
                    ForEach((2020...2030), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - Profit & Loss View

    private var profitLossView: some View {
        let pl = profitAndLossForPeriod()

        return VStack(spacing: 20) {
            // Summary card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Net Income")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(pl.netIncome))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(pl.netIncome >= 0 ? .green : .red)

                    HStack(spacing: 4) {
                        Text("Profit Margin:")
                        Text("\(formatPercentage(pl.profitMarginPercentage))%")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Divider()

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(CurrencyFormatter.format(pl.totalIncome))
                            .font(.headline)
                            .foregroundStyle(.green)
                    }

                    VStack(spacing: 4) {
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(CurrencyFormatter.format(pl.totalExpenses))
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Income breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Income Breakdown")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(pl.incomeByCategory.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .foregroundStyle(.green)

                                Text(category.rawValue)
                                    .font(.subheadline)
                            }

                            Spacer()

                            Text(CurrencyFormatter.format(amount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        if category != pl.incomeByCategory.sorted(by: { $0.value > $1.value }).last?.key {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            // Expense breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Expense Breakdown")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(pl.expensesByCategory.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .foregroundStyle(.red)

                                Text(category.rawValue)
                                    .font(.subheadline)
                            }

                            Spacer()

                            Text(CurrencyFormatter.format(amount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        if category != pl.expensesByCategory.sorted(by: { $0.value > $1.value }).last?.key {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }

    // MARK: - Cash Flow View

    private var cashFlowView: some View {
        let cf = cashFlowForPeriod()

        return VStack(spacing: 20) {
            // Summary card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Net Cash Flow")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(cf.netCashFlow))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(cf.netCashFlow >= 0 ? .green : .red)
                }

                Divider()

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Cash In")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(CurrencyFormatter.format(cf.totalCashIn))
                            .font(.headline)
                            .foregroundStyle(.green)
                    }

                    VStack(spacing: 4) {
                        Text("Cash Out")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(CurrencyFormatter.format(cf.totalCashOut))
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Cash in breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Cash Inflow by Payment Method")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    CashFlowRow(label: "Cash", amount: cf.cashIncome, icon: "dollarsign.circle.fill")
                    Divider()
                    CashFlowRow(label: "Check", amount: cf.checkIncome, icon: "checkmark.circle.fill")
                    Divider()
                    CashFlowRow(label: "Credit Card", amount: cf.creditCardIncome, icon: "creditcard.fill")
                    Divider()
                    CashFlowRow(label: "Other", amount: cf.otherIncome, icon: "ellipsis.circle.fill")
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }

    // MARK: - Tax Report View

    private var taxReportView: some View {
        let tax = bookkeepingManager.taxReport(year: selectedYear)

        return VStack(spacing: 20) {
            // Summary card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Net Taxable Income")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(tax.netTaxableIncome))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(tax.netTaxableIncome >= 0 ? .green : .red)

                    Text("For Tax Year \(tax.year)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(spacing: 8) {
                    HStack {
                        Text("Total Income")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(tax.totalIncome))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Taxable Income")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(tax.taxableIncome))
                            .fontWeight(.semibold)
                    }

                    Divider()

                    HStack {
                        Text("Total Expenses")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(tax.totalExpenses))
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Deductible Expenses")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(tax.deductibleExpenses))
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Missing receipts warning
            if !tax.expensesNeedingReceipts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text("Missing Receipts")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(tax.expensesNeedingReceipts.prefix(5)) { expense in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.description)
                                        .font(.subheadline)

                                    Text(expense.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(CurrencyFormatter.format(expense.amount))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)

                            if expense.id != tax.expensesNeedingReceipts.prefix(5).last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    if tax.expensesNeedingReceipts.count > 5 {
                        Text("+ \(tax.expensesNeedingReceipts.count - 5) more expenses need receipts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom)
    }

    // MARK: - Helper Methods

    private func profitAndLossForPeriod() -> ProfitAndLossStatement {
        let dates = selectedPeriod.dateRange(year: selectedYear)

        switch selectedPeriod {
        case .thisMonth, .lastMonth, .custom:
            return bookkeepingManager.profitAndLoss(from: dates.start, to: dates.end)
        case .thisQuarter, .lastQuarter:
            let quarter = selectedPeriod == .thisQuarter ? currentQuarter() : currentQuarter() - 1
            return bookkeepingManager.profitAndLoss(quarter: quarter, year: selectedYear) ?? ProfitAndLossStatement(
                startDate: dates.start,
                endDate: dates.end,
                totalIncome: 0,
                incomeByCategory: [:],
                totalExpenses: 0,
                expensesByCategory: [:],
                netIncome: 0
            )
        case .thisYear:
            return bookkeepingManager.profitAndLoss(year: selectedYear)
        }
    }

    private func cashFlowForPeriod() -> CashFlowStatement {
        let dates = selectedPeriod.dateRange(year: selectedYear)
        return bookkeepingManager.cashFlow(from: dates.start, to: dates.end)
    }

    private func currentQuarter() -> Int {
        let month = Calendar.current.component(.month, from: Date())
        return (month - 1) / 3 + 1
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        return String(format: "%.1f", nsDecimal.doubleValue)
    }
}

// MARK: - Supporting Views

struct CashFlowRow: View {
    let label: String
    let amount: Decimal
    let icon: String

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)

                Text(label)
                    .font(.subheadline)
            }

            Spacer()

            Text(CurrencyFormatter.format(amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Enums

enum ReportTab: String, CaseIterable {
    case profitLoss = "P&L"
    case cashFlow = "Cash Flow"
    case taxReport = "Tax Report"
}

enum ReportingPeriod: String, CaseIterable {
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case thisQuarter = "This Quarter"
    case lastQuarter = "Last Quarter"
    case thisYear = "This Year"
    case custom = "Custom"

    func dateRange(year: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)?.addingTimeInterval(-1) ?? now
            return (start, end)

        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
            let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart) ?? now
            return (lastMonthStart, lastMonthEnd)

        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            let start = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth, day: 1)) ?? now
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start) ?? now
            return (start, end)

        case .lastQuarter:
            let month = calendar.component(.month, from: now)
            let currentQuarterStartMonth = ((month - 1) / 3) * 3 + 1
            let lastQuarterStartMonth = currentQuarterStartMonth - 3
            let yearForLastQuarter = lastQuarterStartMonth > 0 ? calendar.component(.year, from: now) : calendar.component(.year, from: now) - 1
            let adjustedMonth = lastQuarterStartMonth > 0 ? lastQuarterStartMonth : lastQuarterStartMonth + 12
            let start = calendar.date(from: DateComponents(year: yearForLastQuarter, month: adjustedMonth, day: 1)) ?? now
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start) ?? now
            return (start, end)

        case .thisYear:
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
            let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now
            return (start, end)

        case .custom:
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
            let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now
            return (start, end)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FinancialReportsView()
    }
}

// ScheduleCView.swift
// Schedule C (Form 1040) preparation for self-employed therapists

import SwiftUI

/// Schedule C tax form preparation view
struct ScheduleCView: View {
    @ObservedObject var incomeManager: IncomeManager
    @ObservedObject var expenseManager: ExpenseManager
    @ObservedObject var mileageManager: MileageManager

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var bookkeepingManager: BookkeepingManager {
        BookkeepingManager(expenseManager: expenseManager, incomeManager: incomeManager)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Year selector
                yearSelector

                // Schedule C overview
                scheduleC Overview

                // Part I: Income
                incomeSection

                // Part II: Expenses
                expensesSection

                // Part IV: Information on Vehicle
                vehicleSection

                // Export options
                exportSection
            }
            .padding()
        }
        .navigationTitle("Schedule C")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Components

    private var yearSelector: some View {
        HStack {
            Text("Tax Year")
                .font(.headline)

            Spacer()

            Picker("Year", selection: $selectedYear) {
                ForEach((2020...2030), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scheduleCOverview: some View {
        let taxReport = bookkeepingManager.taxReport(year: selectedYear)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Schedule C Summary")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("Principal Business")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Massage Therapy")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Business Code")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("812199")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Net Profit/Loss")
                        .font(.headline)
                    Spacer()
                    Text(CurrencyFormatter.format(taxReport.netTaxableIncome))
                        .font(.headline)
                        .foregroundStyle(taxReport.netTaxableIncome >= 0 ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var incomeSection: some View {
        let totalIncome = incomeManager.totalIncome(year: selectedYear)
        let incomeByCategory = incomeManager.incomesByCategory(
            from: Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!,
            to: Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        )

        return VStack(alignment: .leading, spacing: 16) {
            Text("Part I: Income")
                .font(.headline)

            VStack(spacing: 0) {
                ScheduleCLineItem(
                    line: "1",
                    description: "Gross receipts or sales",
                    amount: totalIncome
                )

                Divider()

                ForEach(incomeByCategory.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                    HStack {
                        Text("  • \(category.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(amount))
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if category != incomeByCategory.sorted(by: { $0.value > $1.value }).last?.key {
                        Divider()
                    }
                }

                Divider()

                ScheduleCLineItem(
                    line: "7",
                    description: "Gross income",
                    amount: totalIncome,
                    isBold: true
                )
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var expensesSection: some View {
        let expensesByCategory = expenseManager.expensesByCategory(
            from: Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!,
            to: Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        )

        let totalExpenses = expenseManager.totalExpenses(year: selectedYear)
        let mileageDeduction = mileageManager.totalDeduction(year: selectedYear)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Part II: Expenses")
                .font(.headline)

            VStack(spacing: 0) {
                // Common expense categories mapped to Schedule C lines
                ScheduleCLineItem(line: "8", description: "Advertising", amount: expensesByCategory[.marketing] ?? 0)
                Divider()
                ScheduleCLineItem(line: "9", description: "Car and truck expenses", amount: mileageDeduction)
                Divider()
                ScheduleCLineItem(line: "11", description: "Contract labor", amount: 0)
                Divider()
                ScheduleCLineItem(line: "15", description: "Insurance", amount: expensesByCategory[.insurance] ?? 0)
                Divider()
                ScheduleCLineItem(line: "16a", description: "Interest - Mortgage", amount: 0)
                Divider()
                ScheduleCLineItem(line: "17", description: "Legal and professional", amount: expensesByCategory[.legal] ?? 0)
                Divider()
                ScheduleCLineItem(line: "18", description: "Office expense", amount: expensesByCategory[.officeSupplies] ?? 0)
                Divider()
                ScheduleCLineItem(line: "20a", description: "Rent or lease - Equipment", amount: 0)
                Divider()
                ScheduleCLineItem(line: "20b", description: "Rent or lease - Rent", amount: expensesByCategory[.rent] ?? 0)
                Divider()
                ScheduleCLineItem(line: "22", description: "Supplies", amount: expensesByCategory[.massageSupplies] ?? 0)
                Divider()
                ScheduleCLineItem(line: "24a", description: "Travel", amount: expensesByCategory[.travel] ?? 0)
                Divider()
                ScheduleCLineItem(line: "25", description: "Utilities", amount: expensesByCategory[.utilities] ?? 0)
                Divider()
                ScheduleCLineItem(line: "27a", description: "Other expenses", amount: otherExpenses(expensesByCategory))
                Divider()
                ScheduleCLineItem(
                    line: "28",
                    description: "Total expenses",
                    amount: totalExpenses + mileageDeduction,
                    isBold: true
                )
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var vehicleSection: some View {
        let stats = mileageManager.getStatistics(
            from: Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!,
            to: Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        )

        return VStack(alignment: .leading, spacing: 16) {
            Text("Part IV: Information on Your Vehicle")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("Total business miles")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatMiles(stats.totalMiles))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Total mileage deduction")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(stats.totalDeduction))
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("Standard mileage rate")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formatRate(MileageLog.currentIRSRate(year: selectedYear)))/mile")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)

            Button {
                // TODO: Generate PDF
            } label: {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Export as PDF")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                // TODO: Export to CSV
            } label: {
                HStack {
                    Image(systemName: "tablecells.fill")
                    Text("Export to CSV")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helper Methods

    private func otherExpenses(_ expensesByCategory: [ExpenseCategory: Decimal]) -> Decimal {
        // Sum of categories not explicitly listed
        let listedCategories: [ExpenseCategory] = [
            .marketing, .insurance, .legal, .officeSupplies,
            .rent, .massageSupplies, .travel, .utilities
        ]

        return expensesByCategory
            .filter { !listedCategories.contains($0.key) }
            .values
            .reduce(0, +)
    }

    private func formatMiles(_ miles: Double) -> String {
        String(format: "%.0f mi", miles)
    }

    private func formatRate(_ rate: Decimal) -> String {
        let nsDecimal = rate as NSDecimalNumber
        return String(format: "$%.2f", nsDecimal.doubleValue)
    }
}

// MARK: - Schedule C Line Item

struct ScheduleCLineItem: View {
    let line: String
    let description: String
    let amount: Decimal
    var isBold: Bool = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                Text(description)
                    .font(isBold ? .subheadline.weight(.semibold) : .subheadline)
            }

            Spacer()

            Text(CurrencyFormatter.format(amount))
                .font(isBold ? .subheadline.weight(.bold) : .subheadline)
                .foregroundStyle(isBold ? .primary : .secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScheduleCView(
            incomeManager: IncomeManager(),
            expenseManager: ExpenseManager(),
            mileageManager: MileageManager()
        )
    }
}

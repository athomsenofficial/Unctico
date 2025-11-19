// TaxDashboardView.swift
// Comprehensive tax dashboard with quarterly estimates and deadlines

import SwiftUI

/// Tax management dashboard
struct TaxDashboardView: View {
    @StateObject private var incomeManager = IncomeManager()
    @StateObject private var expenseManager = ExpenseManager()
    @StateObject private var mileageManager = MileageManager()
    @StateObject private var deadlineManager = TaxDeadlineManager()

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedQuarter: Int = currentQuarter()
    @State private var filingStatus: FilingStatus = .single
    @State private var includeStateTax = false
    @State private var stateRate: Decimal = 0.05

    private var taxCalculator: TaxCalculator {
        TaxCalculator(incomeManager: incomeManager, expenseManager: expenseManager)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year selector
                yearSelector

                // Quarterly estimated tax
                quarterlyEstimateSection

                // Year-to-date summary
                ytdSummarySection

                // Upcoming deadlines
                upcomingDeadlinesSection

                // Quick actions
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("Tax Management")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filing Status", selection: $filingStatus) {
                        ForEach(FilingStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Toggle("Include State Tax", isOn: $includeStateTax)

                    if includeStateTax {
                        Stepper("State Rate: \(formatPercentage(stateRate))%", value: Binding(
                            get: { Double(truncating: stateRate as NSNumber) },
                            set: { stateRate = Decimal($0) }
                        ), in: 0...0.15, step: 0.01)
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }

    // MARK: - View Components

    private var yearSelector: some View {
        HStack {
            Button {
                selectedYear -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(String(selectedYear))
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                selectedYear += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quarterlyEstimateSection: some View {
        let estimate = taxCalculator.calculateQuarterlyEstimatedTax(
            quarter: selectedQuarter,
            year: selectedYear,
            filingStatus: filingStatus,
            includeStateTax: includeStateTax,
            stateRate: stateRate
        )

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Q\(selectedQuarter) Estimated Tax")
                    .font(.headline)

                Spacer()

                Picker("Quarter", selection: $selectedQuarter) {
                    ForEach(1...4, id: \.self) { quarter in
                        Text("Q\(quarter)").tag(quarter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            // Quarterly payment amount
            VStack(spacing: 8) {
                Text("Quarterly Payment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(CurrencyFormatter.format(estimate.quarterlyPayment))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Breakdown
            VStack(spacing: 12) {
                HStack {
                    Text("Net Profit")
                    Spacer()
                    Text(CurrencyFormatter.format(estimate.netProfit))
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Self-Employment Tax")
                    Spacer()
                    Text(CurrencyFormatter.format(estimate.selfEmploymentTax))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Federal Income Tax")
                    Spacer()
                    Text(CurrencyFormatter.format(estimate.federalIncomeTax))
                        .fontWeight(.semibold)
                }

                if includeStateTax {
                    HStack {
                        Text("State Tax")
                        Spacer()
                        Text(CurrencyFormatter.format(estimate.stateTax))
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                HStack {
                    Text("Total Annual Tax")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(CurrencyFormatter.format(estimate.totalAnnualTax))
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var ytdSummarySection: some View {
        let ytd = taxCalculator.calculateYearToDateEstimatedTax(
            year: selectedYear,
            filingStatus: filingStatus,
            includeStateTax: includeStateTax,
            stateRate: stateRate
        )

        return VStack(alignment: .leading, spacing: 16) {
            Text("Year-to-Date Summary")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("Gross Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(ytd.grossIncome))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 8) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(ytd.expenses))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("Net Profit")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(ytd.netProfit))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 8) {
                    Text("Total Tax")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(ytd.totalTax))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Text("Effective Tax Rate")
                Spacer()
                Text("\(formatPercentage(ytd.effectiveTaxRate))%")
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var upcomingDeadlinesSection: some View {
        let upcoming = deadlineManager.upcomingDeadlines().prefix(5)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Deadlines")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    TaxDeadlinesView(deadlineManager: deadlineManager)
                } label: {
                    Text("View All")
                        .font(.subheadline)
                }
            }

            if upcoming.isEmpty {
                Text("No upcoming deadlines")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcoming)) { deadline in
                        DeadlineRowView(deadline: deadline)

                        if deadline.id != upcoming.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    MileageLogView(mileageManager: mileageManager)
                } label: {
                    QuickActionCard(
                        icon: "car.fill",
                        title: "Mileage Log",
                        color: .blue
                    )
                }

                NavigationLink {
                    ScheduleCView(
                        incomeManager: incomeManager,
                        expenseManager: expenseManager,
                        mileageManager: mileageManager
                    )
                } label: {
                    QuickActionCard(
                        icon: "doc.text.fill",
                        title: "Schedule C",
                        color: .purple
                    )
                }

                NavigationLink {
                    TaxDeadlinesView(deadlineManager: deadlineManager)
                } label: {
                    QuickActionCard(
                        icon: "calendar.circle.fill",
                        title: "Deadlines",
                        color: .orange
                    )
                }

                QuickActionCard(
                    icon: "doc.badge.plus",
                    title: "Form 1099",
                    color: .green
                )
            }
        }
    }

    // MARK: - Helper Methods

    private static func currentQuarter() -> Int {
        let month = Calendar.current.component(.month, from: Date())
        return (month - 1) / 3 + 1
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        return String(format: "%.1f", nsDecimal.doubleValue)
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DeadlineRowView: View {
    let deadline: TaxDeadline

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(deadline.dueDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: deadline.status.icon)
                        .font(.caption)

                    Text(deadline.status.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(statusColor(deadline.status))

                Text("\(deadline.daysUntil) days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func statusColor(_ status: DeadlineStatus) -> Color {
        switch status.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaxDashboardView()
    }
}

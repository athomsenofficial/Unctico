// EnhancedBillingView.swift
// Complete billing interface with invoices, payments, and reports

import SwiftUI

/// Enhanced billing view with full invoice and payment management
struct EnhancedBillingView: View {

    @StateObject private var invoiceManager = InvoiceManager()
    @StateObject private var paymentManager: PaymentManager

    @State private var selectedTab: BillingTab = .invoices

    init() {
        let invoiceMgr = InvoiceManager()
        self._invoiceManager = StateObject(wrappedValue: invoiceMgr)
        self._paymentManager = StateObject(wrappedValue: PaymentManager(invoiceManager: invoiceMgr))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                billingTabSelector

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    InvoiceListView()
                        .tag(BillingTab.invoices)

                    PaymentsListView(paymentManager: paymentManager)
                        .tag(BillingTab.payments)

                    ReportsView(invoiceManager: invoiceManager, paymentManager: paymentManager)
                        .tag(BillingTab.reports)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Billing")
        }
    }

    // MARK: - View Components

    private var billingTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(BillingTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                }
            }
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - Payments List View

struct PaymentsListView: View {
    @ObservedObject var paymentManager: PaymentManager

    @State private var searchText = ""

    var body: some View {
        Group {
            if paymentManager.payments.isEmpty {
                emptyState
            } else {
                paymentsList
            }
        }
        .searchable(text: $searchText, prompt: "Search payments")
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Payments")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Payments will appear here once recorded")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var paymentsList: some View {
        List {
            ForEach(paymentManager.payments.sorted { $0.paymentDate > $1.paymentDate }) { payment in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: payment.paymentMethod.icon)
                                .foregroundStyle(.blue)

                            Text(payment.paymentMethod.rawValue)
                                .font(.headline)
                        }

                        Text(payment.paymentDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let refNumber = payment.referenceNumber {
                            Text("Ref: \(refNumber)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.format(payment.amount))
                            .font(.headline)

                        HStack(spacing: 4) {
                            Image(systemName: payment.status.icon)
                                .font(.caption)

                            Text(payment.status.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(statusColor(payment.status))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func statusColor(_ status: PaymentStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .refunded:
            return .purple
        }
    }
}

// MARK: - Reports View

struct ReportsView: View {
    @ObservedObject var invoiceManager: InvoiceManager
    @ObservedObject var paymentManager: PaymentManager

    @State private var selectedPeriod: ReportPeriod = .thisMonth

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Revenue summary
                revenueSummary

                // Invoice statistics
                invoiceStatistics

                // Payment statistics
                paymentStatistics

                // Outstanding invoices
                outstandingSection
            }
            .padding(.bottom)
        }
    }

    private var revenueSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Summary")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                RevenueCard(
                    title: "Total Revenue",
                    amount: totalRevenue,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )

                Divider()

                RevenueCard(
                    title: "Total Collected",
                    amount: totalCollected,
                    icon: "checkmark.seal.fill",
                    color: .blue
                )

                Divider()

                RevenueCard(
                    title: "Outstanding",
                    amount: totalOutstanding,
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private var invoiceStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Statistics")
                .font(.headline)
                .padding(.horizontal)

            let stats = invoiceManager.getStatistics()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total", value: "\(stats.totalInvoices)", icon: "doc.text.fill", color: .blue)
                StatCard(title: "Paid", value: "\(stats.paidInvoices)", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "Pending", value: "\(stats.sentInvoices)", icon: "clock.fill", color: .orange)
                StatCard(title: "Overdue", value: "\(stats.overdueInvoices)", icon: "exclamationmark.triangle.fill", color: .red)
            }
            .padding(.horizontal)
        }
    }

    private var paymentStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Statistics")
                .font(.headline)
                .padding(.horizontal)

            let stats = paymentManager.getStatistics()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Total Payments", value: "\(stats.totalPayments)", icon: "creditcard.fill", color: .blue)
                StatCard(title: "Completed", value: "\(stats.completedPayments)", icon: "checkmark.seal.fill", color: .green)
                StatCard(title: "Pending", value: "\(stats.pendingPayments)", icon: "clock.fill", color: .orange)
                StatCard(title: "Refunded", value: "\(stats.refundedPayments)", icon: "arrow.uturn.backward", color: .purple)
            }
            .padding(.horizontal)
        }
    }

    private var outstandingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outstanding Invoices")
                .font(.headline)
                .padding(.horizontal)

            let outstanding = invoiceManager.outstandingInvoices()

            if outstanding.isEmpty {
                Text("No outstanding invoices")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(outstanding.prefix(5)) { invoice in
                        HStack {
                            Text(invoice.invoiceNumber)
                                .font(.subheadline)

                            Spacer()

                            Text(CurrencyFormatter.format(invoice.balanceRemaining))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(invoice.isOverdue ? .red : .primary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Computed Properties

    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return (start, end)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return (start, end)

        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return (start, end)

        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? now
            return (start, end)
        }
    }

    private var totalRevenue: Decimal {
        invoiceManager.totalRevenue(from: dateRange.start, to: dateRange.end)
    }

    private var totalCollected: Decimal {
        paymentManager.totalPayments(from: dateRange.start, to: dateRange.end)
    }

    private var totalOutstanding: Decimal {
        invoiceManager.totalOutstanding()
    }
}

// MARK: - Supporting Views

struct RevenueCard: View {
    let title: String
    let amount: Decimal
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(CurrencyFormatter.format(amount))
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Report Period

enum ReportPeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
}

// MARK: - Preview

#Preview {
    EnhancedBillingView()
}

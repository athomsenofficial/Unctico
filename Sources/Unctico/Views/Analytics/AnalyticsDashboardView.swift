import Combine
import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var revenueMetrics: RevenueMetrics?
    @State private var serviceProfitability: [ServiceProfitability] = []
    @State private var revenueForecast: [RevenueForecast] = []

    enum TimePeriod: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    PeriodSelectorView(selectedPeriod: $selectedPeriod)
                        .padding(.horizontal)

                    // Revenue Overview
                    if let metrics = revenueMetrics {
                        RevenueOverviewCard(metrics: metrics)
                            .padding(.horizontal)
                    }

                    // Key Metrics Grid
                    KeyMetricsGrid(metrics: revenueMetrics)
                        .padding(.horizontal)

                    // Service Profitability Chart
                    ServiceProfitabilitySection(profitability: serviceProfitability)
                        .padding(.horizontal)

                    // Revenue Forecast
                    RevenueForecastSection(forecast: revenueForecast)
                        .padding(.horizontal)

                    // Client Analytics
                    ClientAnalyticsSection()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color.massageBackground.opacity(0.3))
            .onAppear(perform: loadAnalytics)
            .onChange(of: selectedPeriod) { _ in
                loadAnalytics()
            }
        }
    }

    private func loadAnalytics() {
        let period = getDateRange(for: selectedPeriod)
        revenueMetrics = analyticsService.calculateRevenueMetrics(for: period)
        serviceProfitability = analyticsService.calculateServiceProfitability()
        revenueForecast = analyticsService.forecastRevenue(months: 3)
    }

    private func getDateRange(for period: TimePeriod) -> DateRange {
        switch period {
        case .thisWeek:
            return DateRange(
                range: TransactionRepository.shared.getThisWeekRange(),
                days: 7
            )
        case .thisMonth:
            return DateRange.thisMonth()
        case .thisYear:
            return DateRange(
                range: TransactionRepository.shared.getThisYearRange(),
                days: 365
            )
        }
    }
}

struct PeriodSelectorView: View {
    @Binding var selectedPeriod: AnalyticsDashboardView.TimePeriod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsDashboardView.TimePeriod.allCases, id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.tranquilTeal : Color.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RevenueOverviewCard: View {
    let metrics: RevenueMetrics

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Revenue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(metrics.totalRevenue, format: .currency(code: "USD"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.tranquilTeal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: metrics.revenueGrowth >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(Int(abs(metrics.revenueGrowth)))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(metrics.revenueGrowth >= 0 ? .green : .red)

                    Text("vs. previous period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 24) {
                StatItem(
                    label: "Expenses",
                    value: metrics.totalExpenses,
                    format: .currency
                )

                Divider()
                    .frame(height: 30)

                StatItem(
                    label: "Net Income",
                    value: metrics.netIncome,
                    format: .currency,
                    valueColor: metrics.netIncome >= 0 ? .soothingGreen : .red
                )

                Divider()
                    .frame(height: 30)

                StatItem(
                    label: "Profit Margin",
                    value: metrics.profitMargin,
                    format: .percentage,
                    valueColor: .tranquilTeal
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct StatItem: View {
    let label: String
    let value: Double
    let format: StatFormat
    var valueColor: Color = .primary

    enum StatFormat {
        case currency
        case percentage
        case number
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(formattedValue)
                .font(.headline)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedValue: String {
        switch format {
        case .currency:
            return value.formatted(.currency(code: "USD"))
        case .percentage:
            return String(format: "%.1f%%", value)
        case .number:
            return String(format: "%.0f", value)
        }
    }
}

struct KeyMetricsGrid: View {
    let metrics: RevenueMetrics?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AnalyticsMetricCard(
                title: "Daily Average",
                value: metrics?.averageDailyRevenue ?? 0,
                icon: "calendar",
                color: .calmingBlue
            )

            AnalyticsMetricCard(
                title: "Projected Monthly",
                value: metrics?.projectedMonthlyRevenue ?? 0,
                icon: "chart.line.uptrend.xyaxis",
                color: .soothingGreen
            )
        }
    }
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(value, format: .currency(code: "USD"))
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ServiceProfitabilitySection: View {
    let profitability: [ServiceProfitability]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Profitability")
                .font(.headline)

            if profitability.isEmpty {
                EmptyStateView(message: "No data available")
            } else {
                VStack(spacing: 8) {
                    ForEach(profitability.prefix(5), id: \.serviceType) { service in
                        ServiceProfitRow(service: service)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }
}

struct ServiceProfitRow: View {
    let service: ServiceProfitability

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.serviceType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(service.count) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(service.totalProfit, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.soothingGreen)

                Text("\(Int(service.profitMargin))% margin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RevenueForecastSection: View {
    let forecast: [RevenueForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Revenue Forecast")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(forecast, id: \.month) { monthForecast in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(monthForecast.month, style: .date)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Confidence: \(Int(monthForecast.confidenceLevel * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(monthForecast.predictedRevenue, format: .currency(code: "USD"))
                            .font(.headline)
                            .foregroundColor(.tranquilTeal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct ClientAnalyticsSection: View {
    @State private var retentionMetrics: RetentionMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client Analytics")
                .font(.headline)

            if let metrics = retentionMetrics {
                HStack(spacing: 16) {
                    ClientMetricCard(
                        title: "Total Clients",
                        value: metrics.totalClients,
                        icon: "person.2.fill",
                        color: .calmingBlue
                    )

                    ClientMetricCard(
                        title: "Active",
                        value: metrics.activeClients,
                        icon: "checkmark.circle.fill",
                        color: .soothingGreen
                    )
                }

                HStack(spacing: 16) {
                    ClientMetricCard(
                        title: "Retention Rate",
                        value: Int(metrics.retentionRate),
                        suffix: "%",
                        icon: "heart.fill",
                        color: .tranquilTeal
                    )

                    ClientMetricCard(
                        title: "Churn Rate",
                        value: Int(metrics.churnRate),
                        suffix: "%",
                        icon: "arrow.down.circle.fill",
                        color: .orange
                    )
                }
            }
        }
        .onAppear {
            retentionMetrics = AnalyticsService.shared.calculateRetentionMetrics()
        }
    }
}

struct ClientMetricCard: View {
    let title: String
    let value: Int
    var suffix: String = ""
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text("\(value)\(suffix)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

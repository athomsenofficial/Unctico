import SwiftUI
import Charts

/// Comprehensive analytics dashboard for practice performance
struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedPeriod: AnalyticsPeriod = .thisMonth
    @State private var analytics: PracticeAnalytics?
    @State private var kpis: [KPI] = []
    @State private var showingPeriodPicker = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    PeriodSelectorView(
                        selectedPeriod: $selectedPeriod,
                        showingPicker: $showingPeriodPicker,
                        customStart: $customStartDate,
                        customEnd: $customEndDate
                    )

                    if let analytics = analytics {
                        // KPI Grid
                        KPIGridView(kpis: kpis)

                        // Revenue Section
                        RevenueSectionView(metrics: analytics.revenueMetrics)

                        // Client Section
                        ClientSectionView(metrics: analytics.clientMetrics)

                        // Appointment Section
                        AppointmentSectionView(metrics: analytics.appointmentMetrics)

                        // Treatment Section
                        TreatmentSectionView(metrics: analytics.treatmentMetrics)

                        // Outcome Section
                        OutcomeSectionView(metrics: analytics.outcomeMetrics)
                    } else {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, maxHeight: 300)
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // TODO: Export as PDF
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            // TODO: Email report
                        } label: {
                            Label("Email Report", systemImage: "envelope")
                        }

                        Button {
                            refreshData()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                refreshData()
            }
            .onChange(of: selectedPeriod) { _ in
                refreshData()
            }
        }
    }

    private func refreshData() {
        let newAnalytics = analyticsService.generateAnalytics(
            for: selectedPeriod,
            customStart: selectedPeriod == .custom ? customStartDate : nil,
            customEnd: selectedPeriod == .custom ? customEndDate : nil
        )
        analytics = newAnalytics
        kpis = analyticsService.generateKPIs(from: newAnalytics)
    }
}

// MARK: - Period Selector

struct PeriodSelectorView: View {
    @Binding var selectedPeriod: AnalyticsPeriod
    @Binding var showingPicker: Bool
    @Binding var customStart: Date
    @Binding var customEnd: Date

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnalyticsPeriod.allCases.filter { $0 != .custom }, id: \.self) { period in
                        Button {
                            selectedPeriod = period
                        } label: {
                            PeriodChip(
                                period: period,
                                isSelected: selectedPeriod == period
                            )
                        }
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        PeriodChip(
                            period: .custom,
                            isSelected: selectedPeriod == .custom
                        )
                    }
                }
                .padding(.horizontal)
            }

            if selectedPeriod == .custom {
                HStack {
                    DatePicker("From", selection: $customStart, displayedComponents: [.date])
                    DatePicker("To", selection: $customEnd, displayedComponents: [.date])
                }
                .font(.caption)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct PeriodChip: View {
    let period: AnalyticsPeriod
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: period.icon)
            Text(period.rawValue)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

// MARK: - KPI Grid

struct KPIGridView: View {
    let kpis: [KPI]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Performance Indicators")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(kpis) { kpi in
                    KPICard(kpi: kpi)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct KPICard: View {
    let kpi: KPI

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: kpi.icon)
                    .font(.title2)
                    .foregroundColor(colorForName(kpi.color))
                Spacer()
                if let change = kpi.change {
                    HStack(spacing: 4) {
                        Image(systemName: kpi.trend.icon)
                        Text("\(abs(change).formatted(.percent.precision(.fractionLength(0))))")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(colorForName(kpi.trend.color))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(kpi.value)
                    .font(.title.weight(.bold))
                    .foregroundColor(colorForName(kpi.color))

                Text(kpi.title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let subtitle = kpi.subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Revenue Section

struct RevenueSectionView: View {
    let metrics: RevenueMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Revenue", icon: "dollarsign.circle.fill", color: .green)

            // Revenue summary
            HStack(spacing: 16) {
                MetricBox(
                    title: "Total Revenue",
                    value: formatCurrency(metrics.totalRevenue),
                    icon: "banknote.fill",
                    color: .green
                )

                MetricBox(
                    title: "Avg. Transaction",
                    value: formatCurrency(metrics.averageTransactionValue),
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }

            // Revenue by service chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Revenue by Service")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(metrics.revenueByService.sorted { $0.value > $1.value }.prefix(5), id: \.key) { service, amount in
                        BarMark(
                            x: .value("Revenue", amount),
                            y: .value("Service", service)
                        )
                        .foregroundStyle(.green.gradient)
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Revenue by payment method
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Methods")
                    .font(.subheadline.weight(.semibold))

                ForEach(metrics.revenueByPaymentMethod.sorted { $0.value > $1.value }, id: \.key) { method, amount in
                    HStack {
                        Image(systemName: method.icon)
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text(method.rawValue)
                            .font(.subheadline)

                        Spacer()

                        Text(formatCurrency(amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Client Section

struct ClientSectionView: View {
    let metrics: ClientMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Clients", icon: "person.3.fill", color: .blue)

            // Client summary
            HStack(spacing: 16) {
                MetricBox(
                    title: "Total Clients",
                    value: "\(metrics.totalClients)",
                    icon: "person.fill",
                    color: .blue
                )

                MetricBox(
                    title: "New Clients",
                    value: "\(metrics.newClients)",
                    icon: "person.badge.plus",
                    color: .green
                )
            }

            HStack(spacing: 16) {
                MetricBox(
                    title: "Active",
                    value: "\(metrics.activeClients)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                MetricBox(
                    title: "Retention",
                    value: metrics.retentionRate.formatted(.percent.precision(.fractionLength(0))),
                    icon: "arrow.clockwise",
                    color: .orange
                )
            }

            // Clients by age group
            VStack(alignment: .leading, spacing: 8) {
                Text("Clients by Age Group")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(ClientMetrics.AgeGroup.allCases, id: \.self) { group in
                        BarMark(
                            x: .value("Count", metrics.clientsByAgeGroup[group] ?? 0),
                            y: .value("Age Group", group.rawValue)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Clients by source
            VStack(alignment: .leading, spacing: 8) {
                Text("Client Acquisition Source")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(metrics.clientsBySource.sorted { $0.value > $1.value }, id: \.key) { source, count in
                        SectorMark(
                            angle: .value("Count", count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Source", source))
                        .annotation(position: .overlay) {
                            Text("\(count)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 200)

                // Legend
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(metrics.clientsBySource.sorted { $0.value > $1.value }, id: \.key) { source, count in
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text(source)
                                .font(.caption)
                            Spacer()
                            Text("\(count)")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Appointment Section

struct AppointmentSectionView: View {
    let metrics: AppointmentMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Appointments", icon: "calendar.badge.clock", color: .purple)

            // Appointment summary
            HStack(spacing: 16) {
                MetricBox(
                    title: "Total",
                    value: "\(metrics.totalAppointments)",
                    icon: "calendar",
                    color: .purple
                )

                MetricBox(
                    title: "Completed",
                    value: "\(metrics.completedAppointments)",
                    icon: "checkmark.circle",
                    color: .green
                )
            }

            HStack(spacing: 16) {
                MetricBox(
                    title: "Completion Rate",
                    value: metrics.completionRate.formatted(.percent.precision(.fractionLength(0))),
                    icon: "chart.pie.fill",
                    color: .green
                )

                MetricBox(
                    title: "Utilization",
                    value: metrics.utilizationRate.formatted(.percent.precision(.fractionLength(0))),
                    icon: "gauge.high",
                    color: .blue
                )
            }

            // Appointments by day of week
            VStack(alignment: .leading, spacing: 8) {
                Text("Appointments by Day of Week")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(metrics.appointmentsByDayOfWeek.sorted { $0.key < $1.key }, id: \.key) { day, count in
                        BarMark(
                            x: .value("Day", dayName(for: day)),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(.purple.gradient)
                    }
                }
                .frame(height: 200)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Busiest day: \(metrics.busiestDay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Appointments by hour
            VStack(alignment: .leading, spacing: 8) {
                Text("Appointments by Hour")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(metrics.appointmentsByHourOfDay.sorted { $0.key < $1.key }, id: \.key) { hour, count in
                        LineMark(
                            x: .value("Hour", "\(hour):00"),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(.purple.gradient)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Hour", "\(hour):00"),
                            y: .value("Count", count)
                        )
                        .foregroundStyle(.purple)
                    }
                }
                .frame(height: 200)

                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Peak hour: \(metrics.busiestHour)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func dayName(for day: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[day - 1]
    }
}

// MARK: - Treatment Section

struct TreatmentSectionView: View {
    let metrics: TreatmentMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Treatments", icon: "heart.text.square.fill", color: .pink)

            // Treatment summary
            HStack(spacing: 16) {
                MetricBox(
                    title: "Total Sessions",
                    value: "\(metrics.totalTreatmentSessions)",
                    icon: "hand.raised.fill",
                    color: .pink
                )

                MetricBox(
                    title: "Satisfaction",
                    value: String(format: "%.1f/5.0", metrics.clientSatisfactionScore),
                    icon: "star.fill",
                    color: .yellow
                )
            }

            HStack(spacing: 16) {
                MetricBox(
                    title: "Avg. Pain ↓",
                    value: String(format: "%.1f pts", metrics.averagePainReduction),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )

                MetricBox(
                    title: "Referrals Made",
                    value: "\(metrics.referralsMade)",
                    icon: "arrow.turn.up.right",
                    color: .blue
                )
            }

            // Treatments by type
            VStack(alignment: .leading, spacing: 8) {
                Text("Treatment Types")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    ForEach(metrics.treatmentsByType.sorted { $0.value > $1.value }, id: \.key) { type, count in
                        BarMark(
                            x: .value("Count", count),
                            y: .value("Type", type)
                        )
                        .foregroundStyle(.pink.gradient)
                    }
                }
                .frame(height: 180)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Outcome Section

struct OutcomeSectionView: View {
    let metrics: OutcomeMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Outcomes", icon: "chart.line.uptrend.xyaxis", color: .green)

            // Outcome summary
            HStack(spacing: 16) {
                MetricBox(
                    title: "Assessments",
                    value: "\(metrics.totalOutcomeAssessments)",
                    icon: "doc.text.fill",
                    color: .blue
                )

                MetricBox(
                    title: "Improvement Rate",
                    value: metrics.improvementRate.formatted(.percent.precision(.fractionLength(0))),
                    icon: "arrow.up.right.circle.fill",
                    color: .green
                )
            }

            // Improvement breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Client Progress")
                    .font(.subheadline.weight(.semibold))

                Chart {
                    SectorMark(
                        angle: .value("Count", metrics.clientsShowingImprovement),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.green)
                    .annotation(position: .overlay) {
                        Text("\(metrics.clientsShowingImprovement)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    }

                    SectorMark(
                        angle: .value("Count", metrics.clientsShowingNoChange),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.yellow)
                    .annotation(position: .overlay) {
                        Text("\(metrics.clientsShowingNoChange)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    }

                    SectorMark(
                        angle: .value("Count", metrics.clientsShowingDeclne),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(.red)
                    .annotation(position: .overlay) {
                        Text("\(metrics.clientsShowingDeclne)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 200)

                // Legend
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Text("Improved")
                        Spacer()
                        Text("\(metrics.clientsShowingImprovement)")
                            .font(.caption.weight(.semibold))
                    }
                    HStack {
                        Circle().fill(.yellow).frame(width: 8, height: 8)
                        Text("No Change")
                        Spacer()
                        Text("\(metrics.clientsShowingNoChange)")
                            .font(.caption.weight(.semibold))
                    }
                    HStack {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("Declined")
                        Spacer()
                        Text("\(metrics.clientsShowingDeclne)")
                            .font(.caption.weight(.semibold))
                    }
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            HStack(spacing: 16) {
                MetricBox(
                    title: "Goal Attainment",
                    value: metrics.goalAttainmentRate.formatted(.percent.precision(.fractionLength(0))),
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.title2.weight(.bold))
        }
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AnalyticsDashboardView()
}

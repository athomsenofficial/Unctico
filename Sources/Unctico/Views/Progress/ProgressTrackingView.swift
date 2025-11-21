import SwiftUI
import Charts

/// View for tracking and visualizing client progress over time
struct ProgressTrackingView: View {
    @StateObject private var service = ProgressTrackingService()
    @State private var selectedReport: ProgressReport?
    @State private var showingGenerateReport = false
    @State private var searchText = ""

    var filteredReports: [ProgressReport] {
        // Filter logic can be added here if needed
        service.progressReports
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredReports.isEmpty {
                        EmptyProgressStateView()
                    } else {
                        ForEach(filteredReports) { report in
                            ProgressReportCard(report: report)
                                .onTapGesture {
                                    selectedReport = report
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress Tracking")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGenerateReport = true
                    } label: {
                        Label("Generate Report", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .sheet(isPresented: $showingGenerateReport) {
                GenerateProgressReportView(service: service)
            }
            .sheet(item: $selectedReport) { report in
                ProgressReportDetailView(report: report)
            }
        }
    }
}

struct ProgressReportCard: View {
    let report: ProgressReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Report")
                        .font(.headline)

                    Text("\(report.startDate, style: .date) - \(report.endDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(report.sessionCount) sessions")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            Divider()

            // Key metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricBadge(
                    title: "Pain Reduction",
                    value: "\(Int(report.metrics.painReductionPercentage))%",
                    trend: report.trends.painTrend
                )

                MetricBadge(
                    title: "Treatment Response",
                    value: "\(Int(report.metrics.treatmentResponseRate))%",
                    trend: report.trends.treatmentResponseTrend
                )
            }

            // Recommendations count
            if !report.recommendations.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)

                    Text("\(report.recommendations.count) recommendations")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricBadge: View {
    let title: String
    let value: String
    let trend: TrendDirection

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .bold()

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ProgressReportDetailView: View {
    let report: ProgressReport

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Overview
                    OverviewSection(report: report)

                    // Metrics
                    MetricsSection(metrics: report.metrics)

                    // Trends
                    TrendsSection(trends: report.trends)

                    // Recommendations
                    RecommendationsSection(recommendations: report.recommendations)
                }
                .padding()
            }
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct OverviewSection: View {
    let report: ProgressReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)

            VStack(spacing: 8) {
                InfoRow(label: "Period", value: "\(report.startDate, style: .date) - \(report.endDate, style: .date)")
                InfoRow(label: "Sessions", value: "\(report.sessionCount)")
                InfoRow(label: "Generated", value: "\(report.generatedDate, style: .date)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricsSection: View {
    let metrics: ProgressMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metrics")
                .font(.headline)

            VStack(spacing: 16) {
                // Pain metrics
                MetricGroup(title: "Pain Management") {
                    MetricRow(
                        label: "Initial Pain",
                        value: "\(metrics.initialPainLevel)/10",
                        color: .red
                    )
                    MetricRow(
                        label: "Current Pain",
                        value: "\(metrics.currentPainLevel)/10",
                        color: metrics.currentPainLevel < metrics.initialPainLevel ? .green : .red
                    )
                    MetricRow(
                        label: "Reduction",
                        value: "\(Int(metrics.painReductionPercentage))%",
                        color: .green
                    )
                }

                // Lifestyle metrics
                MetricGroup(title: "Lifestyle Factors") {
                    MetricRow(
                        label: "Sleep Improvement",
                        value: metrics.sleepQualityImprovement > 0 ? "+\(metrics.sleepQualityImprovement)" : "\(metrics.sleepQualityImprovement)",
                        color: metrics.sleepQualityImprovement > 0 ? .green : .red
                    )
                    MetricRow(
                        label: "Stress Reduction",
                        value: "\(metrics.stressReduction) points",
                        color: metrics.stressReduction > 0 ? .green : .red
                    )
                }

                // Treatment metrics
                MetricGroup(title: "Treatment Outcomes") {
                    MetricRow(
                        label: "Response Rate",
                        value: "\(Int(metrics.treatmentResponseRate))%",
                        color: .blue
                    )
                    MetricRow(
                        label: "Functional Improvement",
                        value: "\(Int(metrics.functionalImprovement))%",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TrendsSection: View {
    let trends: ProgressTrends

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(.headline)

            VStack(spacing: 8) {
                TrendRow(label: "Pain", trend: trends.painTrend)
                TrendRow(label: "Stress", trend: trends.stressTrend)
                TrendRow(label: "Sleep", trend: trends.sleepTrend)
                TrendRow(label: "Muscle Tension", trend: trends.muscleTensionTrend)
                TrendRow(label: "Treatment Response", trend: trends.treatmentResponseTrend)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsSection: View {
    let recommendations: [ProgressRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            ForEach(recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: ProgressRecommendation

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(recommendation.priority.rawValue)
                                .font(.caption)
                                .foregroundColor(recommendation.priority.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(recommendation.priority.color.opacity(0.1))
                                .cornerRadius(6)

                            Text(recommendation.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(recommendation.title)
                            .font(.headline)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(recommendation.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Items:")
                            .font(.subheadline)
                            .bold()

                        ForEach(recommendation.actionItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.blue)

                                Text(item)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .bold()

            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }
}

struct TrendRow: View {
    let label: String
    let trend: TrendDirection

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
                Text(trend.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(trend.color)
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
        }
    }
}

struct EmptyProgressStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Progress Reports")
                .font(.headline)

            Text("Generate your first progress report to track client improvements over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
}

struct GenerateProgressReportView: View {
    let service: ProgressTrackingService

    @State private var selectedClientId: UUID?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Client") {
                    // TODO: Add client picker
                    Text("Select client to generate report")
                        .foregroundColor(.secondary)
                }

                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    Button("Generate Report") {
                        // TODO: Get actual client ID
                        let dummyClientId = UUID()
                        _ = service.generateProgressReport(
                            for: dummyClientId,
                            startDate: startDate,
                            endDate: endDate
                        )
                        dismiss()
                    }
                    .disabled(selectedClientId == nil)
                }
            }
            .navigationTitle("Generate Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProgressTrackingView()
}

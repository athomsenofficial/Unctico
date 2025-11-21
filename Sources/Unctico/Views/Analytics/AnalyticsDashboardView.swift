import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showingReports = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Key metrics (placeholder - would be calculated from real data)
                    MetricsOverviewSection()
                    
                    // Alerts
                    if !analyticsService.alerts.isEmpty {
                        AlertsSection(alerts: analyticsService.alerts)
                    }
                    
                    // Goals
                    if !analyticsService.goals.isEmpty {
                        GoalsSection(goals: analyticsService.getActiveGoals())
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingReports = true }) {
                        Image(systemName: "doc.text")
                    }
                }
            }
            .sheet(isPresented: $showingReports) {
                ReportsView()
            }
        }
    }
}

struct MetricsOverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCard(title: "Revenue", value: "$5,420", change: "+12%", isPositive: true, icon: "dollarsign.circle.fill", color: .green)
                MetricCard(title: "Clients", value: "42", change: "+8", isPositive: true, icon: "person.3.fill", color: .blue)
                MetricCard(title: "Appointments", value: "89", change: "+15%", isPositive: true, icon: "calendar.fill", color: .purple)
                MetricCard(title: "Profit Margin", value: "38%", change: "+2%", isPositive: true, icon: "chart.line.uptrend.xyaxis", color: .orange)
            }
            .padding(.horizontal)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(isPositive ? .green : .red)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AlertsSection: View {
    let alerts: [BusinessAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Business Alerts")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(alerts) { alert in
                AlertRow(alert: alert)
            }
        }
        .padding(.vertical)
    }
}

struct AlertRow: View {
    let alert: BusinessAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundColor(Color(alert.severity.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.recommendedAction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(alert.severity.color).opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct GoalsSection: View {
    let goals: [BusinessGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Goals")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(goals) { goal in
                GoalRow(goal: goal)
            }
        }
    }
}

struct GoalRow: View {
    let goal: BusinessGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundColor(Color(goal.status.color))
                
                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(goal.progress))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(goal.status.color))
            }
            
            ProgressView(value: goal.progress, total: 100)
                .tint(Color(goal.status.color))
            
            HStack {
                Text("\(goal.currentValue, specifier: "%.0f") / \(goal.targetValue, specifier: "%.0f") \(goal.metric)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if goal.daysRemaining > 0 {
                    Text("\(goal.daysRemaining) days left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ReportsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedReport: ReportType = .comprehensive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ReportType.allCases, id: \.self) { reportType in
                    Button(action: { selectedReport = reportType }) {
                        HStack {
                            Image(systemName: reportType.icon)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reportType.rawValue)
                                    .font(.headline)
                                
                                Text(reportType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AnalyticsDashboardView()
}

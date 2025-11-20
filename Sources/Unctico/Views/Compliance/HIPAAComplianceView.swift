import SwiftUI

struct HIPAAComplianceView: View {
    @StateObject private var auditLogRepository = AuditLogRepository()
    @StateObject private var complianceService: HIPAAComplianceService
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var exportStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var exportEndDate = Date()

    init() {
        let auditRepo = AuditLogRepository()
        _auditLogRepository = StateObject(wrappedValue: auditRepo)
        _complianceService = StateObject(wrappedValue: HIPAAComplianceService(auditLogRepository: auditRepo))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Audit Logs").tag(1)
                    Text("Access Control").tag(2)
                    Text("Security").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab(
                        auditLogRepository: auditLogRepository,
                        complianceService: complianceService
                    )
                    .tag(0)

                    AuditLogsTab(
                        auditLogRepository: auditLogRepository,
                        showingExportSheet: $showingExportSheet
                    )
                    .tag(1)

                    AccessControlTab(complianceService: complianceService)
                        .tag(2)

                    SecurityTab(complianceService: complianceService)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("HIPAA Compliance")
            .sheet(isPresented: $showingExportSheet) {
                ExportAuditLogsSheet(
                    auditLogRepository: auditLogRepository,
                    startDate: $exportStartDate,
                    endDate: $exportEndDate,
                    isPresented: $showingExportSheet
                )
            }
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var auditLogRepository: AuditLogRepository
    @ObservedObject var complianceService: HIPAAComplianceService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Compliance Status Card
                ComplianceStatusCard(complianceService: complianceService)

                // Quick Stats
                QuickStatsSection(auditLogRepository: auditLogRepository)

                // Security Concerns
                SecurityConcernsSection(complianceService: complianceService)

                // Encryption Status
                EncryptionStatusSection(complianceService: complianceService)
            }
            .padding()
        }
    }
}

struct ComplianceStatusCard: View {
    @ObservedObject var complianceService: HIPAAComplianceService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("HIPAA Compliance Status")
                    .font(.headline)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Users")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(complianceService.accessControls.values.filter { $0.isActive }.count)")
                        .font(.title2)
                        .bold()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Access Reviews Needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(complianceService.getUsersNeedingAccessReview().count)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(complianceService.getUsersNeedingAccessReview().isEmpty ? .green : .orange)
                }
            }

            if !complianceService.getUsersNeedingAccessReview().isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Some users require access review")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickStatsSection: View {
    @ObservedObject var auditLogRepository: AuditLogRepository

    var stats: AuditStatistics {
        auditLogRepository.getAuditStatistics(for: DateComponents(day: -30))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days")
                .font(.headline)

            HStack(spacing: 16) {
                StatBox(
                    title: "Total Events",
                    value: "\(stats.totalEvents)",
                    icon: "chart.bar.fill",
                    color: .blue
                )

                StatBox(
                    title: "Failed Attempts",
                    value: "\(stats.failedAttempts)",
                    icon: "xmark.circle.fill",
                    color: stats.failedAttempts > 0 ? .red : .green
                )

                StatBox(
                    title: "Unique Users",
                    value: "\(stats.uniqueUsers)",
                    icon: "person.fill",
                    color: .purple
                )
            }
        }
    }
}

struct StatBox: View {
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
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SecurityConcernsSection: View {
    @ObservedObject var complianceService: HIPAAComplianceService

    var concerns: [SecurityConcern] {
        complianceService.checkForSecurityConcerns()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Concerns")
                .font(.headline)

            if concerns.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No security concerns detected")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            } else {
                ForEach(concerns) { concern in
                    SecurityConcernRow(concern: concern)
                }
            }
        }
    }
}

struct SecurityConcernRow: View {
    let concern: SecurityConcern

    var severityColor: Color {
        switch concern.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    var severityIcon: String {
        switch concern.severity {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .critical: return "exclamationmark.shield.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .font(.title3)
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(concern.description)
                    .font(.subheadline)
                Text(concern.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EncryptionStatusSection: View {
    @ObservedObject var complianceService: HIPAAComplianceService

    var status: EncryptionStatus {
        complianceService.getEncryptionStatus()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Encryption Status")
                .font(.headline)

            VStack(spacing: 8) {
                EncryptionStatusRow(title: "Data at Rest", enabled: status.dataAtRest)
                EncryptionStatusRow(title: "Data in Transit", enabled: status.dataInTransit)
                EncryptionStatusRow(title: "Database", enabled: status.databaseEncrypted)
                EncryptionStatusRow(title: "Keychain", enabled: status.keychain)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct EncryptionStatusRow: View {
    let title: String
    let enabled: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? .green : .red)
        }
    }
}

// MARK: - Audit Logs Tab

struct AuditLogsTab: View {
    @ObservedObject var auditLogRepository: AuditLogRepository
    @Binding var showingExportSheet: Bool
    @State private var searchText = ""
    @State private var selectedFilter: AuditAction?

    var filteredLogs: [AuditLog] {
        var logs = auditLogRepository.logs

        if let filter = selectedFilter {
            logs = logs.filter { $0.action == filter }
        }

        if !searchText.isEmpty {
            logs = auditLogRepository.searchLogs(query: searchText)
        }

        return logs
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search logs...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))

            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterButton(title: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }

                    ForEach(AuditAction.allCases, id: \.self) { action in
                        FilterButton(title: action.description, isSelected: selectedFilter == action) {
                            selectedFilter = action
                        }
                    }
                }
                .padding()
            }

            // Logs list
            List(filteredLogs) { log in
                AuditLogRow(log: log)
            }
            .listStyle(.plain)

            // Export button
            Button(action: { showingExportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Audit Logs")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct AuditLogRow: View {
    let log: AuditLog

    var resultColor: Color {
        switch log.result {
        case .success: return .green
        case .failure, .error: return .red
        case .denied: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text(log.userName)
                    .font(.subheadline)
                    .bold()

                Spacer()

                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(log.action.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)

                Text(log.resourceType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)

                Spacer()

                Image(systemName: log.result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(resultColor)
            }

            Text(log.resourceIdentifier)
                .font(.caption)
                .foregroundColor(.secondary)

            if let details = log.details {
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Access Control Tab

struct AccessControlTab: View {
    @ObservedObject var complianceService: HIPAAComplianceService

    var body: some View {
        List {
            Section(header: Text("Access Levels")) {
                ForEach(AccessLevel.allCases, id: \.self) { level in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(level.description)
                            .font(.headline)
                        Text("\(level.permissions.count) permissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Active Users")) {
                ForEach(Array(complianceService.accessControls.values.filter { $0.isActive }), id: \.userId) { control in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("User \(control.userId.uuidString.prefix(8))")
                                .font(.subheadline)
                            Text(control.accessLevel.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let reviewDate = control.nextAccessReview {
                            if reviewDate < Date() {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Security Tab

struct SecurityTab: View {
    @ObservedObject var complianceService: HIPAAComplianceService
    @State private var showingSessionSettings = false

    var body: some View {
        List {
            Section(header: Text("Session Management")) {
                HStack {
                    Text("Session Timeout")
                    Spacer()
                    Text("\(Int(complianceService.sessionTimeout / 60)) minutes")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Session Active")
                    Spacer()
                    Image(systemName: complianceService.isSessionActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(complianceService.isSessionActive ? .green : .red)
                }

                HStack {
                    Text("Last Activity")
                    Spacer()
                    Text(complianceService.lastActivity, style: .relative)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Data Protection")) {
                NavigationLink(destination: Text("Encryption Settings")) {
                    Label("Encryption Settings", systemImage: "lock.fill")
                }

                NavigationLink(destination: Text("Backup & Recovery")) {
                    Label("Backup & Recovery", systemImage: "externaldrive.fill")
                }

                NavigationLink(destination: Text("Data Retention")) {
                    Label("Data Retention Policies", systemImage: "calendar")
                }
            }

            Section(header: Text("Compliance Reports")) {
                Button(action: {}) {
                    Label("Generate Compliance Report", systemImage: "doc.text")
                }

                Button(action: {}) {
                    Label("Risk Assessment", systemImage: "exclamationmark.shield")
                }
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportAuditLogsSheet: View {
    @ObservedObject var auditLogRepository: AuditLogRepository
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    @State private var showingShareSheet = false
    @State private var exportedData: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section(header: Text("Export Info")) {
                    let logs = auditLogRepository.getLogs(from: startDate, to: endDate)
                    Text("\(logs.count) logs will be exported")
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Export as CSV") {
                        exportedData = auditLogRepository.exportAuditLogs(from: startDate, to: endDate)
                        showingShareSheet = true
                    }
                }
            }
            .navigationTitle("Export Audit Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    HIPAAComplianceView()
}

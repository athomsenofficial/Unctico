import SwiftUI

struct TeamManagementView: View {
    @StateObject private var repository = StaffRepository.shared
    @StateObject private var staffService = StaffService.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                StaffDirectoryView()
                    .tabItem {
                        Label("Team", systemImage: "person.3.fill")
                    }
                    .tag(0)

                TimeOffView()
                    .tabItem {
                        Label("Time Off", systemImage: "calendar.badge.clock")
                    }
                    .tag(1)

                PerformanceView()
                    .tabItem {
                        Label("Performance", systemImage: "chart.bar.fill")
                    }
                    .tag(2)

                TeamStatsView()
                    .tabItem {
                        Label("Overview", systemImage: "chart.pie.fill")
                    }
                    .tag(3)
            }
            .navigationTitle("Team Management")
        }
    }
}

// MARK: - Staff Directory View

struct StaffDirectoryView: View {
    @StateObject private var repository = StaffRepository.shared
    @State private var searchText = ""
    @State private var showingAddStaff = false
    @State private var selectedRole: StaffRole?

    var filteredStaff: [StaffMember] {
        var members = repository.staff

        if let role = selectedRole {
            members = members.filter { $0.role == role }
        }

        if !searchText.isEmpty {
            members = repository.searchStaff(query: searchText)
        }

        return members.sorted { $0.fullName < $1.fullName }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Role filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedRole == nil,
                        action: { selectedRole = nil }
                    )

                    ForEach(StaffRole.allCases, id: \.self) { role in
                        FilterChip(
                            title: role.rawValue,
                            isSelected: selectedRole == role,
                            action: { selectedRole = selectedRole == role ? nil : role }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))

            List {
                if filteredStaff.isEmpty {
                    ContentUnavailableView(
                        "No Team Members",
                        systemImage: "person.3",
                        description: Text("Add your first team member")
                    )
                } else {
                    ForEach(filteredStaff) { member in
                        NavigationLink(destination: StaffDetailView(staff: member)) {
                            StaffRow(staff: member)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search team members")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddStaff = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStaff) {
            AddStaffView()
        }
    }
}

struct StaffRow: View {
    let staff: StaffMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(staff.initials)
                        .font(.headline)
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(staff.fullName)
                        .font(.headline)

                    if !staff.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(staff.role.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    if staff.isLicenseExpired {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("License Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if staff.isLicenseExpiringSoon {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("License Expiring Soon")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            if let metrics = staff.performanceMetrics {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.0f", metrics.totalRevenue))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if metrics.averageRating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", metrics.averageRating))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Time Off View

struct TimeOffView: View {
    @StateObject private var repository = StaffRepository.shared
    @State private var showingNewRequest = false
    @State private var selectedFilter: TimeOffFilter = .all

    enum TimeOffFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
    }

    var filteredRequests: [TimeOffRequest] {
        switch selectedFilter {
        case .all:
            return repository.timeOffRequests.sorted { $0.requestedDate > $1.requestedDate }
        case .pending:
            return repository.getPendingTimeOffRequests()
        case .approved:
            return repository.timeOffRequests.filter { $0.status == .approved }
                .sorted { $0.startDate < $1.startDate }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TimeOffFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                if filteredRequests.isEmpty {
                    ContentUnavailableView(
                        "No Time Off Requests",
                        systemImage: "calendar",
                        description: Text("No requests match your filter")
                    )
                } else {
                    ForEach(filteredRequests) { request in
                        TimeOffRequestRow(request: request)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewRequest = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewRequest) {
            Text("New Time Off Request")
        }
    }
}

struct TimeOffRequestRow: View {
    let request: TimeOffRequest
    @StateObject private var repository = StaffRepository.shared
    @StateObject private var service = StaffService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.staffName)
                    .font(.headline)

                Spacer()

                RequestStatusBadge(status: request.status)
            }

            HStack {
                Image(systemName: request.requestType.icon)
                    .foregroundColor(.blue)

                Text(request.requestType.rawValue)
                    .font(.subheadline)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(request.startDate, style: .date) - \(request.endDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !request.reason.isEmpty {
                Text(request.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if request.isPending {
                HStack(spacing: 12) {
                    Button(action: { approveRequest() }) {
                        Text("Approve")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { denyRequest() }) {
                        Text("Deny")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func approveRequest() {
        let approved = service.approveTimeOffRequest(
            request: request,
            reviewedBy: UUID(), // Should be current user ID
            notes: "Approved"
        )
        repository.updateTimeOffRequest(approved)
    }

    private func denyRequest() {
        let denied = service.denyTimeOffRequest(
            request: request,
            reviewedBy: UUID(), // Should be current user ID
            reason: "Denied"
        )
        repository.updateTimeOffRequest(denied)
    }
}

struct RequestStatusBadge: View {
    let status: RequestStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

// MARK: - Performance View

struct PerformanceView: View {
    @StateObject private var repository = StaffRepository.shared

    var therapists: [StaffMember] {
        repository.getTherapists()
    }

    var body: some View {
        List {
            if therapists.isEmpty {
                ContentUnavailableView(
                    "No Therapists",
                    systemImage: "chart.bar",
                    description: Text("Add therapists to track performance")
                )
            } else {
                ForEach(therapists) { therapist in
                    NavigationLink(destination: StaffPerformanceDetailView(staff: therapist)) {
                        PerformanceRow(staff: therapist)
                    }
                }
            }
        }
    }
}

struct PerformanceRow: View {
    let staff: StaffMember

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(staff.fullName)
                .font(.headline)

            if let metrics = staff.performanceMetrics {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricItem(
                        label: "Revenue",
                        value: String(format: "$%.0f", metrics.totalRevenue),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )

                    MetricItem(
                        label: "Appointments",
                        value: "\(metrics.totalAppointments)",
                        icon: "calendar.circle.fill",
                        color: .blue
                    )

                    MetricItem(
                        label: "Rating",
                        value: String(format: "%.1f", metrics.averageRating),
                        icon: "star.circle.fill",
                        color: .yellow
                    )

                    MetricItem(
                        label: "Rebooking",
                        value: String(format: "%.0f%%", metrics.rebookingRate),
                        icon: "arrow.clockwise.circle.fill",
                        color: .purple
                    )
                }
            } else {
                Text("No performance data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Team Stats View

struct TeamStatsView: View {
    @StateObject private var repository = StaffRepository.shared

    var stats: TeamStatistics {
        repository.getStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatsCard(
                        title: "Total Staff",
                        value: "\(stats.totalStaff)",
                        icon: "person.3.fill",
                        color: .blue
                    )

                    StatsCard(
                        title: "Active Staff",
                        value: "\(stats.activeStaff)",
                        icon: "person.fill.checkmark",
                        color: .green
                    )

                    StatsCard(
                        title: "Therapists",
                        value: "\(stats.therapistCount)",
                        icon: "hand.raised.fill",
                        color: .purple
                    )

                    StatsCard(
                        title: "Support Staff",
                        value: "\(stats.supportStaffCount)",
                        icon: "person.fill",
                        color: .orange
                    )

                    StatsCard(
                        title: "Team Revenue",
                        value: String(format: "$%.0f", stats.totalTeamRevenue),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )

                    StatsCard(
                        title: "Avg Rating",
                        value: String(format: "%.1f", stats.averagePerformanceRating),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                .padding()

                // Alerts Section
                if stats.pendingTimeOffRequests > 0 || stats.expiringLicenses > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alerts")
                            .font(.headline)
                            .padding(.horizontal)

                        if stats.pendingTimeOffRequests > 0 {
                            AlertCard(
                                icon: "calendar.badge.exclamationmark",
                                title: "Pending Time Off Requests",
                                value: "\(stats.pendingTimeOffRequests)",
                                color: .orange
                            )
                        }

                        if stats.expiringLicenses > 0 {
                            AlertCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Licenses Expiring Soon",
                                value: "\(stats.expiringLicenses)",
                                color: .red
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct AlertCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)

                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Staff Detail View

struct StaffDetailView: View {
    let staff: StaffMember
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Personal Information") {
                DetailRow(label: "Email", value: staff.email)
                DetailRow(label: "Phone", value: staff.phone)
                DetailRow(label: "Role", value: staff.role.rawValue)
                DetailRow(label: "Employment Type", value: staff.employmentType.rawValue)
            }

            if staff.role.canProvideServices {
                Section("License") {
                    DetailRow(label: "License Number", value: staff.licenseNumber ?? "N/A")
                    if let expiration = staff.licenseExpiration {
                        DetailRow(label: "Expiration", value: expiration.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                if !staff.specializations.isEmpty {
                    Section("Specializations") {
                        ForEach(staff.specializations, id: \.self) { spec in
                            Text(spec)
                        }
                    }
                }
            }

            Section("Compensation") {
                DetailRow(label: "Type", value: staff.compensation.type.rawValue)
                DetailRow(label: "Base Rate", value: String(format: "$%.2f", staff.compensation.baseRate))
                if let commission = staff.compensation.commissionRate {
                    DetailRow(label: "Commission Rate", value: String(format: "%.0f%%", commission))
                }
            }

            if let metrics = staff.performanceMetrics {
                Section("Performance") {
                    DetailRow(label: "Total Revenue", value: String(format: "$%.2f", metrics.totalRevenue))
                    DetailRow(label: "Appointments", value: "\(metrics.totalAppointments)")
                    DetailRow(label: "Average Rating", value: String(format: "%.1f", metrics.averageRating))
                    DetailRow(label: "Rebooking Rate", value: String(format: "%.1f%%", metrics.rebookingRate))
                }
            }
        }
        .navigationTitle(staff.fullName)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct StaffPerformanceDetailView: View {
    let staff: StaffMember

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let metrics = staff.performanceMetrics {
                    Text("Performance Metrics")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        PerformanceCard(
                            title: "Total Revenue",
                            value: String(format: "$%.2f", metrics.totalRevenue),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )

                        PerformanceCard(
                            title: "Appointments",
                            value: "\(metrics.totalAppointments)",
                            icon: "calendar.circle.fill",
                            color: .blue
                        )

                        PerformanceCard(
                            title: "Avg Rating",
                            value: String(format: "%.1f ⭐", metrics.averageRating),
                            icon: "star.circle.fill",
                            color: .yellow
                        )

                        PerformanceCard(
                            title: "Avg per Appt",
                            value: String(format: "$%.2f", metrics.averageRevenuePerAppointment),
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .purple
                        )

                        PerformanceCard(
                            title: "New Clients",
                            value: "\(metrics.newClients)",
                            icon: "person.crop.circle.badge.plus",
                            color: .blue
                        )

                        PerformanceCard(
                            title: "Repeat Clients",
                            value: "\(metrics.repeatClients)",
                            icon: "arrow.clockwise.circle.fill",
                            color: .green
                        )

                        PerformanceCard(
                            title: "Rebooking Rate",
                            value: String(format: "%.1f%%", metrics.rebookingRate),
                            icon: "arrow.2.circlepath.circle.fill",
                            color: .teal
                        )

                        PerformanceCard(
                            title: "Retention Rate",
                            value: String(format: "%.1f%%", metrics.clientRetentionRate),
                            icon: "heart.circle.fill",
                            color: .red
                        )
                    }
                    .padding()
                } else {
                    Text("No performance data available")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("\(staff.fullName) - Performance")
    }
}

struct PerformanceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

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

// MARK: - Add Staff View

struct AddStaffView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Text("Add staff member form")
            }
            .navigationTitle("Add Team Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TeamManagementView()
}

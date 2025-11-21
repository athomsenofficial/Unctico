import SwiftUI

struct ClientPortalManagementView: View {
    @StateObject private var repository = ClientPortalRepository.shared
    @StateObject private var service = ClientPortalService.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                PortalAccountsView()
                    .tabItem {
                        Label("Accounts", systemImage: "person.circle.fill")
                    }
                    .tag(0)

                BookingRequestsView()
                    .tabItem {
                        Label("Bookings", systemImage: "calendar.badge.plus")
                    }
                    .tag(1)

                PortalNotificationsView()
                    .tabItem {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    .tag(2)

                PortalStatsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)

                PortalConfigView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .navigationTitle("Client Portal")
        }
    }
}

// MARK: - Portal Accounts View

struct PortalAccountsView: View {
    @StateObject private var repository = ClientPortalRepository.shared
    @State private var searchText = ""

    var filteredAccounts: [ClientPortalAccount] {
        if searchText.isEmpty {
            return repository.accounts.sorted { $0.createdDate > $1.createdDate }
        } else {
            return repository.accounts.filter {
                $0.email.lowercased().contains(searchText.lowercased())
            }.sorted { $0.createdDate > $1.createdDate }
        }
    }

    var body: some View {
        List {
            if filteredAccounts.isEmpty {
                ContentUnavailableView(
                    "No Portal Accounts",
                    systemImage: "person.circle",
                    description: Text("No clients have created portal accounts yet")
                )
            } else {
                ForEach(filteredAccounts) { account in
                    PortalAccountRow(account: account)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by email")
    }
}

struct PortalAccountRow: View {
    let account: ClientPortalAccount
    @StateObject private var repository = ClientPortalRepository.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(account.isActive ? .blue : .gray)

                Text(account.email)
                    .font(.headline)

                Spacer()

                if !account.isActive {
                    Text("Inactive")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                if !account.isEmailVerified {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            HStack {
                Text("Created: \(account.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastLogin = account.lastLoginDate {
                    Text("•")
                        .foregroundColor(.secondary)

                    Text("Last login: \(lastLogin.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(account.accessLevel.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                if account.twoFactorEnabled {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)
                        Text("2FA")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(4)
                }
            }

            // Active sessions
            let activeSessions = repository.getActiveSessions(clientId: account.clientId)
            if !activeSessions.isEmpty {
                Text("\(activeSessions.count) active session(s)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Booking Requests View

struct BookingRequestsView: View {
    @StateObject private var repository = ClientPortalRepository.shared
    @State private var selectedStatus: BookingRequestStatus?

    var filteredRequests: [OnlineBookingRequest] {
        var requests = repository.bookingRequests

        if let status = selectedStatus {
            requests = requests.filter { $0.status == status }
        }

        return requests.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedStatus == nil,
                        action: { selectedStatus = nil }
                    )

                    ForEach([BookingRequestStatus.pending, .confirmed, .declined, .cancelled], id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: selectedStatus == status,
                            action: { selectedStatus = selectedStatus == status ? nil : status }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))

            List {
                if filteredRequests.isEmpty {
                    ContentUnavailableView(
                        "No Booking Requests",
                        systemImage: "calendar",
                        description: Text("No online booking requests match your filter")
                    )
                } else {
                    ForEach(filteredRequests) { request in
                        BookingRequestRow(request: request)
                    }
                }
            }
        }
    }
}

struct BookingRequestRow: View {
    let request: OnlineBookingRequest
    @StateObject private var repository = ClientPortalRepository.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.serviceName)
                    .font(.headline)

                Spacer()

                BookingStatusBadge(status: request.status)
            }

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(request.preferredTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)

                if let therapistName = request.therapistName {
                    Text("•")
                        .foregroundColor(.secondary)

                    Text("with \(therapistName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !request.notes.isEmpty {
                Text(request.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text("Requested: \(request.createdDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)

            if request.isPending {
                HStack(spacing: 12) {
                    Button(action: { confirmRequest() }) {
                        Text("Confirm")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { declineRequest() }) {
                        Text("Decline")
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

    private func confirmRequest() {
        // Would normally create appointment and update request
        var updatedRequest = request
        updatedRequest.status = .confirmed
        updatedRequest.processedDate = Date()
        repository.updateBookingRequest(updatedRequest)
    }

    private func declineRequest() {
        var updatedRequest = request
        updatedRequest.status = .declined
        updatedRequest.processedDate = Date()
        repository.updateBookingRequest(updatedRequest)
    }
}

struct BookingStatusBadge: View {
    let status: BookingRequestStatus

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

// MARK: - Portal Notifications View

struct PortalNotificationsView: View {
    @StateObject private var repository = ClientPortalRepository.shared
    @State private var selectedClient: UUID?

    var body: some View {
        List {
            if repository.notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell",
                    description: Text("No portal notifications have been sent")
                )
            } else {
                ForEach(repository.notifications.sorted { $0.createdDate > $1.createdDate }) { notification in
                    NotificationRow(notification: notification)
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: ClientNotification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.notificationType.icon)
                .foregroundColor(Color(notification.notificationType.color))
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)

                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(notification.createdDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if notification.isRead {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Portal Stats View

struct PortalStatsView: View {
    @StateObject private var repository = ClientPortalRepository.shared

    var stats: ClientPortalStatistics {
        repository.getStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatsCard(
                        title: "Total Accounts",
                        value: "\(stats.totalAccounts)",
                        icon: "person.circle.fill",
                        color: .blue
                    )

                    StatsCard(
                        title: "Active Accounts",
                        value: "\(stats.activeAccounts)",
                        icon: "person.fill.checkmark",
                        color: .green
                    )

                    StatsCard(
                        title: "Active Sessions",
                        value: "\(stats.activeSessions)",
                        icon: "desktopcomputer",
                        color: .purple
                    )

                    StatsCard(
                        title: "Activation Rate",
                        value: String(format: "%.1f%%", stats.accountActivationRate),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )

                    StatsCard(
                        title: "Online Bookings",
                        value: "\(stats.onlineBookings)",
                        icon: "calendar.badge.plus",
                        color: .teal
                    )

                    StatsCard(
                        title: "Pending Bookings",
                        value: "\(stats.pendingBookings)",
                        icon: "clock.fill",
                        color: .orange
                    )
                }
                .padding()

                // Pending Actions
                if stats.pendingBookings > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pending Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Booking Requests Awaiting Response")
                                    .font(.subheadline)

                                Text("\(stats.pendingBookings) request(s)")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Accounts")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(repository.accounts.sorted { $0.createdDate > $1.createdDate }.prefix(5)) { account in
                        AccountActivityRow(account: account)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct AccountActivityRow: View {
    let account: ClientPortalAccount

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(account.isActive ? .blue : .gray)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(account.email)
                    .font(.subheadline)

                Text("Joined \(account.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if account.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Portal Config View

struct PortalConfigView: View {
    @StateObject private var repository = ClientPortalRepository.shared
    @State private var config: ClientPortalConfiguration

    init() {
        let repo = ClientPortalRepository.shared
        _config = State(initialValue: repo.configuration)
    }

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable Client Portal", isOn: $config.isEnabled)
                Toggle("Allow Self Registration", isOn: $config.allowSelfRegistration)
                Toggle("Require Email Verification", isOn: $config.requireEmailVerification)
            }

            Section("Online Booking") {
                Toggle("Allow Online Booking", isOn: $config.allowOnlineBooking)
                Toggle("Show Pricing", isOn: $config.showPricing)
                Toggle("Show Therapist Profiles", isOn: $config.showTherapistProfiles)

                Stepper("Booking Advance: \(config.bookingAdvanceDays) days", value: $config.bookingAdvanceDays, in: 1...90)
            }

            Section("Cancellation Policy") {
                Toggle("Allow Cancellations", isOn: $config.allowCancellations)

                if config.allowCancellations {
                    Stepper("Notice Required: \(config.cancellationHoursNotice) hours", value: $config.cancellationHoursNotice, in: 0...72, step: 12)
                }

                Toggle("Allow Rescheduling", isOn: $config.allowRescheduling)
            }

            Section("Customization") {
                VStack(alignment: .leading) {
                    Text("Welcome Message")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Custom welcome message", text: $config.customWelcomeMessage, axis: .vertical)
                        .lineLimit(3...6)
                }

                VStack(alignment: .leading) {
                    Text("Booking Instructions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Custom booking instructions", text: $config.customBookingInstructions, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section {
                Button(action: saveConfiguration) {
                    HStack {
                        Spacer()
                        Text("Save Configuration")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Portal Settings")
    }

    private func saveConfiguration() {
        repository.updateConfiguration(config)
    }
}

#Preview {
    ClientPortalManagementView()
}

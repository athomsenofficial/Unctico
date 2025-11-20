import SwiftUI

/// Comprehensive view for managing client communications
struct CommunicationView: View {
    @StateObject private var communicationService = CommunicationService.shared
    @StateObject private var repository = CommunicationRepository.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                MessagesListView()
                    .tabItem {
                        Label("Messages", systemImage: "envelope.fill")
                    }
                    .tag(0)

                CampaignsView()
                    .tabItem {
                        Label("Campaigns", systemImage: "megaphone.fill")
                    }
                    .tag(1)

                WorkflowsView()
                    .tabItem {
                        Label("Workflows", systemImage: "arrow.triangle.branch")
                    }
                    .tag(2)

                CommunicationAnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)

                CommunicationSettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .navigationTitle("Communications")
        }
    }
}

// MARK: - Messages List View

struct MessagesListView: View {
    @StateObject private var repository = CommunicationRepository.shared
    @State private var filterChannel: CommunicationChannel?
    @State private var filterStatus: MessageStatus?
    @State private var searchText = ""
    @State private var showingNewMessage = false

    var filteredMessages: [CommunicationMessage] {
        var filtered = repository.messages

        if let channel = filterChannel {
            filtered = filtered.filter { $0.channel == channel }
        }

        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.clientName.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        title: "All Channels",
                        isSelected: filterChannel == nil,
                        action: { filterChannel = nil }
                    )

                    ForEach(CommunicationChannel.allCases, id: \.self) { channel in
                        FilterButton(
                            title: channel.rawValue,
                            isSelected: filterChannel == channel,
                            action: { filterChannel = channel }
                        )
                    }

                    Divider()
                        .frame(height: 24)

                    ForEach([MessageStatus.sent, .delivered, .failed], id: \.self) { status in
                        FilterButton(
                            title: status.rawValue,
                            isSelected: filterStatus == status,
                            action: { filterStatus = filterStatus == status ? nil : status }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))

            List {
                if filteredMessages.isEmpty {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "envelope",
                        description: Text("No messages match your filters")
                    )
                } else {
                    ForEach(filteredMessages) { message in
                        MessageRow(message: message)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search messages")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewMessage = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewMessage) {
            NewMessageView()
        }
    }
}

struct MessageRow: View {
    let message: CommunicationMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: message.channel.icon)
                    .foregroundColor(message.channel.color)

                Text(message.clientName)
                    .font(.headline)

                Spacer()

                Text(message.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let subject = message.subject {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(message.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                StatusBadge(status: message.status)

                Spacer()

                if message.wasOpened {
                    Label("Opened", systemImage: "envelope.open.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                if message.wasClicked {
                    Label("Clicked", systemImage: "hand.tap.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: MessageStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

// MARK: - Campaigns View

struct CampaignsView: View {
    @StateObject private var repository = CommunicationRepository.shared
    @State private var showingNewCampaign = false
    @State private var selectedCampaign: MarketingCampaign?

    var body: some View {
        List {
            if repository.campaigns.isEmpty {
                ContentUnavailableView(
                    "No Campaigns",
                    systemImage: "megaphone",
                    description: Text("Create your first marketing campaign")
                )
            } else {
                ForEach(repository.campaigns) { campaign in
                    CampaignRow(campaign: campaign)
                        .onTapGesture {
                            selectedCampaign = campaign
                        }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCampaign = true }) {
                    Label("New Campaign", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCampaign) {
            NewCampaignView()
        }
        .sheet(item: $selectedCampaign) { campaign in
            CampaignDetailView(campaign: campaign)
        }
    }
}

struct CampaignRow: View {
    let campaign: MarketingCampaign
    @StateObject private var repository = CommunicationRepository.shared

    var statistics: CampaignStatistics {
        repository.getCampaignStatistics(campaign.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(campaign.name)
                        .font(.headline)

                    Text(campaign.campaignType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: campaignStatusToMessageStatus(campaign.status))
            }

            Text(campaign.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 16) {
                StatItem(label: "Recipients", value: "\(statistics.totalRecipients)")
                StatItem(label: "Sent", value: "\(statistics.totalSent)")
                StatItem(label: "Open Rate", value: String(format: "%.1f%%", statistics.openRate))
                StatItem(label: "Click Rate", value: String(format: "%.1f%%", statistics.clickRate))
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    func campaignStatusToMessageStatus(_ status: CampaignStatus) -> MessageStatus {
        switch status {
        case .draft: return .draft
        case .scheduled: return .scheduled
        case .active: return .sending
        case .completed: return .delivered
        case .paused: return .cancelled
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .fontWeight(.semibold)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workflows View

struct WorkflowsView: View {
    @StateObject private var repository = CommunicationRepository.shared
    @State private var showingNewWorkflow = false

    var body: some View {
        List {
            if repository.workflows.isEmpty {
                ContentUnavailableView(
                    "No Workflows",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Create automated workflows to engage clients")
                )
            } else {
                ForEach(repository.workflows) { workflow in
                    WorkflowRow(workflow: workflow)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewWorkflow = true }) {
                    Label("New Workflow", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewWorkflow) {
            NewWorkflowView()
        }
    }
}

struct WorkflowRow: View {
    let workflow: AutomatedWorkflow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workflow.name)
                    .font(.headline)

                Spacer()

                Toggle("", isOn: .constant(workflow.isActive))
                    .labelsHidden()
            }

            Text(workflow.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(workflow.trigger.rawValue, systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Spacer()

                Text("\(workflow.actions.count) action\(workflow.actions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Analytics View

struct CommunicationAnalyticsView: View {
    @StateObject private var repository = CommunicationRepository.shared
    @State private var timeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }

    var statistics: MessageStatistics {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        return repository.getMessageStatistics(from: startDate, to: endDate)
    }

    var reviewStats: ReviewStatistics {
        repository.getReviewStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Message Statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Message Performance")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Total Messages",
                            value: "\(statistics.totalMessages)",
                            icon: "envelope.fill",
                            color: .blue
                        )

                        MetricCard(
                            title: "Delivered",
                            value: "\(statistics.sentMessages)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )

                        MetricCard(
                            title: "Open Rate",
                            value: String(format: "%.1f%%", statistics.openRate),
                            icon: "envelope.open.fill",
                            color: .orange
                        )

                        MetricCard(
                            title: "Click Rate",
                            value: String(format: "%.1f%%", statistics.clickRate),
                            icon: "hand.tap.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }

                // Review Statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Performance")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Requests Sent",
                            value: "\(reviewStats.sentRequests)",
                            icon: "star.fill",
                            color: .yellow
                        )

                        MetricCard(
                            title: "Completed",
                            value: "\(reviewStats.completedReviews)",
                            icon: "checkmark.star.fill",
                            color: .green
                        )

                        MetricCard(
                            title: "Completion Rate",
                            value: String(format: "%.1f%%", reviewStats.completionRate),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )

                        MetricCard(
                            title: "Pending",
                            value: "\(reviewStats.pendingRequests)",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }

                // Channel Breakdown
                if !statistics.messagesByChannel.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Channel")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(Array(statistics.messagesByChannel.keys), id: \.self) { channel in
                            HStack {
                                Image(systemName: channel.icon)
                                    .foregroundColor(channel.color)
                                    .frame(width: 30)

                                Text(channel.rawValue)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(statistics.messagesByChannel[channel] ?? 0)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct MetricCard: View {
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
                .font(.title)
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

// MARK: - Settings View

struct CommunicationSettingsView: View {
    @StateObject private var communicationService = CommunicationService.shared
    @State private var selectedChannel: CommunicationChannel?

    var body: some View {
        List {
            Section("Service Configuration") {
                ForEach(CommunicationChannel.allCases, id: \.self) { channel in
                    Button(action: { selectedChannel = channel }) {
                        HStack {
                            Image(systemName: channel.icon)
                                .foregroundColor(channel.color)
                                .frame(width: 30)

                            Text(channel.rawValue)

                            Spacer()

                            if communicationService.isChannelConfigured(channel) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Message Templates") {
                NavigationLink(destination: MessageTemplatesView()) {
                    Label("Manage Templates", systemImage: "doc.text")
                }
            }

            Section {
                Text("Configure your communication channels to start sending messages to clients.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(item: $selectedChannel) { channel in
            ChannelConfigurationView(channel: channel)
        }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Text("New message form would go here")
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct NewCampaignView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Text("New campaign form would go here")
            }
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CampaignDetailView: View {
    let campaign: MarketingCampaign
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Text("Campaign details for: \(campaign.name)")
            }
            .navigationTitle(campaign.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct NewWorkflowView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Text("New workflow form would go here")
            }
            .navigationTitle("New Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct MessageTemplatesView: View {
    @StateObject private var communicationService = CommunicationService.shared

    var body: some View {
        List {
            ForEach(communicationService.messageTemplates) { template in
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)

                    Text(template.messageType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Message Templates")
    }
}

struct ChannelConfigurationView: View {
    let channel: CommunicationChannel
    @Environment(\.dismiss) var dismiss
    @StateObject private var communicationService = CommunicationService.shared

    @State private var isEnabled = false
    @State private var apiKey = ""
    @State private var secretKey = ""
    @State private var senderIdentity = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Configuration") {
                    Toggle("Enable \(channel.rawValue)", isOn: $isEnabled)
                }

                if isEnabled {
                    Section("Credentials") {
                        TextField("API Key", text: $apiKey)
                            .autocapitalization(.none)

                        SecureField("Secret Key", text: $secretKey)

                        TextField(channel == .email ? "Sender Email" : "Sender Phone", text: $senderIdentity)
                            .autocapitalization(.none)
                    }

                    Section {
                        Text(getProviderInstructions())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("\(channel.rawValue) Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingConfig()
            }
        }
    }

    func getProviderInstructions() -> String {
        switch channel {
        case .sms:
            return "Get your Twilio Account SID and Auth Token from twilio.com/console"
        case .email:
            return "Get your SendGrid API Key from app.sendgrid.com/settings/api_keys"
        case .push:
            return "Configure APNs in your Apple Developer account"
        case .inApp:
            return "In-app notifications are automatically configured"
        }
    }

    func loadExistingConfig() {
        if let config = communicationService.getServiceConfig(for: channel) {
            isEnabled = config.isEnabled
            apiKey = config.apiKey
            secretKey = config.secretKey
            senderIdentity = config.senderIdentity
        }
    }

    func saveConfiguration() {
        let config = CommunicationServiceConfig(
            channel: channel,
            provider: channel == .sms ? .twilio : .sendgrid,
            apiKey: apiKey,
            secretKey: secretKey,
            senderIdentity: senderIdentity,
            isEnabled: isEnabled
        )

        communicationService.updateServiceConfig(config)
    }
}

#Preview {
    CommunicationView()
}

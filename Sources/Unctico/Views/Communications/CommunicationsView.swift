import SwiftUI

/// Comprehensive communication management system for email and SMS
struct CommunicationsView: View {
    @StateObject private var communicationService = CommunicationService.shared
    @StateObject private var reminderScheduler = AppointmentReminderScheduler.shared

    @State private var selectedTab: CommunicationTab = .messages
    @State private var showingSendMessage = false
    @State private var showingCampaignBuilder = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                CommunicationTabBar(selectedTab: $selectedTab)

                // Content
                TabView(selection: $selectedTab) {
                    MessageHistoryView()
                        .tag(CommunicationTab.messages)

                    ScheduledRemindersView()
                        .tag(CommunicationTab.reminders)

                    CampaignsView()
                        .tag(CommunicationTab.campaigns)

                    AnalyticsView()
                        .tag(CommunicationTab.analytics)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Communications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSendMessage = true }) {
                            Label("Send Message", systemImage: "paperplane.fill")
                        }

                        Button(action: { showingCampaignBuilder = true }) {
                            Label("Create Campaign", systemImage: "megaphone.fill")
                        }

                        Divider()

                        NavigationLink(destination: NotificationPreferencesView()) {
                            Label("Notification Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingSendMessage) {
                SendMessageView()
            }
            .sheet(isPresented: $showingCampaignBuilder) {
                CampaignBuilderView()
            }
        }
    }
}

// MARK: - Communication Tabs

enum CommunicationTab: String, CaseIterable {
    case messages = "Messages"
    case reminders = "Reminders"
    case campaigns = "Campaigns"
    case analytics = "Analytics"

    var icon: String {
        switch self {
        case .messages: return "envelope.fill"
        case .reminders: return "bell.fill"
        case .campaigns: return "megaphone.fill"
        case .analytics: return "chart.bar.fill"
        }
    }
}

struct CommunicationTabBar: View {
    @Binding var selectedTab: CommunicationTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CommunicationTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(selectedTab == tab ? .tranquilTeal : .gray)
                    .background(selectedTab == tab ? Color.tranquilTeal.opacity(0.1) : Color.clear)
                }
            }
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - Message History

struct MessageHistoryView: View {
    @StateObject private var communicationService = CommunicationService.shared
    @State private var searchText = ""
    @State private var filterChannel: CommunicationChannel?
    @State private var filterStatus: MessageStatus?

    var filteredMessages: [CommunicationMessage] {
        var messages = communicationService.messageHistory

        if !searchText.isEmpty {
            messages = messages.filter {
                $0.recipientName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.subject?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        if let channel = filterChannel {
            messages = messages.filter { $0.channel == channel }
        }

        if let status = filterStatus {
            messages = messages.filter { $0.status == status }
        }

        return messages.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Filters
            VStack(spacing: 12) {
                SearchBar(text: $searchText, placeholder: "Search messages...")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All Channels",
                            isSelected: filterChannel == nil,
                            action: { filterChannel = nil }
                        )

                        ForEach([CommunicationChannel.email, .sms], id: \.self) { channel in
                            FilterChip(
                                title: channel.rawValue,
                                isSelected: filterChannel == channel,
                                action: { filterChannel = channel }
                            )
                        }

                        Divider()
                            .frame(height: 20)

                        FilterChip(
                            title: "All Status",
                            isSelected: filterStatus == nil,
                            action: { filterStatus = nil }
                        )

                        ForEach([MessageStatus.sent, .delivered, .failed], id: \.self) { status in
                            FilterChip(
                                title: status.rawValue,
                                isSelected: filterStatus == status,
                                action: { filterStatus = status }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Messages List
            if filteredMessages.isEmpty {
                MessageHistoryEmptyState(hasFilters: filterChannel != nil || filterStatus != nil || !searchText.isEmpty)
            } else {
                List {
                    ForEach(filteredMessages) { message in
                        NavigationLink(destination: MessageDetailView(message: message)) {
                            MessageRow(message: message)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct MessageRow: View {
    let message: CommunicationMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Channel Icon
                Image(systemName: message.channel.icon)
                    .foregroundColor(message.channel.color)
                    .frame(width: 24)

                // Recipient
                Text(message.recipientName ?? message.recipientContact)
                    .font(.headline)

                Spacer()

                // Status Badge
                Text(message.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(message.status.color.opacity(0.2))
                    .foregroundColor(message.status.color)
                    .cornerRadius(8)
            }

            // Subject/Type
            HStack {
                Image(systemName: message.messageType.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(message.subject ?? message.messageType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Date and Analytics
            HStack(spacing: 16) {
                Label(message.createdDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if message.status == .delivered || message.status == .opened {
                    if message.channel == .email {
                        if message.openedDate != nil {
                            Label("Opened", systemImage: "envelope.open.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                if message.status == .failed {
                    Label("Failed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MessageHistoryEmptyState: View {
    let hasFilters: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "envelope")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(hasFilters ? "No Matching Messages" : "No Messages Sent")
                .font(.title2)
                .fontWeight(.semibold)

            Text(hasFilters ? "Try adjusting your filters" : "Send your first message to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Message Detail

struct MessageDetailView: View {
    let message: CommunicationMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Header
                HStack {
                    Image(systemName: message.channel.icon)
                        .font(.title2)
                        .foregroundColor(message.channel.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.channel.rawValue)
                            .font(.headline)
                        Text(message.messageType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(message.status.rawValue)
                            .font(.headline)
                            .foregroundColor(message.status.color)
                        Text(message.createdDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(message.status.color.opacity(0.1))
                .cornerRadius(12)

                // Recipient Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recipient")
                        .font(.headline)

                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.tranquilTeal)
                        Text(message.recipientName ?? "Unknown")
                        Spacer()
                    }

                    HStack {
                        Image(systemName: message.channel == .email ? "envelope" : "phone")
                            .foregroundColor(.secondary)
                        Text(message.recipientContact)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Message Content
                if let subject = message.subject {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject")
                            .font(.headline)
                        Text(subject)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Message")
                        .font(.headline)
                    Text(message.body)
                        .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Delivery Timeline
                if message.status == .sent || message.status == .delivered || message.status == .opened {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Delivery Timeline")
                            .font(.headline)

                        DeliveryTimelineView(message: message)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Error Info
                if let error = message.errorMessage {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Error Details")
                                .font(.headline)
                        }
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Message Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeliveryTimelineView: View {
    let message: CommunicationMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineItem(
                icon: "paperplane.fill",
                title: "Sent",
                date: message.createdDate,
                isCompleted: true
            )

            if let sentDate = message.sentDate {
                TimelineItem(
                    icon: "checkmark.circle.fill",
                    title: "Delivered",
                    date: sentDate,
                    isCompleted: true
                )
            }

            if let openedDate = message.openedDate {
                TimelineItem(
                    icon: "envelope.open.fill",
                    title: "Opened",
                    date: openedDate,
                    isCompleted: true
                )
            }
        }
    }
}

struct TimelineItem: View {
    let icon: String
    let title: String
    let date: Date
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isCompleted ? .green : .gray)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(date, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Scheduled Reminders

struct ScheduledRemindersView: View {
    @StateObject private var scheduler = AppointmentReminderScheduler.shared
    @State private var filterStatus: ReminderStatus?

    var filteredReminders: [ScheduledReminder] {
        var reminders = scheduler.scheduledReminders

        if let status = filterStatus {
            reminders = reminders.filter { $0.status == status }
        }

        return reminders.sorted { $0.sendDate < $1.sendDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: filterStatus == nil,
                        action: { filterStatus = nil }
                    )

                    ForEach([ReminderStatus.pending, .sent, .failed], id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: filterStatus == status,
                            action: { filterStatus = status },
                            color: status.color
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            // Reminders List
            if filteredReminders.isEmpty {
                ScheduledRemindersEmptyState()
            } else {
                List {
                    ForEach(filteredReminders) { reminder in
                        ScheduledReminderRow(reminder: reminder)
                    }
                    .onDelete { indexSet in
                        // Delete reminders
                        for index in indexSet {
                            let reminder = filteredReminders[index]
                            scheduler.cancelReminders(for: reminder.appointmentId)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct ScheduledReminderRow: View {
    let reminder: ScheduledReminder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminder.channel.icon)
                    .foregroundColor(reminder.channel.color)
                    .frame(width: 24)

                Text(reminder.clientName)
                    .font(.headline)

                Spacer()

                Text(reminder.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reminder.status.color.opacity(0.2))
                    .foregroundColor(reminder.status.color)
                    .cornerRadius(8)
            }

            HStack {
                Label(reminder.timing.displayName, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Appointment: \(reminder.appointmentDate, style: .date)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "paperplane")
                        .font(.caption)
                    Text("Sends: \(reminder.sendDate, style: .relative)")
                        .font(.caption)
                }
                .foregroundColor(reminder.status == .pending ? .tranquilTeal : .secondary)
            }

            if let error = reminder.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ScheduledRemindersEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Scheduled Reminders")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Appointment reminders will appear here when scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Campaigns

struct CampaignsView: View {
    @StateObject private var communicationService = CommunicationService.shared
    @State private var filterStatus: CampaignStatus?

    var filteredCampaigns: [MarketingCampaign] {
        var campaigns = communicationService.campaigns

        if let status = filterStatus {
            campaigns = campaigns.filter { $0.status == status }
        }

        return campaigns.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: filterStatus == nil,
                        action: { filterStatus = nil }
                    )

                    ForEach([CampaignStatus.draft, .scheduled, .sent], id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: filterStatus == status,
                            action: { filterStatus = status },
                            color: status.color
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            // Campaigns List
            if filteredCampaigns.isEmpty {
                CampaignsEmptyState()
            } else {
                List {
                    ForEach(filteredCampaigns) { campaign in
                        NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
                            CampaignRow(campaign: campaign)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct CampaignRow: View {
    let campaign: MarketingCampaign

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: campaign.channel.icon)
                    .foregroundColor(campaign.channel.color)
                    .frame(width: 24)

                Text(campaign.name)
                    .font(.headline)

                Spacer()

                Text(campaign.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(campaign.status.color.opacity(0.2))
                    .foregroundColor(campaign.status.color)
                    .cornerRadius(8)
            }

            Text(campaign.targetAudience.description)
                .font(.caption)
                .foregroundColor(.secondary)

            if campaign.status == .sent {
                HStack(spacing: 16) {
                    StatBadge(icon: "paperplane.fill", value: "\(campaign.sentCount)", label: "Sent")
                    StatBadge(icon: "envelope.open.fill", value: String(format: "%.1f%%", campaign.openRate), label: "Opened")
                    StatBadge(icon: "hand.tap.fill", value: String(format: "%.1f%%", campaign.clickRate), label: "Clicked")
                }
            } else if let scheduledDate = campaign.scheduledDate {
                Label("Scheduled for \(scheduledDate, style: .date)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(.tranquilTeal)
    }
}

struct CampaignsEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Campaigns")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a campaign to send bulk messages to multiple clients")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Campaign Detail

struct CampaignDetailView: View {
    let campaign: MarketingCampaign

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(campaign.status.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(campaign.status.color)

                        if let scheduledDate = campaign.scheduledDate {
                            Text("Scheduled for \(scheduledDate, style: .date) at \(scheduledDate, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: campaign.channel.icon)
                        .font(.largeTitle)
                        .foregroundColor(campaign.channel.color)
                }
                .padding()
                .background(campaign.status.color.opacity(0.1))
                .cornerRadius(12)

                // Performance Metrics (if sent)
                if campaign.status == .sent {
                    VStack(spacing: 16) {
                        Text("Campaign Performance")
                            .font(.headline)

                        HStack(spacing: 16) {
                            MetricCard(title: "Sent", value: "\(campaign.sentCount)", icon: "paperplane.fill", color: .blue)
                            MetricCard(title: "Open Rate", value: String(format: "%.1f%%", campaign.openRate), icon: "envelope.open.fill", color: .green)
                            MetricCard(title: "Click Rate", value: String(format: "%.1f%%", campaign.clickRate), icon: "hand.tap.fill", color: .purple)
                        }
                    }
                }

                // Campaign Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Campaign Details")
                        .font(.headline)

                    DetailRow(label: "Name", value: campaign.name)
                    DetailRow(label: "Channel", value: campaign.channel.rawValue)
                    DetailRow(label: "Type", value: campaign.messageType.rawValue)
                    DetailRow(label: "Audience", value: campaign.targetAudience.description)
                    DetailRow(label: "Created", value: campaign.createdDate, style: .date)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Message Content
                if let subject = campaign.subject {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject")
                            .font(.headline)
                        Text(subject)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Message")
                        .font(.headline)
                    Text(campaign.content)
                        .font(.body)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(campaign.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetricCard: View {
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
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    init(label: String, value: Date, style: Date.FormatStyle.DateStyle) {
        self.label = label
        self.value = value.formatted(date: style, time: .omitted)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Analytics

struct AnalyticsView: View {
    @StateObject private var communicationService = CommunicationService.shared

    var totalSent: Int {
        communicationService.messageHistory.filter { $0.status == .sent || $0.status == .delivered }.count
    }

    var emailCount: Int {
        communicationService.messageHistory.filter { $0.channel == .email }.count
    }

    var smsCount: Int {
        communicationService.messageHistory.filter { $0.channel == .sms }.count
    }

    var openRate: Double {
        let emailMessages = communicationService.messageHistory.filter { $0.channel == .email && ($0.status == .delivered || $0.status == .opened) }
        guard !emailMessages.isEmpty else { return 0 }
        let opened = emailMessages.filter { $0.openedDate != nil }.count
        return Double(opened) / Double(emailMessages.count) * 100
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Overview Cards
                Text("Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    AnalyticsCard(
                        title: "Total Sent",
                        value: "\(totalSent)",
                        icon: "paperplane.fill",
                        color: .blue
                    )

                    AnalyticsCard(
                        title: "Open Rate",
                        value: String(format: "%.1f%%", openRate),
                        icon: "envelope.open.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    AnalyticsCard(
                        title: "Emails",
                        value: "\(emailCount)",
                        icon: "envelope.fill",
                        color: .purple
                    )

                    AnalyticsCard(
                        title: "SMS",
                        value: "\(smsCount)",
                        icon: "message.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Message Type Breakdown
                Text("By Message Type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)

                VStack(spacing: 12) {
                    ForEach(MessageType.allCases, id: \.self) { type in
                        let count = communicationService.messageHistory.filter { $0.messageType == type }.count
                        if count > 0 {
                            MessageTypeBar(type: type, count: count, total: totalSent)
                        }
                    }
                }
                .padding(.horizontal)

                // Recent Activity
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)

                VStack(spacing: 8) {
                    ForEach(communicationService.messageHistory.prefix(10)) { message in
                        RecentActivityRow(message: message)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MessageTypeBar: View {
    let type: MessageType
    let count: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(type.rawValue, systemImage: type.icon)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    Rectangle()
                        .fill(Color.tranquilTeal)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct RecentActivityRow: View {
    let message: CommunicationMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.channel.icon)
                .foregroundColor(message.channel.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.recipientName ?? message.recipientContact)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(message.messageType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(message.status.rawValue)
                    .font(.caption)
                    .foregroundColor(message.status.color)
                Text(message.createdDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var color: Color = .tranquilTeal

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(16)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Extensions

extension CommunicationChannel {
    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .push: return "bell.fill"
        case .inApp: return "app.fill"
        }
    }

    var color: Color {
        switch self {
        case .email: return .purple
        case .sms: return .green
        case .push: return .orange
        case .inApp: return .blue
        }
    }
}

extension MessageStatus {
    var color: Color {
        switch self {
        case .pending, .scheduled: return .orange
        case .sent, .delivered: return .blue
        case .opened: return .green
        case .failed, .bounced: return .red
        case .unsubscribed: return .gray
        }
    }
}

extension MessageType {
    var icon: String {
        switch self {
        case .appointmentReminder: return "bell.fill"
        case .appointmentConfirmation: return "checkmark.circle.fill"
        case .followUp: return "arrow.turn.up.right"
        case .birthdayGreeting: return "gift.fill"
        case .reviewRequest: return "star.fill"
        case .promotional: return "megaphone.fill"
        case .newsletter: return "newspaper.fill"
        case .welcomeSeries: return "hand.wave.fill"
        case .reEngagement: return "arrow.clockwise"
        case .cancellationFollowUp: return "xmark.circle.fill"
        case .thankYou: return "heart.fill"
        case .custom: return "text.bubble.fill"
        }
    }
}

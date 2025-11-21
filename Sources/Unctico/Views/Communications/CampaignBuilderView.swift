import SwiftUI

/// Bulk messaging campaign creation interface
struct CampaignBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var communicationService = CommunicationService.shared

    @State private var currentStep = 0
    @State private var campaignName = ""
    @State private var channel: CommunicationChannel = .email
    @State private var messageType: MessageType = .promotional
    @State private var subject = ""
    @State private var body = ""
    @State private var targetAudience: AudienceFilter = .all
    @State private var enableScheduling = false
    @State private var scheduledDate: Date?

    @State private var estimatedRecipients = 0
    @State private var isCreating = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?

    let steps = ["Setup", "Audience", "Message", "Review"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                CampaignProgressBar(currentStep: currentStep, totalSteps: steps.count, stepNames: steps)

                // Content
                TabView(selection: $currentStep) {
                    SetupStepView(
                        campaignName: $campaignName,
                        channel: $channel,
                        messageType: $messageType
                    )
                    .tag(0)

                    AudienceStepView(
                        targetAudience: $targetAudience,
                        estimatedRecipients: $estimatedRecipients
                    )
                    .tag(1)

                    MessageStepView(
                        channel: channel,
                        subject: $subject,
                        body: $body
                    )
                    .tag(2)

                    ReviewStepView(
                        campaignName: campaignName,
                        channel: channel,
                        messageType: messageType,
                        targetAudience: targetAudience,
                        subject: subject,
                        body: body,
                        estimatedRecipients: estimatedRecipients,
                        enableScheduling: $enableScheduling,
                        scheduledDate: $scheduledDate
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                    }

                    Button(action: nextAction) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(currentStep == steps.count - 1 ? "Create Campaign" : "Continue")
                                if currentStep < steps.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed() ? Color.tranquilTeal : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canProceed() || isCreating)
                }
                .padding()

                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Campaign Created", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your campaign has been created and will be sent \(enableScheduling ? "at the scheduled time" : "shortly")")
            }
        }
    }

    // MARK: - Helper Methods

    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return !campaignName.isEmpty
        case 1:
            return true // Audience always has a default
        case 2:
            return !body.isEmpty && (channel != .email || !subject.isEmpty)
        case 3:
            return true
        default:
            return false
        }
    }

    private func nextAction() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            createCampaign()
        }
    }

    private func createCampaign() {
        guard canProceed() else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                let campaign = MarketingCampaign(
                    name: campaignName,
                    channel: channel,
                    messageType: messageType,
                    subject: channel == .email ? subject : nil,
                    content: body,
                    targetAudience: targetAudience,
                    scheduledDate: enableScheduling ? scheduledDate : nil,
                    status: enableScheduling ? .scheduled : .draft
                )

                try await communicationService.createCampaign(campaign)

                await MainActor.run {
                    isCreating = false
                    showingSuccess = true

                    AuditLogger.shared.log(
                        event: .userAction,
                        details: "Marketing campaign created: \(campaignName)"
                    )
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Progress Bar

struct CampaignProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let stepNames: [String]

    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.tranquilTeal)
                        .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 4)

            // Step Labels
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(index <= currentStep ? Color.tranquilTeal : Color(.systemGray5))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(index <= currentStep ? .white : .gray)
                            )

                        Text(stepNames[index])
                            .font(.caption)
                            .foregroundColor(index <= currentStep ? .tranquilTeal : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Step 1: Setup

struct SetupStepView: View {
    @Binding var campaignName: String
    @Binding var channel: CommunicationChannel
    @Binding var messageType: MessageType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Campaign Setup")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Configure the basic details for your campaign")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Campaign Name")
                        .font(.headline)

                    TextField("e.g., Spring Promotion 2024", text: $campaignName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Channel")
                        .font(.headline)

                    Picker("Channel", selection: $channel) {
                        ForEach([CommunicationChannel.email, .sms], id: \.self) { ch in
                            Label(ch.rawValue, systemImage: ch.icon)
                                .tag(ch)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Message Type")
                        .font(.headline)

                    Picker("Type", selection: $messageType) {
                        ForEach(MessageType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Step 2: Audience

struct AudienceStepView: View {
    @Binding var targetAudience: AudienceFilter
    @Binding var estimatedRecipients: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Audience")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose who will receive this campaign")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    AudienceOptionCard(
                        title: "All Clients",
                        description: "Send to all active clients",
                        icon: "person.3.fill",
                        isSelected: isSelected(.all),
                        action: { selectAudience(.all) }
                    )

                    AudienceOptionCard(
                        title: "Recent Visitors",
                        description: "Clients who visited in last 30 days",
                        icon: "calendar",
                        isSelected: isSelected(.lastVisit(daysAgo: 30)),
                        action: { selectAudience(.lastVisit(daysAgo: 30)) }
                    )

                    AudienceOptionCard(
                        title: "Inactive Clients",
                        description: "Re-engage clients who haven't visited in 90+ days",
                        icon: "arrow.clockwise",
                        isSelected: isSelected(.lastVisit(daysAgo: 90)),
                        action: { selectAudience(.lastVisit(daysAgo: 90)) }
                    )

                    AudienceOptionCard(
                        title: "New Clients",
                        description: "Clients who never visited",
                        icon: "person.badge.plus",
                        isSelected: isSelected(.neverVisited),
                        action: { selectAudience(.neverVisited) }
                    )

                    AudienceOptionCard(
                        title: "Birthday This Month",
                        description: "Send birthday greetings",
                        icon: "gift.fill",
                        isSelected: isBirthdaySelected(),
                        action: { selectAudience(.birthday(month: Calendar.current.component(.month, from: Date()))) }
                    )
                }

                // Estimated Recipients
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.tranquilTeal)
                    Text("Estimated Recipients:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(estimatedRecipients)")
                        .font(.headline)
                        .foregroundColor(.tranquilTeal)
                }
                .padding()
                .background(Color.tranquilTeal.opacity(0.1))
                .cornerRadius(10)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            calculateEstimatedRecipients()
        }
    }

    private func isSelected(_ filter: AudienceFilter) -> Bool {
        switch (targetAudience, filter) {
        case (.all, .all):
            return true
        case (.neverVisited, .neverVisited):
            return true
        case (.lastVisit(let days1), .lastVisit(let days2)):
            return days1 == days2
        default:
            return false
        }
    }

    private func isBirthdaySelected() -> Bool {
        if case .birthday = targetAudience {
            return true
        }
        return false
    }

    private func selectAudience(_ filter: AudienceFilter) {
        targetAudience = filter
        calculateEstimatedRecipients()
    }

    private func calculateEstimatedRecipients() {
        // TODO: Calculate from actual client repository
        switch targetAudience {
        case .all:
            estimatedRecipients = 150
        case .lastVisit(let days):
            estimatedRecipients = days <= 30 ? 45 : 30
        case .neverVisited:
            estimatedRecipients = 12
        case .birthday:
            estimatedRecipients = 8
        case .custom:
            estimatedRecipients = 0
        }
    }
}

struct AudienceOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .tranquilTeal : .gray)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.tranquilTeal)
                        .font(.title3)
                }
            }
            .padding()
            .background(isSelected ? Color.tranquilTeal.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tranquilTeal : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Step 3: Message

struct MessageStepView: View {
    let channel: CommunicationChannel
    @Binding var subject: String
    @Binding var body: String

    @StateObject private var communicationService = CommunicationService.shared
    @State private var selectedTemplate: MessageTemplate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Content")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Compose your message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Template Selector
                if !communicationService.templates.filter({ $0.channel == channel }).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Use Template")
                            .font(.headline)

                        Picker("Template", selection: $selectedTemplate) {
                            Text("None").tag(nil as MessageTemplate?)
                            ForEach(communicationService.templates.filter { $0.channel == channel }) { template in
                                Text(template.name).tag(template as MessageTemplate?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedTemplate) { _, template in
                            if let template = template {
                                applyTemplate(template)
                            }
                        }
                    }
                }

                // Subject (Email only)
                if channel == .email {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subject Line")
                            .font(.headline)

                        TextField("Enter email subject", text: $subject)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // Message Body
                VStack(alignment: .leading, spacing: 12) {
                    Text(channel == .email ? "Email Body" : "Message")
                        .font(.headline)

                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    if channel == .sms {
                        HStack {
                            Spacer()
                            Text("\(body.count)/160 characters")
                                .font(.caption)
                                .foregroundColor(body.count > 160 ? .red : .secondary)
                        }
                    }
                }

                // Variable Hints
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Variables")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            VariableChip(title: "{{clientName}}", action: { body += "{{clientName}}" })
                            VariableChip(title: "{{therapistName}}", action: { body += "{{therapistName}}" })
                            VariableChip(title: "{{practiceName}}", action: { body += "{{practiceName}}" })
                            VariableChip(title: "{{date}}", action: { body += "{{date}}" })
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    private func applyTemplate(_ template: MessageTemplate) {
        subject = template.subject ?? ""
        body = template.content
    }
}

// MARK: - Step 4: Review

struct ReviewStepView: View {
    let campaignName: String
    let channel: CommunicationChannel
    let messageType: MessageType
    let targetAudience: AudienceFilter
    let subject: String
    let body: String
    let estimatedRecipients: Int
    @Binding var enableScheduling: Bool
    @Binding var scheduledDate: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review Campaign")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Review your campaign before sending")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Campaign Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Campaign Details")
                        .font(.headline)

                    ReviewRow(label: "Name", value: campaignName)
                    ReviewRow(label: "Channel", icon: channel.icon, value: channel.rawValue)
                    ReviewRow(label: "Type", value: messageType.rawValue)
                    ReviewRow(label: "Audience", value: targetAudience.description)
                    ReviewRow(label: "Recipients", value: "\(estimatedRecipients) clients")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Message Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Message Preview")
                        .font(.headline)

                    if channel == .email {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(subject)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(channel == .email ? "Body:" : "Message:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(body)
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Scheduling
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Schedule for Later", isOn: $enableScheduling)
                        .font(.headline)

                    if enableScheduling {
                        DatePicker("Send Date", selection: Binding(
                            get: { scheduledDate ?? Date().addingTimeInterval(3600) },
                            set: { scheduledDate = $0 }
                        ), in: Date()...)
                        .padding(.leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Cost Estimate (if applicable)
                if channel == .sms {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Estimated Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(String(format: "%.2f", Double(estimatedRecipients) * 0.01))")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct ReviewRow: View {
    let label: String
    var icon: String?
    let value: String

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.tranquilTeal)
                    .frame(width: 20)
            }

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

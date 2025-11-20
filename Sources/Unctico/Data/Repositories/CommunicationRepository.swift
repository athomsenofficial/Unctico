import Foundation

/// Repository for managing communications, campaigns, and workflows
@MainActor
class CommunicationRepository: ObservableObject {
    static let shared = CommunicationRepository()

    @Published var messages: [CommunicationMessage] = []
    @Published var campaigns: [MarketingCampaign] = []
    @Published var workflows: [AutomatedWorkflow] = []
    @Published var reviewRequests: [ReviewRequest] = []
    @Published var clientPreferences: [UUID: ClientCommunicationPreferences] = [:]

    private let messagesKey = "unctico_messages"
    private let campaignsKey = "unctico_campaigns"
    private let workflowsKey = "unctico_workflows"
    private let reviewRequestsKey = "unctico_review_requests"
    private let preferencesKey = "unctico_client_comm_preferences"

    init() {
        loadData()
    }

    // MARK: - Message Management

    func addMessage(_ message: CommunicationMessage) {
        messages.append(message)
        saveMessages()
    }

    func updateMessage(_ message: CommunicationMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            saveMessages()
        }
    }

    func deleteMessage(_ messageId: UUID) {
        messages.removeAll { $0.id == messageId }
        saveMessages()
    }

    func getMessages(for clientId: UUID) -> [CommunicationMessage] {
        messages.filter { $0.clientId == clientId }
            .sorted { $0.scheduledFor ?? $0.createdAt > $1.scheduledFor ?? $1.createdAt }
    }

    func getMessages(for campaign: MarketingCampaign) -> [CommunicationMessage] {
        messages.filter { $0.campaignId == campaign.id }
    }

    func getPendingMessages() -> [CommunicationMessage] {
        messages.filter { $0.status == .pending || $0.status == .scheduled }
    }

    func getScheduledMessages() -> [CommunicationMessage] {
        messages.filter {
            $0.status == .scheduled &&
            $0.scheduledFor != nil &&
            $0.scheduledFor! <= Date()
        }
    }

    // MARK: - Campaign Management

    func createCampaign(_ campaign: MarketingCampaign) {
        campaigns.append(campaign)
        saveCampaigns()
    }

    func updateCampaign(_ campaign: MarketingCampaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[index] = campaign
            saveCampaigns()
        }
    }

    func deleteCampaign(_ campaignId: UUID) {
        campaigns.removeAll { $0.id == campaignId }
        // Also delete associated messages
        messages.removeAll { $0.campaignId == campaignId }
        saveCampaigns()
        saveMessages()
    }

    func getActiveCampaigns() -> [MarketingCampaign] {
        campaigns.filter { $0.status == .active || $0.status == .scheduled }
    }

    func getCampaignStatistics(_ campaignId: UUID) -> CampaignStatistics {
        let campaignMessages = messages.filter { $0.campaignId == campaignId }

        let totalSent = campaignMessages.filter { $0.status == .sent }.count
        let totalDelivered = campaignMessages.filter { $0.status == .delivered }.count
        let totalOpened = campaignMessages.filter { $0.wasOpened }.count
        let totalClicked = campaignMessages.filter { $0.wasClicked }.count
        let totalFailed = campaignMessages.filter { $0.status == .failed }.count

        let openRate = totalDelivered > 0 ? Double(totalOpened) / Double(totalDelivered) * 100 : 0
        let clickRate = totalOpened > 0 ? Double(totalClicked) / Double(totalOpened) * 100 : 0
        let deliveryRate = totalSent > 0 ? Double(totalDelivered) / Double(totalSent) * 100 : 0

        return CampaignStatistics(
            totalRecipients: campaignMessages.count,
            totalSent: totalSent,
            totalDelivered: totalDelivered,
            totalOpened: totalOpened,
            totalClicked: totalClicked,
            totalFailed: totalFailed,
            openRate: openRate,
            clickRate: clickRate,
            deliveryRate: deliveryRate
        )
    }

    // MARK: - Workflow Management

    func createWorkflow(_ workflow: AutomatedWorkflow) {
        workflows.append(workflow)
        saveWorkflows()
    }

    func updateWorkflow(_ workflow: AutomatedWorkflow) {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
            saveWorkflows()
        }
    }

    func deleteWorkflow(_ workflowId: UUID) {
        workflows.removeAll { $0.id == workflowId }
        saveWorkflows()
    }

    func getActiveWorkflows() -> [AutomatedWorkflow] {
        workflows.filter { $0.isActive }
    }

    func getWorkflows(for trigger: WorkflowTrigger) -> [AutomatedWorkflow] {
        workflows.filter { $0.trigger == trigger && $0.isActive }
    }

    /// Check if workflow should trigger and return actions to execute
    func checkWorkflowTriggers(
        trigger: WorkflowTrigger,
        clientId: UUID,
        context: [String: String] = [:]
    ) -> [WorkflowAction] {
        let matchingWorkflows = getWorkflows(for: trigger)
        var actions: [WorkflowAction] = []

        for workflow in matchingWorkflows {
            // Check if client preferences allow this
            if let prefs = clientPreferences[clientId] {
                if !prefs.allowsMarketing && workflow.actions.contains(where: { $0 == .sendPromotion }) {
                    continue
                }
                if !prefs.allowsReminders && workflow.actions.contains(where: { $0 == .sendReminder }) {
                    continue
                }
            }

            actions.append(contentsOf: workflow.actions)
        }

        return actions
    }

    // MARK: - Review Request Management

    func createReviewRequest(_ request: ReviewRequest) {
        reviewRequests.append(request)
        saveReviewRequests()
    }

    func updateReviewRequest(_ request: ReviewRequest) {
        if let index = reviewRequests.firstIndex(where: { $0.id == request.id }) {
            reviewRequests[index] = request
            saveReviewRequests()
        }
    }

    func getReviewRequests(for clientId: UUID) -> [ReviewRequest] {
        reviewRequests.filter { $0.clientId == clientId }
    }

    func getPendingReviewRequests() -> [ReviewRequest] {
        reviewRequests.filter { $0.status == .pending }
    }

    func markReviewAsCompleted(_ requestId: UUID, reviewUrl: String? = nil) {
        if let index = reviewRequests.firstIndex(where: { $0.id == requestId }) {
            reviewRequests[index].status = .completed
            reviewRequests[index].completedAt = Date()
            reviewRequests[index].reviewUrl = reviewUrl
            saveReviewRequests()
        }
    }

    // MARK: - Client Preferences

    func updateClientPreferences(_ preferences: ClientCommunicationPreferences) {
        clientPreferences[preferences.clientId] = preferences
        savePreferences()
    }

    func getClientPreferences(for clientId: UUID) -> ClientCommunicationPreferences {
        clientPreferences[clientId] ?? ClientCommunicationPreferences(clientId: clientId)
    }

    func canSendMessage(to clientId: UUID, messageType: MessageType) -> Bool {
        let prefs = getClientPreferences(for: clientId)

        switch messageType {
        case .appointmentReminder, .appointmentConfirmation, .cancellationConfirmation:
            return prefs.allowsReminders
        case .promotional, .newsletter, .specialOffer:
            return prefs.allowsMarketing
        case .reviewRequest:
            return prefs.allowsReviewRequests
        default:
            return true // Allow transactional messages by default
        }
    }

    // MARK: - Analytics

    func getMessageStatistics(from startDate: Date, to endDate: Date) -> MessageStatistics {
        let periodMessages = messages.filter {
            $0.createdAt >= startDate && $0.createdAt <= endDate
        }

        let totalMessages = periodMessages.count
        let sentMessages = periodMessages.filter { $0.status == .sent || $0.status == .delivered }.count
        let failedMessages = periodMessages.filter { $0.status == .failed }.count
        let openedMessages = periodMessages.filter { $0.wasOpened }.count
        let clickedMessages = periodMessages.filter { $0.wasClicked }.count

        let openRate = sentMessages > 0 ? Double(openedMessages) / Double(sentMessages) * 100 : 0
        let clickRate = openedMessages > 0 ? Double(clickedMessages) / Double(openedMessages) * 100 : 0
        let deliveryRate = totalMessages > 0 ? Double(sentMessages) / Double(totalMessages) * 100 : 0

        // Messages by channel
        let messagesByChannel = Dictionary(grouping: periodMessages, by: { $0.channel })
            .mapValues { $0.count }

        // Messages by type
        let messagesByType = Dictionary(grouping: periodMessages, by: { $0.messageType })
            .mapValues { $0.count }

        return MessageStatistics(
            totalMessages: totalMessages,
            sentMessages: sentMessages,
            failedMessages: failedMessages,
            openedMessages: openedMessages,
            clickedMessages: clickedMessages,
            openRate: openRate,
            clickRate: clickRate,
            deliveryRate: deliveryRate,
            messagesByChannel: messagesByChannel,
            messagesByType: messagesByType
        )
    }

    func getReviewStatistics() -> ReviewStatistics {
        let total = reviewRequests.count
        let pending = reviewRequests.filter { $0.status == .pending }.count
        let sent = reviewRequests.filter { $0.status == .sent }.count
        let completed = reviewRequests.filter { $0.status == .completed }.count
        let declined = reviewRequests.filter { $0.status == .declined }.count

        let completionRate = sent > 0 ? Double(completed) / Double(sent) * 100 : 0

        let byPlatform = Dictionary(grouping: reviewRequests, by: { $0.platform })
            .mapValues { requests in
                requests.filter { $0.status == .completed }.count
            }

        return ReviewStatistics(
            totalRequests: total,
            pendingRequests: pending,
            sentRequests: sent,
            completedReviews: completed,
            declinedRequests: declined,
            completionRate: completionRate,
            reviewsByPlatform: byPlatform
        )
    }

    // MARK: - Scheduled Message Processing

    /// Process scheduled messages that are due to be sent
    func processScheduledMessages() async -> [CommunicationMessage] {
        let dueSend = getScheduledMessages()
        var processed: [CommunicationMessage] = []

        for var message in dueSend {
            // Check client preferences
            guard canSendMessage(to: message.clientId, messageType: message.messageType) else {
                message.status = .cancelled
                updateMessage(message)
                continue
            }

            // Send through communication service
            do {
                let sent = try await CommunicationService.shared.sendMessage(message)
                updateMessage(sent)
                processed.append(sent)
            } catch {
                message.status = .failed
                message.failureReason = error.localizedDescription
                updateMessage(message)
            }
        }

        return processed
    }

    // MARK: - Automated Workflows Execution

    /// Execute workflow actions
    func executeWorkflowActions(
        _ actions: [WorkflowAction],
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        context: [String: String] = [:]
    ) async {
        for action in actions {
            await executeWorkflowAction(
                action,
                clientId: clientId,
                clientName: clientName,
                recipientContact: recipientContact,
                context: context
            )
        }
    }

    private func executeWorkflowAction(
        _ action: WorkflowAction,
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        context: [String: String]
    ) async {
        switch action {
        case .sendReminder:
            await sendReminderAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact, context: context)

        case .sendFollowUp:
            await sendFollowUpAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact)

        case .sendPromotion:
            await sendPromotionAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact)

        case .requestReview:
            await requestReviewAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact)

        case .sendBirthdayGreeting:
            await sendBirthdayAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact)

        case .sendReactivation:
            await sendReactivationAction(clientId: clientId, clientName: clientName, recipientContact: recipientContact)

        case .createTask:
            // Create internal task for staff follow-up
            break

        case .updateClientTag:
            // Update client tags/segments
            break
        }
    }

    private func sendReminderAction(clientId: UUID, clientName: String, recipientContact: String, context: [String: String]) async {
        guard let appointmentDate = context["appointmentDate"],
              let appointmentTime = context["appointmentTime"],
              let therapistName = context["therapistName"] else { return }

        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: appointmentDate) else { return }

        let message = CommunicationService.shared.createAppointmentReminder(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            appointmentDate: date,
            appointmentTime: appointmentTime,
            therapistName: therapistName
        )

        addMessage(message)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)
        } catch {
            var failed = message
            failed.status = .failed
            failed.failureReason = error.localizedDescription
            updateMessage(failed)
        }
    }

    private func sendFollowUpAction(clientId: UUID, clientName: String, recipientContact: String) async {
        let message = CommunicationService.shared.createFollowUp(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            lastAppointmentDate: Date()
        )

        addMessage(message)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)
        } catch {
            var failed = message
            failed.status = .failed
            updateMessage(failed)
        }
    }

    private func sendPromotionAction(clientId: UUID, clientName: String, recipientContact: String) async {
        // Create promotional message
        let message = CommunicationMessage(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            messageType: .promotional,
            channel: .email,
            subject: "Special Offer Just For You!",
            content: "Hi \(clientName), we have a special offer just for you! Book your next massage and save 20%."
        )

        addMessage(message)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)
        } catch {
            var failed = message
            failed.status = .failed
            updateMessage(failed)
        }
    }

    private func requestReviewAction(clientId: UUID, clientName: String, recipientContact: String) async {
        let message = CommunicationService.shared.createReviewRequest(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            reviewPlatform: .google
        )

        addMessage(message)

        let reviewRequest = ReviewRequest(
            clientId: clientId,
            platform: .google,
            messageId: message.id
        )

        createReviewRequest(reviewRequest)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)

            var updated = reviewRequest
            updated.status = .sent
            updated.sentAt = Date()
            updateReviewRequest(updated)
        } catch {
            var failed = message
            failed.status = .failed
            updateMessage(failed)
        }
    }

    private func sendBirthdayAction(clientId: UUID, clientName: String, recipientContact: String) async {
        guard let template = CommunicationService.shared.getTemplate(for: .birthdayGreeting) else { return }

        let message = CommunicationService.shared.createMessageFromTemplate(
            template,
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact
        )

        addMessage(message)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)
        } catch {
            var failed = message
            failed.status = .failed
            updateMessage(failed)
        }
    }

    private func sendReactivationAction(clientId: UUID, clientName: String, recipientContact: String) async {
        let message = CommunicationMessage(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            messageType: .winBack,
            channel: .email,
            subject: "We Miss You!",
            content: "Hi \(clientName), we've missed seeing you! Come back and enjoy 25% off your next massage session."
        )

        addMessage(message)

        do {
            let sent = try await CommunicationService.shared.sendMessage(message)
            updateMessage(sent)
        } catch {
            var failed = message
            failed.status = .failed
            updateMessage(failed)
        }
    }

    // MARK: - Data Export

    func exportMessages(from startDate: Date, to endDate: Date) -> String {
        let periodMessages = messages.filter {
            $0.createdAt >= startDate && $0.createdAt <= endDate
        }.sorted { $0.createdAt > $1.createdAt }

        var csv = "Date,Client Name,Channel,Type,Status,Subject,Opened,Clicked\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for message in periodMessages {
            let date = dateFormatter.string(from: message.createdAt)
            let subject = message.subject?.replacingOccurrences(of: ",", with: ";") ?? "N/A"

            csv += "\(date),\(message.clientName),\(message.channel.rawValue),\(message.messageType.rawValue),\(message.status.rawValue),\(subject),\(message.wasOpened),\(message.wasClicked)\n"
        }

        return csv
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: messagesKey),
           let decoded = try? JSONDecoder().decode([CommunicationMessage].self, from: data) {
            messages = decoded
        }

        if let data = UserDefaults.standard.data(forKey: campaignsKey),
           let decoded = try? JSONDecoder().decode([MarketingCampaign].self, from: data) {
            campaigns = decoded
        }

        if let data = UserDefaults.standard.data(forKey: workflowsKey),
           let decoded = try? JSONDecoder().decode([AutomatedWorkflow].self, from: data) {
            workflows = decoded
        }

        if let data = UserDefaults.standard.data(forKey: reviewRequestsKey),
           let decoded = try? JSONDecoder().decode([ReviewRequest].self, from: data) {
            reviewRequests = decoded
        }

        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode([UUID: ClientCommunicationPreferences].self, from: data) {
            clientPreferences = decoded
        }
    }

    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: messagesKey)
        }
    }

    private func saveCampaigns() {
        if let encoded = try? JSONEncoder().encode(campaigns) {
            UserDefaults.standard.set(encoded, forKey: campaignsKey)
        }
    }

    private func saveWorkflows() {
        if let encoded = try? JSONEncoder().encode(workflows) {
            UserDefaults.standard.set(encoded, forKey: workflowsKey)
        }
    }

    private func saveReviewRequests() {
        if let encoded = try? JSONEncoder().encode(reviewRequests) {
            UserDefaults.standard.set(encoded, forKey: reviewRequestsKey)
        }
    }

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(clientPreferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
}

// MARK: - Supporting Types

struct CampaignStatistics {
    let totalRecipients: Int
    let totalSent: Int
    let totalDelivered: Int
    let totalOpened: Int
    let totalClicked: Int
    let totalFailed: Int
    let openRate: Double
    let clickRate: Double
    let deliveryRate: Double
}

struct MessageStatistics {
    let totalMessages: Int
    let sentMessages: Int
    let failedMessages: Int
    let openedMessages: Int
    let clickedMessages: Int
    let openRate: Double
    let clickRate: Double
    let deliveryRate: Double
    let messagesByChannel: [CommunicationChannel: Int]
    let messagesByType: [MessageType: Int]
}

struct ReviewStatistics {
    let totalRequests: Int
    let pendingRequests: Int
    let sentRequests: Int
    let completedReviews: Int
    let declinedRequests: Int
    let completionRate: Double
    let reviewsByPlatform: [ReviewPlatform: Int]
}

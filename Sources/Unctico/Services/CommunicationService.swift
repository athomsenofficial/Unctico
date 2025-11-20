import Foundation

/// Service for managing client communications via SMS and Email
@MainActor
class CommunicationService: ObservableObject {
    static let shared = CommunicationService()

    @Published var serviceConfigs: [CommunicationChannel: CommunicationServiceConfig] = [:]
    @Published var messageTemplates: [MessageTemplate] = []
    @Published var isConfigured: Bool = false

    private let configKey = "unctico_communication_configs"
    private let templatesKey = "unctico_message_templates"

    init() {
        loadConfigurations()
        loadTemplates()
        initializeDefaultTemplates()
    }

    // MARK: - Configuration Management

    func updateServiceConfig(_ config: CommunicationServiceConfig) {
        serviceConfigs[config.channel] = config
        updateConfigurationStatus()
        saveConfigurations()
    }

    func getServiceConfig(for channel: CommunicationChannel) -> CommunicationServiceConfig? {
        serviceConfigs[channel]
    }

    func isChannelConfigured(_ channel: CommunicationChannel) -> Bool {
        guard let config = serviceConfigs[channel] else { return false }
        return config.isEnabled && !config.apiKey.isEmpty
    }

    private func updateConfigurationStatus() {
        isConfigured = serviceConfigs.values.contains { $0.isEnabled && !$0.apiKey.isEmpty }
    }

    // MARK: - Message Sending

    /// Send a communication message
    func sendMessage(_ message: CommunicationMessage) async throws -> CommunicationMessage {
        guard isChannelConfigured(message.channel) else {
            throw CommunicationError.channelNotConfigured
        }

        var updatedMessage = message
        updatedMessage.status = .sending

        do {
            // Simulate sending (in production, integrate with actual services)
            switch message.channel {
            case .sms:
                try await sendSMS(message)
            case .email:
                try await sendEmail(message)
            case .push:
                try await sendPushNotification(message)
            case .inApp:
                // In-app messages are stored and displayed within the app
                break
            }

            updatedMessage.status = .sent
            updatedMessage.sentAt = Date()

        } catch {
            updatedMessage.status = .failed
            updatedMessage.failureReason = error.localizedDescription
            throw error
        }

        return updatedMessage
    }

    /// Send SMS via configured provider (Twilio, etc.)
    private func sendSMS(_ message: CommunicationMessage) async throws {
        guard let config = serviceConfigs[.sms], config.isEnabled else {
            throw CommunicationError.channelNotConfigured
        }

        // In production, integrate with actual SMS provider
        // Example for Twilio:
        // let client = TwilioClient(accountSid: config.apiKey, authToken: config.secretKey)
        // try await client.sendMessage(
        //     from: config.senderIdentity,
        //     to: message.recipientContact,
        //     body: message.content
        // )

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

        // Simulate 95% success rate
        if Double.random(in: 0...1) < 0.05 {
            throw CommunicationError.sendFailed("SMS delivery failed")
        }
    }

    /// Send Email via configured provider (SendGrid, etc.)
    private func sendEmail(_ message: CommunicationMessage) async throws {
        guard let config = serviceConfigs[.email], config.isEnabled else {
            throw CommunicationError.channelNotConfigured
        }

        // In production, integrate with actual email provider
        // Example for SendGrid:
        // let sendGrid = SendGridClient(apiKey: config.apiKey)
        // try await sendGrid.sendEmail(
        //     from: config.senderIdentity,
        //     to: message.recipientContact,
        //     subject: message.subject ?? "Message from \(config.senderIdentity)",
        //     body: message.content,
        //     isHTML: true
        // )

        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay

        // Simulate 98% success rate
        if Double.random(in: 0...1) < 0.02 {
            throw CommunicationError.sendFailed("Email delivery failed")
        }
    }

    /// Send push notification
    private func sendPushNotification(_ message: CommunicationMessage) async throws {
        // In production, integrate with APNs for iOS
        // Example:
        // let apns = APNSClient(...)
        // try await apns.send(
        //     deviceToken: message.recipientContact,
        //     payload: APNSPayload(alert: message.content, badge: 1)
        // )

        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }

    // MARK: - Bulk Sending

    /// Send messages in bulk (for campaigns)
    func sendBulkMessages(_ messages: [CommunicationMessage]) async -> [CommunicationMessage] {
        var results: [CommunicationMessage] = []

        for message in messages {
            do {
                let sent = try await sendMessage(message)
                results.append(sent)
            } catch {
                var failed = message
                failed.status = .failed
                failed.failureReason = error.localizedDescription
                results.append(failed)
            }

            // Rate limiting: delay between messages
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        }

        return results
    }

    // MARK: - Template Management

    func addTemplate(_ template: MessageTemplate) {
        messageTemplates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: MessageTemplate) {
        if let index = messageTemplates.firstIndex(where: { $0.id == template.id }) {
            messageTemplates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ templateId: UUID) {
        messageTemplates.removeAll { $0.id == templateId }
        saveTemplates()
    }

    func getTemplate(for messageType: MessageType) -> MessageTemplate? {
        messageTemplates.first { $0.messageType == messageType }
    }

    func getTemplates(for channel: CommunicationChannel) -> [MessageTemplate] {
        messageTemplates.filter { $0.channel == channel }
    }

    /// Render template with variables
    func renderTemplate(_ template: MessageTemplate, variables: [String: String]) -> String {
        var rendered = template.content

        for (key, value) in variables {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        return rendered
    }

    /// Create message from template
    func createMessageFromTemplate(
        _ template: MessageTemplate,
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        variables: [String: String] = [:]
    ) -> CommunicationMessage {
        var allVariables = variables
        allVariables["clientName"] = clientName
        allVariables["firstName"] = clientName.components(separatedBy: " ").first ?? clientName

        let content = renderTemplate(template, variables: allVariables)

        return CommunicationMessage(
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            messageType: template.messageType,
            channel: template.channel,
            subject: template.subject,
            content: content
        )
    }

    // MARK: - Appointment Reminders

    /// Generate appointment reminder message
    func createAppointmentReminder(
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        appointmentDate: Date,
        appointmentTime: String,
        therapistName: String,
        channel: CommunicationChannel = .sms
    ) -> CommunicationMessage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let template = getTemplate(for: .appointmentReminder) ?? defaultAppointmentReminderTemplate(for: channel)

        let variables: [String: String] = [
            "clientName": clientName,
            "date": dateFormatter.string(from: appointmentDate),
            "time": appointmentTime,
            "therapist": therapistName
        ]

        return createMessageFromTemplate(
            template,
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            variables: variables
        )
    }

    /// Generate appointment confirmation
    func createAppointmentConfirmation(
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        appointmentDate: Date,
        appointmentTime: String,
        channel: CommunicationChannel = .email
    ) -> CommunicationMessage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let template = getTemplate(for: .appointmentConfirmation) ?? defaultAppointmentConfirmationTemplate(for: channel)

        let variables: [String: String] = [
            "clientName": clientName,
            "date": dateFormatter.string(from: appointmentDate),
            "time": appointmentTime
        ]

        return createMessageFromTemplate(
            template,
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            variables: variables
        )
    }

    /// Generate follow-up message
    func createFollowUp(
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        lastAppointmentDate: Date,
        channel: CommunicationChannel = .email
    ) -> CommunicationMessage {
        let template = getTemplate(for: .followUp) ?? defaultFollowUpTemplate(for: channel)

        let variables: [String: String] = [
            "clientName": clientName
        ]

        return createMessageFromTemplate(
            template,
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            variables: variables
        )
    }

    // MARK: - Review Requests

    /// Create review request message
    func createReviewRequest(
        clientId: UUID,
        clientName: String,
        recipientContact: String,
        reviewPlatform: ReviewPlatform,
        channel: CommunicationChannel = .email
    ) -> CommunicationMessage {
        let template = getTemplate(for: .reviewRequest) ?? defaultReviewRequestTemplate(for: channel)

        let reviewLink = getReviewLink(for: reviewPlatform)

        let variables: [String: String] = [
            "clientName": clientName,
            "reviewLink": reviewLink,
            "platform": reviewPlatform.rawValue
        ]

        return createMessageFromTemplate(
            template,
            clientId: clientId,
            clientName: clientName,
            recipientContact: recipientContact,
            variables: variables
        )
    }

    private func getReviewLink(for platform: ReviewPlatform) -> String {
        // In production, use actual business review page URLs
        switch platform {
        case .google:
            return "https://g.page/r/YOUR_BUSINESS_ID/review"
        case .yelp:
            return "https://www.yelp.com/biz/YOUR_BUSINESS_ID"
        case .facebook:
            return "https://www.facebook.com/YOUR_PAGE/reviews"
        case .custom:
            return "https://yourwebsite.com/review"
        }
    }

    // MARK: - Campaign Support

    /// Create messages for a marketing campaign
    func createCampaignMessages(
        campaign: MarketingCampaign,
        recipients: [(clientId: UUID, name: String, contact: String)]
    ) -> [CommunicationMessage] {
        recipients.map { recipient in
            CommunicationMessage(
                clientId: recipient.clientId,
                clientName: recipient.name,
                recipientContact: recipient.contact,
                messageType: .promotional,
                channel: campaign.channel,
                subject: campaign.subject,
                content: campaign.content,
                campaignId: campaign.id
            )
        }
    }

    // MARK: - Default Templates

    private func initializeDefaultTemplates() {
        if messageTemplates.isEmpty {
            messageTemplates = [
                defaultAppointmentReminderTemplate(for: .sms),
                defaultAppointmentConfirmationTemplate(for: .email),
                defaultFollowUpTemplate(for: .email),
                defaultReviewRequestTemplate(for: .email),
                defaultBirthdayGreetingTemplate(for: .email)
            ]
            saveTemplates()
        }
    }

    private func defaultAppointmentReminderTemplate(for channel: CommunicationChannel) -> MessageTemplate {
        let content: String
        if channel == .sms {
            content = "Hi {{firstName}}! Reminder: You have a massage appointment tomorrow at {{time}} with {{therapist}}. Reply C to confirm or call us to reschedule."
        } else {
            content = """
            Hi {{clientName}},

            This is a friendly reminder that you have an appointment scheduled:

            Date: {{date}}
            Time: {{time}}
            Therapist: {{therapist}}

            Please arrive 10 minutes early. If you need to reschedule, please call us at least 24 hours in advance.

            Looking forward to seeing you!
            """
        }

        return MessageTemplate(
            name: "Appointment Reminder",
            messageType: .appointmentReminder,
            channel: channel,
            subject: channel == .email ? "Appointment Reminder - {{date}}" : nil,
            content: content
        )
    }

    private func defaultAppointmentConfirmationTemplate(for channel: CommunicationChannel) -> MessageTemplate {
        MessageTemplate(
            name: "Appointment Confirmation",
            messageType: .appointmentConfirmation,
            channel: channel,
            subject: "Appointment Confirmed",
            content: """
            Hi {{clientName}},

            Your massage appointment has been confirmed!

            Date: {{date}}
            Time: {{time}}

            We look forward to seeing you. If you have any questions, please don't hesitate to contact us.

            Thank you!
            """
        )
    }

    private func defaultFollowUpTemplate(for channel: CommunicationChannel) -> MessageTemplate {
        MessageTemplate(
            name: "Follow-Up",
            messageType: .followUp,
            channel: channel,
            subject: "How are you feeling?",
            content: """
            Hi {{clientName}},

            We hope you're feeling great after your recent massage session! We wanted to check in and see how you're doing.

            If you have any questions or concerns, or if you'd like to schedule your next appointment, please let us know.

            We look forward to seeing you again soon!
            """
        )
    }

    private func defaultReviewRequestTemplate(for channel: CommunicationChannel) -> MessageTemplate {
        MessageTemplate(
            name: "Review Request",
            messageType: .reviewRequest,
            channel: channel,
            subject: "We'd love your feedback!",
            content: """
            Hi {{clientName}},

            Thank you for choosing us for your massage therapy needs! We hope you had a wonderful experience.

            If you enjoyed your visit, we would greatly appreciate it if you could take a moment to leave us a review on {{platform}}:

            {{reviewLink}}

            Your feedback helps us serve you better and helps others discover our services.

            Thank you for your support!
            """
        )
    }

    private func defaultBirthdayGreetingTemplate(for channel: CommunicationChannel) -> MessageTemplate {
        MessageTemplate(
            name: "Birthday Greeting",
            messageType: .birthdayGreeting,
            channel: channel,
            subject: "Happy Birthday! 🎉",
            content: """
            Happy Birthday, {{clientName}}! 🎉

            We hope you have a wonderful day filled with joy and celebration!

            As a birthday gift from us, enjoy 15% off your next massage session when you book within the next 30 days.

            Treat yourself - you deserve it!

            Warm wishes,
            Your Massage Therapy Team
            """
        )
    }

    // MARK: - Validation

    func validatePhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression))
    }

    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func validateRecipient(_ contact: String, for channel: CommunicationChannel) -> Bool {
        switch channel {
        case .sms, .push:
            return validatePhoneNumber(contact)
        case .email:
            return validateEmail(contact)
        case .inApp:
            return true // In-app messages use user ID
        }
    }

    // MARK: - Persistence

    private func loadConfigurations() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode([CommunicationChannel: CommunicationServiceConfig].self, from: data) {
            serviceConfigs = decoded
            updateConfigurationStatus()
        }
    }

    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(serviceConfigs) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        }
    }

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: templatesKey),
           let decoded = try? JSONDecoder().decode([MessageTemplate].self, from: data) {
            messageTemplates = decoded
        }
    }

    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(messageTemplates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
}

// MARK: - Error Types

enum CommunicationError: LocalizedError {
    case channelNotConfigured
    case invalidRecipient
    case sendFailed(String)
    case rateLimitExceeded
    case templateNotFound
    case invalidTemplate

    var errorDescription: String? {
        switch self {
        case .channelNotConfigured:
            return "Communication channel is not configured"
        case .invalidRecipient:
            return "Invalid recipient contact information"
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .templateNotFound:
            return "Message template not found"
        case .invalidTemplate:
            return "Invalid template format"
        }
    }
}

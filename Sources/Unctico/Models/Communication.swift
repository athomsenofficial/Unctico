import Foundation
import SwiftUI

/// Communication message model for SMS and Email
struct CommunicationMessage: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let messageType: MessageType
    let channel: CommunicationChannel
    let subject: String?
    let body: String
    let scheduledDate: Date
    let sentDate: Date?
    let status: MessageStatus
    let campaignId: UUID?
    let appointmentId: UUID?
    let metadata: [String: String]
    let recipientEmail: String?
    let recipientPhone: String?
    let openedDate: Date?
    let clickedDate: Date?
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        messageType: MessageType,
        channel: CommunicationChannel,
        subject: String? = nil,
        body: String,
        scheduledDate: Date = Date(),
        sentDate: Date? = nil,
        status: MessageStatus = .scheduled,
        campaignId: UUID? = nil,
        appointmentId: UUID? = nil,
        metadata: [String: String] = [:],
        recipientEmail: String? = nil,
        recipientPhone: String? = nil,
        openedDate: Date? = nil,
        clickedDate: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.messageType = messageType
        self.channel = channel
        self.subject = subject
        self.body = body
        self.scheduledDate = scheduledDate
        self.sentDate = sentDate
        self.status = status
        self.campaignId = campaignId
        self.appointmentId = appointmentId
        self.metadata = metadata
        self.recipientEmail = recipientEmail
        self.recipientPhone = recipientPhone
        self.openedDate = openedDate
        self.clickedDate = clickedDate
        self.errorMessage = errorMessage
    }

    var wasOpened: Bool {
        openedDate != nil
    }

    var wasClicked: Bool {
        clickedDate != nil
    }

    var openRate: Bool {
        wasOpened
    }
}

enum MessageType: String, Codable, CaseIterable {
    case appointmentReminder = "Appointment Reminder"
    case appointmentConfirmation = "Appointment Confirmation"
    case appointmentCancellation = "Appointment Cancellation"
    case followUp = "Follow-up"
    case birthdayGreeting = "Birthday Greeting"
    case reviewRequest = "Review Request"
    case promotional = "Promotional"
    case newsletter = "Newsletter"
    case welcomeSeries = "Welcome Series"
    case reEngagement = "Re-engagement"
    case thankYou = "Thank You"
    case paymentReminder = "Payment Reminder"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .appointmentReminder: return "clock.fill"
        case .appointmentConfirmation: return "checkmark.circle.fill"
        case .appointmentCancellation: return "xmark.circle.fill"
        case .followUp: return "arrow.right.circle.fill"
        case .birthdayGreeting: return "gift.fill"
        case .reviewRequest: return "star.fill"
        case .promotional: return "megaphone.fill"
        case .newsletter: return "newspaper.fill"
        case .welcomeSeries: return "hand.wave.fill"
        case .reEngagement: return "arrow.clockwise.circle.fill"
        case .thankYou: return "heart.fill"
        case .paymentReminder: return "dollarsign.circle.fill"
        case .custom: return "envelope.fill"
        }
    }

    var color: Color {
        switch self {
        case .appointmentReminder: return .orange
        case .appointmentConfirmation: return .green
        case .appointmentCancellation: return .red
        case .followUp: return .blue
        case .birthdayGreeting: return .pink
        case .reviewRequest: return .yellow
        case .promotional: return .purple
        case .newsletter: return .cyan
        case .welcomeSeries: return .mint
        case .reEngagement: return .indigo
        case .thankYou: return .teal
        case .paymentReminder: return .orange
        case .custom: return .gray
        }
    }
}

enum CommunicationChannel: String, Codable, CaseIterable {
    case email = "Email"
    case sms = "SMS"
    case push = "Push Notification"
    case inApp = "In-App Message"

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .push: return "bell.fill"
        case .inApp: return "app.badge.fill"
        }
    }

    var color: Color {
        switch self {
        case .email: return .blue
        case .sms: return .green
        case .push: return .orange
        case .inApp: return .purple
        }
    }
}

enum MessageStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case sending = "Sending"
    case sent = "Sent"
    case delivered = "Delivered"
    case opened = "Opened"
    case clicked = "Clicked"
    case failed = "Failed"
    case bounced = "Bounced"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .scheduled: return .blue
        case .sending: return .orange
        case .sent, .delivered: return .green
        case .opened, .clicked: return .cyan
        case .failed, .bounced: return .red
        case .cancelled: return .purple
        }
    }
}

/// Marketing campaign
struct MarketingCampaign: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let campaignType: CampaignType
    let channel: CommunicationChannel
    let subject: String?
    let body: String
    let targetAudience: TargetAudience
    let scheduledDate: Date?
    let startDate: Date?
    let endDate: Date?
    let status: CampaignStatus
    let createdDate: Date
    let totalRecipients: Int
    let sentCount: Int
    let openedCount: Int
    let clickedCount: Int
    let unsubscribedCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        campaignType: CampaignType,
        channel: CommunicationChannel,
        subject: String? = nil,
        body: String,
        targetAudience: TargetAudience,
        scheduledDate: Date? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: CampaignStatus = .draft,
        createdDate: Date = Date(),
        totalRecipients: Int = 0,
        sentCount: Int = 0,
        openedCount: Int = 0,
        clickedCount: Int = 0,
        unsubscribedCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.campaignType = campaignType
        self.channel = channel
        self.subject = subject
        self.body = body
        self.targetAudience = targetAudience
        self.scheduledDate = scheduledDate
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.createdDate = createdDate
        self.totalRecipients = totalRecipients
        self.sentCount = sentCount
        self.openedCount = openedCount
        self.clickedCount = clickedCount
        self.unsubscribedCount = unsubscribedCount
    }

    var openRate: Double {
        guard sentCount > 0 else { return 0 }
        return Double(openedCount) / Double(sentCount) * 100
    }

    var clickRate: Double {
        guard sentCount > 0 else { return 0 }
        return Double(clickedCount) / Double(sentCount) * 100
    }

    var unsubscribeRate: Double {
        guard sentCount > 0 else { return 0 }
        return Double(unsubscribedCount) / Double(sentCount) * 100
    }
}

enum CampaignType: String, Codable, CaseIterable {
    case promotional = "Promotional"
    case educational = "Educational"
    case seasonal = "Seasonal"
    case reEngagement = "Re-engagement"
    case referral = "Referral Program"
    case announcement = "Announcement"
    case survey = "Survey"
    case eventInvitation = "Event Invitation"

    var icon: String {
        switch self {
        case .promotional: return "megaphone.fill"
        case .educational: return "book.fill"
        case .seasonal: return "snowflake"
        case .reEngagement: return "arrow.clockwise.circle.fill"
        case .referral: return "person.2.fill"
        case .announcement: return "bell.fill"
        case .survey: return "list.clipboard.fill"
        case .eventInvitation: return "calendar.badge.plus"
        }
    }
}

enum CampaignStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .scheduled: return .blue
        case .active: return .green
        case .paused: return .orange
        case .completed: return .purple
        case .cancelled: return .red
        }
    }
}

struct TargetAudience: Codable {
    let segmentType: AudienceSegment
    let filters: [AudienceFilter]
    let includeClientIds: [UUID]
    let excludeClientIds: [UUID]

    init(
        segmentType: AudienceSegment = .all,
        filters: [AudienceFilter] = [],
        includeClientIds: [UUID] = [],
        excludeClientIds: [UUID] = []
    ) {
        self.segmentType = segmentType
        self.filters = filters
        self.includeClientIds = includeClientIds
        self.excludeClientIds = excludeClientIds
    }
}

enum AudienceSegment: String, Codable, CaseIterable {
    case all = "All Clients"
    case active = "Active Clients"
    case inactive = "Inactive Clients"
    case newClients = "New Clients"
    case vipClients = "VIP Clients"
    case birthdayThisMonth = "Birthday This Month"
    case custom = "Custom"
}

struct AudienceFilter: Codable {
    let filterType: FilterType
    let value: String

    enum FilterType: String, Codable {
        case lastVisit = "Last Visit"
        case totalVisits = "Total Visits"
        case totalSpent = "Total Spent"
        case hasUpcomingAppt = "Has Upcoming Appointment"
        case preferredService = "Preferred Service"
    }
}

/// Automated message template
struct MessageTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let messageType: MessageType
    let channel: CommunicationChannel
    let subject: String?
    let body: String
    let variables: [TemplateVariable]
    let isActive: Bool
    let createdDate: Date
    let lastModifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        messageType: MessageType,
        channel: CommunicationChannel,
        subject: String? = nil,
        body: String,
        variables: [TemplateVariable] = [],
        isActive: Bool = true,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.messageType = messageType
        self.channel = channel
        self.subject = subject
        self.body = body
        self.variables = variables
        self.isActive = isActive
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }

    func renderBody(with values: [String: String]) -> String {
        var rendered = body
        for (key, value) in values {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }
}

struct TemplateVariable: Codable {
    let name: String
    let placeholder: String
    let description: String

    init(name: String, placeholder: String = "", description: String = "") {
        self.name = name
        self.placeholder = placeholder
        self.description = description
    }
}

/// Automated workflow/sequence
struct AutomatedWorkflow: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let trigger: WorkflowTrigger
    let actions: [WorkflowAction]
    let isActive: Bool
    let createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        trigger: WorkflowTrigger,
        actions: [WorkflowAction] = [],
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.actions = actions
        self.isActive = isActive
        self.createdDate = createdDate
    }
}

enum WorkflowTrigger: Codable {
    case appointmentBooked
    case appointmentCompleted
    case clientBirthday
    case clientInactive(days: Int)
    case firstVisit
    case specificDate(date: Date)
    case afterLastVisit(days: Int)

    var description: String {
        switch self {
        case .appointmentBooked: return "Appointment Booked"
        case .appointmentCompleted: return "Appointment Completed"
        case .clientBirthday: return "Client Birthday"
        case .clientInactive(let days): return "Client Inactive (\(days) days)"
        case .firstVisit: return "First Visit"
        case .specificDate: return "Specific Date"
        case .afterLastVisit(let days): return "\(days) Days After Last Visit"
        }
    }
}

struct WorkflowAction: Identifiable, Codable {
    let id: UUID
    let delay: TimeInterval // in seconds
    let messageTemplate: UUID
    let channel: CommunicationChannel

    init(id: UUID = UUID(), delay: TimeInterval, messageTemplate: UUID, channel: CommunicationChannel) {
        self.id = id
        self.delay = delay
        self.messageTemplate = messageTemplate
        self.channel = channel
    }

    var delayDescription: String {
        let hours = Int(delay / 3600)
        let days = hours / 24

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "Immediately"
        }
    }
}

/// Review request
struct ReviewRequest: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let appointmentId: UUID
    let requestDate: Date
    let reminderDate: Date?
    let reviewedDate: Date?
    let rating: Int?
    let reviewText: String?
    let platform: ReviewPlatform
    let status: ReviewRequestStatus

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        appointmentId: UUID,
        requestDate: Date = Date(),
        reminderDate: Date? = nil,
        reviewedDate: Date? = nil,
        rating: Int? = nil,
        reviewText: String? = nil,
        platform: ReviewPlatform = .google,
        status: ReviewRequestStatus = .sent
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.appointmentId = appointmentId
        self.requestDate = requestDate
        self.reminderDate = reminderDate
        self.reviewedDate = reviewedDate
        self.rating = rating
        self.reviewText = reviewText
        self.platform = platform
        self.status = status
    }
}

enum ReviewPlatform: String, Codable, CaseIterable {
    case google = "Google"
    case yelp = "Yelp"
    case facebook = "Facebook"
    case internal = "Internal"

    var icon: String {
        switch self {
        case .google: return "magnifyingglass"
        case .yelp: return "y.circle.fill"
        case .facebook: return "f.circle.fill"
        case .internal: return "star.fill"
        }
    }
}

enum ReviewRequestStatus: String, Codable {
    case sent = "Sent"
    case reminded = "Reminded"
    case reviewed = "Reviewed"
    case declined = "Declined"
    case expired = "Expired"

    var color: Color {
        switch self {
        case .sent: return .blue
        case .reminded: return .orange
        case .reviewed: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
}

/// Communication preferences per client
struct ClientCommunicationPreferences: Codable {
    let clientId: UUID
    var emailEnabled: Bool
    var smsEnabled: Bool
    var pushEnabled: Bool
    var appointmentReminders: Bool
    var promotionalMessages: Bool
    var newsletters: Bool
    var reviewRequests: Bool
    var preferredChannel: CommunicationChannel
    var preferredTime: PreferredTime
    var unsubscribedDate: Date?

    init(
        clientId: UUID,
        emailEnabled: Bool = true,
        smsEnabled: Bool = true,
        pushEnabled: Bool = true,
        appointmentReminders: Bool = true,
        promotionalMessages: Bool = true,
        newsletters: Bool = true,
        reviewRequests: Bool = true,
        preferredChannel: CommunicationChannel = .email,
        preferredTime: PreferredTime = .anytime,
        unsubscribedDate: Date? = nil
    ) {
        self.clientId = clientId
        self.emailEnabled = emailEnabled
        self.smsEnabled = smsEnabled
        self.pushEnabled = pushEnabled
        self.appointmentReminders = appointmentReminders
        self.promotionalMessages = promotionalMessages
        self.newsletters = newsletters
        self.reviewRequests = reviewRequests
        self.preferredChannel = preferredChannel
        self.preferredTime = preferredTime
        self.unsubscribedDate = unsubscribedDate
    }

    var isOptedIn: Bool {
        unsubscribedDate == nil && (emailEnabled || smsEnabled || pushEnabled)
    }
}

enum PreferredTime: String, Codable, CaseIterable {
    case morning = "Morning (8am-12pm)"
    case afternoon = "Afternoon (12pm-5pm)"
    case evening = "Evening (5pm-9pm)"
    case anytime = "Anytime"
}

/// Email/SMS service provider configuration
struct CommunicationServiceConfig: Codable {
    let provider: CommunicationProvider
    let isEnabled: Bool
    let apiKey: String
    let senderEmail: String?
    let senderPhone: String?
    let replyToEmail: String?
    let testMode: Bool

    init(
        provider: CommunicationProvider,
        isEnabled: Bool = false,
        apiKey: String = "",
        senderEmail: String? = nil,
        senderPhone: String? = nil,
        replyToEmail: String? = nil,
        testMode: Bool = true
    ) {
        self.provider = provider
        self.isEnabled = isEnabled
        self.apiKey = apiKey
        self.senderEmail = senderEmail
        self.senderPhone = senderPhone
        self.replyToEmail = replyToEmail
        self.testMode = testMode
    }
}

enum CommunicationProvider: String, Codable, CaseIterable {
    case twilio = "Twilio (SMS)"
    case sendgrid = "SendGrid (Email)"
    case mailgun = "Mailgun (Email)"
    case amazonSES = "Amazon SES (Email)"
    case manual = "Manual"

    var supportsEmail: Bool {
        switch self {
        case .sendgrid, .mailgun, .amazonSES: return true
        default: return false
        }
    }

    var supportsSMS: Bool {
        self == .twilio
    }
}

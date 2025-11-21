import Foundation

/// Marketing automation and campaign management models

// MARK: - Email Campaign

struct EmailCampaign: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var campaignType: CampaignType
    var status: CampaignStatus
    var template: EmailTemplate
    var audience: CampaignAudience
    var schedule: CampaignSchedule
    var createdDate: Date
    var lastModifiedDate: Date
    var sentDate: Date?
    var completedDate: Date?
    var metrics: CampaignMetrics?
    var abTest: ABTest?
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        campaignType: CampaignType,
        status: CampaignStatus = .draft,
        template: EmailTemplate,
        audience: CampaignAudience,
        schedule: CampaignSchedule = .manual,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date(),
        sentDate: Date? = nil,
        completedDate: Date? = nil,
        metrics: CampaignMetrics? = nil,
        abTest: ABTest? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.campaignType = campaignType
        self.status = status
        self.template = template
        self.audience = audience
        self.schedule = schedule
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.sentDate = sentDate
        self.completedDate = completedDate
        self.metrics = metrics
        self.abTest = abTest
        self.tags = tags
    }

    var isDraft: Bool {
        status == .draft
    }

    var isActive: Bool {
        status == .active || status == .scheduled
    }
}

enum CampaignType: String, Codable, CaseIterable {
    case oneTime = "One-Time"
    case recurring = "Recurring"
    case triggered = "Triggered"
    case drip = "Drip Campaign"

    var icon: String {
        switch self {
        case .oneTime: return "envelope.fill"
        case .recurring: return "arrow.clockwise"
        case .triggered: return "bolt.fill"
        case .drip: return "drop.fill"
        }
    }
}

enum CampaignStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case archived = "Archived"

    var color: String {
        switch self {
        case .draft: return "gray"
        case .scheduled: return "orange"
        case .active: return "green"
        case .paused: return "yellow"
        case .completed: return "blue"
        case .archived: return "gray"
        }
    }
}

// MARK: - Email Template

struct EmailTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var subject: String
    var previewText: String
    var body: String // HTML or plain text
    var placeholders: [String] // e.g., "{{client_name}}", "{{appointment_date}}"
    var category: TemplateCategory
    var isDefault: Bool
    var createdDate: Date
    var lastModifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        subject: String,
        previewText: String = "",
        body: String,
        placeholders: [String] = [],
        category: TemplateCategory,
        isDefault: Bool = false,
        createdDate: Date = Date(),
        lastModifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.previewText = previewText
        self.body = body
        self.placeholders = placeholders
        self.category = category
        self.isDefault = isDefault
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
    }

    func renderWithData(_ data: [String: String]) -> RenderedEmail {
        var renderedSubject = subject
        var renderedBody = body

        for (placeholder, value) in data {
            renderedSubject = renderedSubject.replacingOccurrences(of: "{{\(placeholder)}}", with: value)
            renderedBody = renderedBody.replacingOccurrences(of: "{{\(placeholder)}}", with: value)
        }

        return RenderedEmail(
            subject: renderedSubject,
            body: renderedBody,
            previewText: previewText
        )
    }
}

enum TemplateCategory: String, Codable, CaseIterable {
    case welcome = "Welcome"
    case appointment = "Appointment"
    case reminder = "Reminder"
    case followUp = "Follow-Up"
    case birthday = "Birthday"
    case promotion = "Promotion"
    case newsletter = "Newsletter"
    case reEngagement = "Re-Engagement"
    case thankyou = "Thank You"
    case review = "Review Request"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .appointment: return "calendar.badge.checkmark"
        case .reminder: return "bell.fill"
        case .followUp: return "arrow.turn.up.right"
        case .birthday: return "gift.fill"
        case .promotion: return "tag.fill"
        case .newsletter: return "newspaper.fill"
        case .reEngagement: return "arrow.clockwise"
        case .thankyou: return "heart.fill"
        case .review: return "star.fill"
        case .custom: return "doc.text.fill"
        }
    }
}

struct RenderedEmail {
    let subject: String
    let body: String
    let previewText: String
}

// MARK: - Campaign Audience

struct CampaignAudience: Codable {
    var targetType: TargetType
    var filters: [AudienceFilter]
    var excludeFilters: [AudienceFilter]
    var estimatedRecipients: Int

    init(
        targetType: TargetType = .allClients,
        filters: [AudienceFilter] = [],
        excludeFilters: [AudienceFilter] = [],
        estimatedRecipients: Int = 0
    ) {
        self.targetType = targetType
        self.filters = filters
        self.excludeFilters = excludeFilters
        self.estimatedRecipients = estimatedRecipients
    }
}

enum TargetType: String, Codable {
    case allClients = "All Clients"
    case activeClients = "Active Clients"
    case newClients = "New Clients"
    case dormantClients = "Dormant Clients"
    case vipClients = "VIP Clients"
    case custom = "Custom Filter"
}

struct AudienceFilter: Codable, Identifiable {
    let id: UUID
    var filterType: FilterType
    var condition: FilterCondition
    var value: String

    init(
        id: UUID = UUID(),
        filterType: FilterType,
        condition: FilterCondition,
        value: String
    ) {
        self.id = id
        self.filterType = filterType
        self.condition = condition
        self.value = value
    }
}

enum FilterType: String, Codable, CaseIterable {
    case lastVisit = "Last Visit"
    case totalVisits = "Total Visits"
    case totalSpent = "Total Spent"
    case averageSpent = "Average Spent"
    case hasEmail = "Has Email"
    case hasPhone = "Has Phone"
    case birthday = "Birthday"
    case tags = "Tags"
}

enum FilterCondition: String, Codable {
    case equals = "Equals"
    case notEquals = "Not Equals"
    case greaterThan = "Greater Than"
    case lessThan = "Less Than"
    case contains = "Contains"
    case notContains = "Not Contains"
    case inLast = "In Last"
    case notInLast = "Not In Last"
}

// MARK: - Campaign Schedule

enum CampaignSchedule: Codable {
    case manual
    case scheduled(Date)
    case recurring(RecurringSchedule)
    case triggered(TriggerEvent)

    var description: String {
        switch self {
        case .manual:
            return "Manual Send"
        case .scheduled(let date):
            return "Scheduled for \(date.formatted(date: .abbreviated, time: .shortened))"
        case .recurring(let schedule):
            return "Recurring: \(schedule.frequency.rawValue)"
        case .triggered(let event):
            return "Triggered by: \(event.rawValue)"
        }
    }
}

struct RecurringSchedule: Codable {
    var frequency: RecurringFrequency
    var startDate: Date
    var endDate: Date?
    var daysOfWeek: [Int]? // 0 = Sunday, 6 = Saturday
    var timeOfDay: Date // Time component only

    init(
        frequency: RecurringFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        daysOfWeek: [Int]? = nil,
        timeOfDay: Date = Date()
    ) {
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.daysOfWeek = daysOfWeek
        self.timeOfDay = timeOfDay
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
}

enum TriggerEvent: String, Codable, CaseIterable {
    case newClient = "New Client Sign-Up"
    case firstAppointment = "First Appointment"
    case appointmentBooked = "Appointment Booked"
    case appointmentCompleted = "Appointment Completed"
    case birthday = "Client Birthday"
    case anniversary = "Client Anniversary"
    case inactivity30Days = "30 Days of Inactivity"
    case inactivity60Days = "60 Days of Inactivity"
    case inactivity90Days = "90 Days of Inactivity"

    var delayDays: Int {
        switch self {
        case .newClient, .firstAppointment, .appointmentBooked, .birthday, .anniversary:
            return 0
        case .appointmentCompleted:
            return 1
        case .inactivity30Days:
            return 30
        case .inactivity60Days:
            return 60
        case .inactivity90Days:
            return 90
        }
    }
}

// MARK: - Campaign Metrics

struct CampaignMetrics: Codable {
    var totalSent: Int
    var totalDelivered: Int
    var totalOpened: Int
    var totalClicked: Int
    var totalBounced: Int
    var totalUnsubscribed: Int
    var totalConverted: Int // Booked appointment, made purchase, etc.
    var revenue: Double

    init(
        totalSent: Int = 0,
        totalDelivered: Int = 0,
        totalOpened: Int = 0,
        totalClicked: Int = 0,
        totalBounced: Int = 0,
        totalUnsubscribed: Int = 0,
        totalConverted: Int = 0,
        revenue: Double = 0
    ) {
        self.totalSent = totalSent
        self.totalDelivered = totalDelivered
        self.totalOpened = totalOpened
        self.totalClicked = totalClicked
        self.totalBounced = totalBounced
        self.totalUnsubscribed = totalUnsubscribed
        self.totalConverted = totalConverted
        self.revenue = revenue
    }

    var deliveryRate: Double {
        guard totalSent > 0 else { return 0 }
        return Double(totalDelivered) / Double(totalSent) * 100
    }

    var openRate: Double {
        guard totalDelivered > 0 else { return 0 }
        return Double(totalOpened) / Double(totalDelivered) * 100
    }

    var clickRate: Double {
        guard totalDelivered > 0 else { return 0 }
        return Double(totalClicked) / Double(totalDelivered) * 100
    }

    var clickToOpenRate: Double {
        guard totalOpened > 0 else { return 0 }
        return Double(totalClicked) / Double(totalOpened) * 100
    }

    var conversionRate: Double {
        guard totalDelivered > 0 else { return 0 }
        return Double(totalConverted) / Double(totalDelivered) * 100
    }

    var bounceRate: Double {
        guard totalSent > 0 else { return 0 }
        return Double(totalBounced) / Double(totalSent) * 100
    }

    var unsubscribeRate: Double {
        guard totalDelivered > 0 else { return 0 }
        return Double(totalUnsubscribed) / Double(totalDelivered) * 100
    }

    var revenuePerRecipient: Double {
        guard totalDelivered > 0 else { return 0 }
        return revenue / Double(totalDelivered)
    }
}

// MARK: - A/B Testing

struct ABTest: Identifiable, Codable {
    let id: UUID
    var name: String
    var testType: ABTestType
    var variantA: EmailTemplate
    var variantB: EmailTemplate
    var splitPercentage: Double // 0-100, percentage for variant A
    var winnerCriteria: WinnerCriteria
    var duration: TimeInterval // Test duration in seconds
    var startDate: Date?
    var endDate: Date?
    var metricsA: CampaignMetrics
    var metricsB: CampaignMetrics
    var winner: TestVariant?

    init(
        id: UUID = UUID(),
        name: String,
        testType: ABTestType,
        variantA: EmailTemplate,
        variantB: EmailTemplate,
        splitPercentage: Double = 50,
        winnerCriteria: WinnerCriteria = .openRate,
        duration: TimeInterval = 86400, // 24 hours
        startDate: Date? = nil,
        endDate: Date? = nil,
        metricsA: CampaignMetrics = CampaignMetrics(),
        metricsB: CampaignMetrics = CampaignMetrics(),
        winner: TestVariant? = nil
    ) {
        self.id = id
        self.name = name
        self.testType = testType
        self.variantA = variantA
        self.variantB = variantB
        self.splitPercentage = splitPercentage
        self.winnerCriteria = winnerCriteria
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.metricsA = metricsA
        self.metricsB = metricsB
        self.winner = winner
    }

    var isComplete: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }
}

enum ABTestType: String, Codable {
    case subjectLine = "Subject Line"
    case emailContent = "Email Content"
    case sendTime = "Send Time"
    case sender = "Sender Name"
}

enum WinnerCriteria: String, Codable, CaseIterable {
    case openRate = "Open Rate"
    case clickRate = "Click Rate"
    case conversionRate = "Conversion Rate"
    case revenue = "Revenue"
}

enum TestVariant: String, Codable {
    case variantA = "Variant A"
    case variantB = "Variant B"
}

// MARK: - Email Log

struct EmailLog: Identifiable, Codable {
    let id: UUID
    let campaignId: UUID?
    let campaignName: String?
    let clientId: UUID
    let clientEmail: String
    let subject: String
    var status: EmailStatus
    var sentDate: Date
    var deliveredDate: Date?
    var openedDate: Date?
    var clickedDate: Date?
    var bouncedDate: Date?
    var unsubscribedDate: Date?
    var errorMessage: String?
    var variant: TestVariant?

    init(
        id: UUID = UUID(),
        campaignId: UUID? = nil,
        campaignName: String? = nil,
        clientId: UUID,
        clientEmail: String,
        subject: String,
        status: EmailStatus = .sent,
        sentDate: Date = Date(),
        deliveredDate: Date? = nil,
        openedDate: Date? = nil,
        clickedDate: Date? = nil,
        bouncedDate: Date? = nil,
        unsubscribedDate: Date? = nil,
        errorMessage: String? = nil,
        variant: TestVariant? = nil
    ) {
        self.id = id
        self.campaignId = campaignId
        self.campaignName = campaignName
        self.clientId = clientId
        self.clientEmail = clientEmail
        self.subject = subject
        self.status = status
        self.sentDate = sentDate
        self.deliveredDate = deliveredDate
        self.openedDate = openedDate
        self.clickedDate = clickedDate
        self.bouncedDate = bouncedDate
        self.unsubscribedDate = unsubscribedDate
        self.errorMessage = errorMessage
        self.variant = variant
    }
}

enum EmailStatus: String, Codable {
    case queued = "Queued"
    case sent = "Sent"
    case delivered = "Delivered"
    case opened = "Opened"
    case clicked = "Clicked"
    case bounced = "Bounced"
    case failed = "Failed"
    case unsubscribed = "Unsubscribed"

    var color: String {
        switch self {
        case .queued: return "gray"
        case .sent: return "blue"
        case .delivered: return "green"
        case .opened: return "teal"
        case .clicked: return "purple"
        case .bounced: return "orange"
        case .failed: return "red"
        case .unsubscribed: return "red"
        }
    }
}

// MARK: - Automation Rule

struct AutomationRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var trigger: TriggerEvent
    var template: EmailTemplate
    var isActive: Bool
    var delayMinutes: Int // Delay after trigger event
    var conditions: [AutomationCondition]
    var createdDate: Date
    var lastTriggeredDate: Date?
    var totalTriggered: Int

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        trigger: TriggerEvent,
        template: EmailTemplate,
        isActive: Bool = true,
        delayMinutes: Int = 0,
        conditions: [AutomationCondition] = [],
        createdDate: Date = Date(),
        lastTriggeredDate: Date? = nil,
        totalTriggered: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.template = template
        self.isActive = isActive
        self.delayMinutes = delayMinutes
        self.conditions = conditions
        self.createdDate = createdDate
        self.lastTriggeredDate = lastTriggeredDate
        self.totalTriggered = totalTriggered
    }
}

struct AutomationCondition: Codable, Identifiable {
    let id: UUID
    var conditionType: ConditionType
    var operator_: ConditionOperator
    var value: String

    init(
        id: UUID = UUID(),
        conditionType: ConditionType,
        operator_: ConditionOperator,
        value: String
    ) {
        self.id = id
        self.conditionType = conditionType
        self.operator_ = operator_
        self.value = value
    }
}

enum ConditionType: String, Codable {
    case hasEmail = "Has Email"
    case totalVisits = "Total Visits"
    case lastVisit = "Last Visit"
    case clientTag = "Client Tag"
    case emailOptIn = "Email Opt-In"
}

enum ConditionOperator: String, Codable {
    case equals = "Equals"
    case notEquals = "Not Equals"
    case greaterThan = "Greater Than"
    case lessThan = "Less Than"
    case contains = "Contains"
}

// MARK: - Marketing Statistics

struct MarketingStatistics {
    let totalCampaigns: Int
    let activeCampaigns: Int
    let totalEmailsSent: Int
    let averageOpenRate: Double
    let averageClickRate: Double
    let averageConversionRate: Double
    let totalRevenue: Double
    let roi: Double // Return on Investment

    init(
        totalCampaigns: Int = 0,
        activeCampaigns: Int = 0,
        totalEmailsSent: Int = 0,
        averageOpenRate: Double = 0,
        averageClickRate: Double = 0,
        averageConversionRate: Double = 0,
        totalRevenue: Double = 0,
        roi: Double = 0
    ) {
        self.totalCampaigns = totalCampaigns
        self.activeCampaigns = activeCampaigns
        self.totalEmailsSent = totalEmailsSent
        self.averageOpenRate = averageOpenRate
        self.averageClickRate = averageClickRate
        self.averageConversionRate = averageConversionRate
        self.totalRevenue = totalRevenue
        self.roi = roi
    }
}

import Foundation

class MarketingAutomationService: ObservableObject {
    static let shared = MarketingAutomationService()

    @Published var campaigns: [MarketingCampaign] = []
    @Published var automations: [Automation] = []

    private init() {}

    // MARK: - Campaign Management

    func createCampaign(
        name: String,
        type: CampaignType,
        targetAudience: TargetAudience,
        message: String,
        scheduledDate: Date?
    ) -> MarketingCampaign {
        return MarketingCampaign(
            name: name,
            type: type,
            targetAudience: targetAudience,
            message: message,
            scheduledDate: scheduledDate
        )
    }

    func sendCampaign(_ campaign: MarketingCampaign) {
        // Send to target audience
        let recipients = getTargetedClients(for: campaign.targetAudience)

        for clientId in recipients {
            if let client = ClientRepository.shared.getClient(by: clientId) {
                sendCampaignMessage(to: client, campaign: campaign)
            }
        }
    }

    // MARK: - Automated Workflows

    func setupAutomation(_ automation: Automation) {
        automations.append(automation)
    }

    func triggerAutomation(type: AutomationTrigger, context: [String: Any]) {
        let matchingAutomations = automations.filter { $0.trigger == type && $0.isActive }

        for automation in matchingAutomations {
            executeAutomationActions(automation, context: context)
        }
    }

    // MARK: - Review Request System

    func requestReview(for clientId: UUID, appointmentId: UUID) {
        guard let client = ClientRepository.shared.getClient(by: clientId) else { return }

        let message = """
        Hi \(client.firstName),

        Thank you for your recent visit! We'd love to hear about your experience.

        Please take a moment to leave us a review:
        ⭐ Google: [link]
        ⭐ Yelp: [link]

        Your feedback helps us serve you better!

        Best regards,
        Your Massage Therapy Team
        """

        if let email = client.email {
            CommunicationService.shared.sendEmail(
                to: email,
                subject: "How was your massage session?",
                body: message
            ) { _ in }
        }
    }

    // MARK: - Referral Program

    func createReferralLink(for clientId: UUID) -> String {
        // Generate unique referral code
        let referralCode = "REF-\(clientId.uuidString.prefix(8))"
        return "https://yourbusiness.com/book?ref=\(referralCode)"
    }

    func processReferral(referralCode: String, newClientId: UUID) -> ReferralReward {
        // Track referral and create rewards
        return ReferralReward(
            referrerId: extractClientId(from: referralCode),
            newClientId: newClientId,
            rewardType: .discount,
            rewardValue: 25.00,
            expirationDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
        )
    }

    // MARK: - Loyalty Program

    func calculateLoyaltyPoints(for clientId: UUID) -> Int {
        let appointments = AppointmentRepository.shared.getAppointments(for: clientId)
            .filter { $0.status == .completed }

        // 1 point per dollar spent
        let points = appointments.reduce(0) { total, appointment in
            let price = PaymentService.shared.getServicePrice(for: appointment.serviceType)
            return total + Int(price)
        }

        return points
    }

    func redeemReward(clientId: UUID, reward: LoyaltyReward) -> Bool {
        let currentPoints = calculateLoyaltyPoints(for: clientId)

        guard currentPoints >= reward.pointsCost else {
            return false
        }

        // Process reward redemption
        return true
    }

    // MARK: - Re-engagement Campaigns

    func identifyInactiveClients(monthsInactive: Int = 3) -> [UUID] {
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -monthsInactive, to: Date())!
        var inactiveClients: [UUID] = []

        for client in ClientRepository.shared.clients {
            let recentAppointments = AppointmentRepository.shared.getAppointments(for: client.id)
                .filter { $0.startTime >= cutoffDate }

            if recentAppointments.isEmpty {
                inactiveClients.append(client.id)
            }
        }

        return inactiveClients
    }

    func sendWinBackCampaign(to clientIds: [UUID]) {
        for clientId in clientIds {
            guard let client = ClientRepository.shared.getClient(by: clientId) else { continue }

            let message = """
            Hi \(client.firstName),

            We miss you! It's been a while since your last visit.

            Come back and enjoy 20% OFF your next massage session!

            Use code: COMEBACK20
            Valid for 30 days

            Book now and let us help you feel your best again!
            """

            if let email = client.email {
                CommunicationService.shared.sendEmail(
                    to: email,
                    subject: "We Miss You! Special 20% Off Offer",
                    body: message
                ) { _ in }
            }
        }
    }

    // MARK: - Birthday Campaigns

    func scheduleBirthdayCampaigns() {
        let calendar = Calendar.current
        let today = Date()

        for client in ClientRepository.shared.clients {
            guard let birthday = client.dateOfBirth else { continue }

            let clientBirthday = calendar.dateComponents([.month, .day], from: birthday)
            let todayComponents = calendar.dateComponents([.month, .day], from: today)

            if clientBirthday.month == todayComponents.month &&
               clientBirthday.day == todayComponents.day {
                sendBirthdayMessage(to: client)
            }
        }
    }

    private func sendBirthdayMessage(to client: Client) {
        let message = """
        Happy Birthday, \(client.firstName)! 🎉

        Celebrate your special day with a special gift:
        FREE upgrade to any premium massage service!

        Valid during your birthday month.

        Book your birthday massage today!
        """

        if let email = client.email {
            CommunicationService.shared.sendEmail(
                to: email,
                subject: "Happy Birthday! Your Special Gift Inside 🎁",
                body: message
            ) { _ in }
        }
    }

    // MARK: - Helper Methods

    private func getTargetedClients(for audience: TargetAudience) -> [UUID] {
        let allClients = ClientRepository.shared.clients

        switch audience {
        case .all:
            return allClients.map { $0.id }

        case .newClients:
            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            return allClients.filter { $0.createdAt >= threeMonthsAgo }.map { $0.id }

        case .vipClients:
            return allClients.filter { client in
                let ltv = AnalyticsService.shared.calculateClientLifetimeValue(for: client.id)
                return ltv.totalRevenue >= 1000
            }.map { $0.id }

        case .inactiveClients:
            return identifyInactiveClients(monthsInactive: 3)

        case .custom(let filter):
            return filter(allClients)
        }
    }

    private func sendCampaignMessage(to client: Client, campaign: MarketingCampaign) {
        switch campaign.type {
        case .email:
            if let email = client.email {
                CommunicationService.shared.sendEmail(
                    to: email,
                    subject: campaign.name,
                    body: campaign.message
                ) { _ in }
            }

        case .sms:
            if let phone = client.phone {
                CommunicationService.shared.sendSMS(
                    to: phone,
                    message: campaign.message
                ) { _ in }
            }

        case .push:
            // Send push notification
            break
        }
    }

    private func executeAutomationActions(_ automation: Automation, context: [String: Any]) {
        for action in automation.actions {
            switch action {
            case .sendEmail(let template):
                // Send templated email
                break
            case .sendSMS(let template):
                // Send templated SMS
                break
            case .addTag(let tag):
                // Add tag to client
                break
            case .updateStatus(let status):
                // Update client status
                break
            case .scheduleFollowUp(let days):
                // Schedule follow-up task
                break
            }
        }
    }

    private func extractClientId(from referralCode: String) -> UUID {
        // Extract UUID from referral code
        return UUID() // Placeholder
    }
}

// MARK: - Marketing Models

struct MarketingCampaign: Identifiable {
    let id: UUID
    var name: String
    var type: CampaignType
    var targetAudience: TargetAudience
    var message: String
    var scheduledDate: Date?
    var sentDate: Date?
    var status: CampaignStatus
    var metrics: CampaignMetrics
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: CampaignType,
        targetAudience: TargetAudience,
        message: String,
        scheduledDate: Date? = nil,
        sentDate: Date? = nil,
        status: CampaignStatus = .draft,
        metrics: CampaignMetrics = CampaignMetrics(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.targetAudience = targetAudience
        self.message = message
        self.scheduledDate = scheduledDate
        self.sentDate = sentDate
        self.status = status
        self.metrics = metrics
        self.createdAt = createdAt
    }
}

enum CampaignType: String, Codable, CaseIterable {
    case email = "Email"
    case sms = "SMS"
    case push = "Push Notification"
}

enum TargetAudience {
    case all
    case newClients
    case vipClients
    case inactiveClients
    case custom((([Client]) -> [UUID]))

    var description: String {
        switch self {
        case .all: return "All Clients"
        case .newClients: return "New Clients (Last 3 Months)"
        case .vipClients: return "VIP Clients ($1000+ LTV)"
        case .inactiveClients: return "Inactive Clients (3+ Months)"
        case .custom: return "Custom Segment"
        }
    }
}

enum CampaignStatus: String, Codable {
    case draft = "Draft"
    case scheduled = "Scheduled"
    case sending = "Sending"
    case sent = "Sent"
    case paused = "Paused"
}

struct CampaignMetrics: Codable {
    var recipientCount: Int = 0
    var sentCount: Int = 0
    var deliveredCount: Int = 0
    var openedCount: Int = 0
    var clickedCount: Int = 0
    var convertedCount: Int = 0

    var openRate: Double {
        guard deliveredCount > 0 else { return 0 }
        return Double(openedCount) / Double(deliveredCount) * 100
    }

    var clickRate: Double {
        guard deliveredCount > 0 else { return 0 }
        return Double(clickedCount) / Double(deliveredCount) * 100
    }

    var conversionRate: Double {
        guard deliveredCount > 0 else { return 0 }
        return Double(convertedCount) / Double(deliveredCount) * 100
    }
}

struct Automation: Identifiable {
    let id: UUID
    var name: String
    var trigger: AutomationTrigger
    var conditions: [AutomationCondition]
    var actions: [AutomationAction]
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        trigger: AutomationTrigger,
        conditions: [AutomationCondition] = [],
        actions: [AutomationAction],
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.conditions = conditions
        self.actions = actions
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

enum AutomationTrigger: Equatable {
    case appointmentBooked
    case appointmentCompleted
    case clientCreated
    case birthdayUpcoming
    case inactiveClient(months: Int)
    case reviewReceived
}

enum AutomationCondition {
    case firstTimeClient
    case vipClient
    case hasTag(String)
    case appointmentCount(min: Int, max: Int?)
    case totalSpent(min: Double, max: Double?)
}

enum AutomationAction {
    case sendEmail(template: String)
    case sendSMS(template: String)
    case addTag(String)
    case updateStatus(String)
    case scheduleFollowUp(days: Int)
}

struct ReferralReward: Identifiable {
    let id: UUID
    var referrerId: UUID
    var newClientId: UUID
    var rewardType: RewardType
    var rewardValue: Double
    var expirationDate: Date?
    var isRedeemed: Bool
    var redeemedDate: Date?

    init(
        id: UUID = UUID(),
        referrerId: UUID,
        newClientId: UUID,
        rewardType: RewardType,
        rewardValue: Double,
        expirationDate: Date? = nil,
        isRedeemed: Bool = false,
        redeemedDate: Date? = nil
    ) {
        self.id = id
        self.referrerId = referrerId
        self.newClientId = newClientId
        self.rewardType = rewardType
        self.rewardValue = rewardValue
        self.expirationDate = expirationDate
        self.isRedeemed = isRedeemed
        self.redeemedDate = redeemedDate
    }

    enum RewardType: String, Codable {
        case discount = "Discount"
        case freeService = "Free Service"
        case credit = "Account Credit"
        case points = "Loyalty Points"
    }
}

struct LoyaltyReward: Identifiable {
    let id: UUID
    var name: String
    var description: String
    var pointsCost: Int
    var rewardValue: Double
    var isAvailable: Bool

    static let defaultRewards: [LoyaltyReward] = [
        LoyaltyReward(id: UUID(), name: "15-Minute Add-On", description: "Free 15-minute add-on service", pointsCost: 500, rewardValue: 25.00, isAvailable: true),
        LoyaltyReward(id: UUID(), name: "$25 Off", description: "$25 off your next massage", pointsCost: 1000, rewardValue: 25.00, isAvailable: true),
        LoyaltyReward(id: UUID(), name: "Free Upgrade", description: "Free upgrade to premium service", pointsCost: 1500, rewardValue: 50.00, isAvailable: true),
        LoyaltyReward(id: UUID(), name: "$50 Off", description: "$50 off your next massage", pointsCost: 2000, rewardValue: 50.00, isAvailable: true),
        LoyaltyReward(id: UUID(), name: "Free Session", description: "Complimentary 60-minute massage", pointsCost: 3000, rewardValue: 80.00, isAvailable: true)
    ]
}

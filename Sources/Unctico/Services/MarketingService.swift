import Foundation

/// Service for marketing automation and campaign management
@MainActor
class MarketingService: ObservableObject {
    static let shared = MarketingService()

    @Published var activeAutomations: [AutomationRule] = []

    init() {
        // Initialize service
    }

    // MARK: - Audience Filtering

    /// Filter clients based on campaign audience criteria
    func filterAudience(
        audience: CampaignAudience,
        allClients: [Client]
    ) -> [Client] {
        var filteredClients = allClients

        // Apply target type
        switch audience.targetType {
        case .allClients:
            break // No filtering

        case .activeClients:
            let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            filteredClients = filteredClients.filter { client in
                guard let lastVisit = client.lastVisitDate else { return false }
                return lastVisit >= sixtyDaysAgo
            }

        case .newClients:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            filteredClients = filteredClients.filter { client in
                guard let firstVisit = client.firstVisitDate else { return false }
                return firstVisit >= thirtyDaysAgo
            }

        case .dormantClients:
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
            filteredClients = filteredClients.filter { client in
                guard let lastVisit = client.lastVisitDate else { return false }
                return lastVisit < ninetyDaysAgo
            }

        case .vipClients:
            filteredClients = filteredClients.filter { client in
                client.totalVisits >= 10 || client.totalSpent >= 1000
            }

        case .custom:
            break // Will apply filters below
        }

        // Apply include filters
        for filter in audience.filters {
            filteredClients = applyFilter(filter: filter, to: filteredClients, exclude: false)
        }

        // Apply exclude filters
        for filter in audience.excludeFilters {
            filteredClients = applyFilter(filter: filter, to: filteredClients, exclude: true)
        }

        // Filter out clients without email
        filteredClients = filteredClients.filter { !$0.email.isEmpty }

        return filteredClients
    }

    private func applyFilter(
        filter: AudienceFilter,
        to clients: [Client],
        exclude: Bool
    ) -> [Client] {
        let result = clients.filter { client in
            let matches = evaluateFilter(filter: filter, client: client)
            return exclude ? !matches : matches
        }
        return result
    }

    private func evaluateFilter(filter: AudienceFilter, client: Client) -> Bool {
        switch filter.filterType {
        case .lastVisit:
            guard let lastVisit = client.lastVisitDate,
                  let daysAgo = Int(filter.value) else { return false }
            let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            switch filter.condition {
            case .inLast:
                return lastVisit >= targetDate
            case .notInLast:
                return lastVisit < targetDate
            default:
                return false
            }

        case .totalVisits:
            guard let targetValue = Int(filter.value) else { return false }
            switch filter.condition {
            case .equals:
                return client.totalVisits == targetValue
            case .notEquals:
                return client.totalVisits != targetValue
            case .greaterThan:
                return client.totalVisits > targetValue
            case .lessThan:
                return client.totalVisits < targetValue
            default:
                return false
            }

        case .totalSpent:
            guard let targetValue = Double(filter.value) else { return false }
            switch filter.condition {
            case .equals:
                return client.totalSpent == targetValue
            case .notEquals:
                return client.totalSpent != targetValue
            case .greaterThan:
                return client.totalSpent > targetValue
            case .lessThan:
                return client.totalSpent < targetValue
            default:
                return false
            }

        case .averageSpent:
            let avgSpent = client.totalVisits > 0 ? client.totalSpent / Double(client.totalVisits) : 0
            guard let targetValue = Double(filter.value) else { return false }
            switch filter.condition {
            case .greaterThan:
                return avgSpent > targetValue
            case .lessThan:
                return avgSpent < targetValue
            default:
                return false
            }

        case .hasEmail:
            return !client.email.isEmpty

        case .hasPhone:
            return !client.phone.isEmpty

        case .birthday:
            // Check if birthday is in the next X days
            guard let daysAhead = Int(filter.value),
                  let birthday = client.dateOfBirth else { return false }
            let today = Date()
            let calendar = Calendar.current
            let todayComponents = calendar.dateComponents([.month, .day], from: today)
            let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)

            for dayOffset in 0...daysAhead {
                guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let checkComponents = calendar.dateComponents([.month, .day], from: checkDate)
                if checkComponents.month == birthdayComponents.month &&
                   checkComponents.day == birthdayComponents.day {
                    return true
                }
            }
            return false

        case .tags:
            let targetTag = filter.value.lowercased()
            let hasTag = client.tags.contains { $0.lowercased() == targetTag }
            switch filter.condition {
            case .contains:
                return hasTag
            case .notContains:
                return !hasTag
            default:
                return false
            }
        }
    }

    // MARK: - Email Rendering

    /// Render email template with client data
    func renderEmail(
        template: EmailTemplate,
        client: Client,
        additionalData: [String: String] = [:]
    ) -> RenderedEmail {
        var data: [String: String] = [
            "client_name": "\(client.firstName) \(client.lastName)",
            "first_name": client.firstName,
            "last_name": client.lastName,
            "email": client.email,
            "phone": client.phone,
            "total_visits": "\(client.totalVisits)",
            "total_spent": String(format: "$%.2f", client.totalSpent)
        ]

        // Add additional data
        for (key, value) in additionalData {
            data[key] = value
        }

        return template.renderWithData(data)
    }

    // MARK: - Campaign Execution

    /// Send campaign to recipients (simulated)
    func sendCampaign(
        campaign: EmailCampaign,
        recipients: [Client]
    ) -> (logs: [EmailLog], metrics: CampaignMetrics) {
        var logs: [EmailLog] = []
        var metrics = CampaignMetrics()

        // Determine variant split if A/B test
        let abTest = campaign.abTest
        var variantACount = 0
        var variantBCount = 0

        if let test = abTest {
            let splitIndex = Int(Double(recipients.count) * (test.splitPercentage / 100.0))
            variantACount = splitIndex
            variantBCount = recipients.count - splitIndex
        }

        for (index, client) in recipients.enumerated() {
            // Determine which template to use
            var template = campaign.template
            var variant: TestVariant? = nil

            if let test = abTest {
                if index < variantACount {
                    template = test.variantA
                    variant = .variantA
                } else {
                    template = test.variantB
                    variant = .variantB
                }
            }

            // Render email
            let rendered = renderEmail(template: template, client: client)

            // Simulate email sending with random outcomes
            let status = simulateEmailDelivery()

            let log = EmailLog(
                campaignId: campaign.id,
                campaignName: campaign.name,
                clientId: client.id,
                clientEmail: client.email,
                subject: rendered.subject,
                status: status,
                variant: variant
            )

            logs.append(log)

            // Update metrics
            metrics.totalSent += 1

            switch status {
            case .delivered, .opened, .clicked:
                metrics.totalDelivered += 1
            case .bounced:
                metrics.totalBounced += 1
            default:
                break
            }

            if status == .opened || status == .clicked {
                metrics.totalOpened += 1
            }

            if status == .clicked {
                metrics.totalClicked += 1
            }
        }

        return (logs, metrics)
    }

    private func simulateEmailDelivery() -> EmailStatus {
        let random = Double.random(in: 0...1)

        if random < 0.05 { // 5% bounce
            return .bounced
        } else if random < 0.35 { // 30% opened
            return .opened
        } else if random < 0.45 { // 10% clicked
            return .clicked
        } else {
            return .delivered
        }
    }

    // MARK: - A/B Testing

    /// Determine winner of A/B test
    func determineABTestWinner(test: ABTest) -> TestVariant? {
        let metricsA = test.metricsA
        let metricsB = test.metricsB

        switch test.winnerCriteria {
        case .openRate:
            if metricsA.openRate > metricsB.openRate {
                return .variantA
            } else if metricsB.openRate > metricsA.openRate {
                return .variantB
            }

        case .clickRate:
            if metricsA.clickRate > metricsB.clickRate {
                return .variantA
            } else if metricsB.clickRate > metricsA.clickRate {
                return .variantB
            }

        case .conversionRate:
            if metricsA.conversionRate > metricsB.conversionRate {
                return .variantA
            } else if metricsB.conversionRate > metricsA.conversionRate {
                return .variantB
            }

        case .revenue:
            if metricsA.revenue > metricsB.revenue {
                return .variantA
            } else if metricsB.revenue > metricsA.revenue {
                return .variantB
            }
        }

        return nil // Tie or insufficient data
    }

    /// Split A/B test metrics from email logs
    func splitABTestMetrics(logs: [EmailLog]) -> (metricsA: CampaignMetrics, metricsB: CampaignMetrics) {
        let logsA = logs.filter { $0.variant == .variantA }
        let logsB = logs.filter { $0.variant == .variantB }

        let metricsA = calculateMetricsFromLogs(logsA)
        let metricsB = calculateMetricsFromLogs(logsB)

        return (metricsA, metricsB)
    }

    private func calculateMetricsFromLogs(_ logs: [EmailLog]) -> CampaignMetrics {
        var metrics = CampaignMetrics()

        metrics.totalSent = logs.count
        metrics.totalDelivered = logs.filter { $0.status == .delivered || $0.status == .opened || $0.status == .clicked }.count
        metrics.totalOpened = logs.filter { $0.status == .opened || $0.status == .clicked }.count
        metrics.totalClicked = logs.filter { $0.status == .clicked }.count
        metrics.totalBounced = logs.filter { $0.status == .bounced }.count
        metrics.totalUnsubscribed = logs.filter { $0.status == .unsubscribed }.count

        return metrics
    }

    // MARK: - Automation

    /// Check if automation rule should trigger for a client
    func shouldTriggerAutomation(
        rule: AutomationRule,
        client: Client,
        triggerContext: TriggerContext
    ) -> Bool {
        // Check if rule is active
        guard rule.isActive else { return false }

        // Check if trigger matches
        guard rule.trigger == triggerContext.event else { return false }

        // Check all conditions
        for condition in rule.conditions {
            if !evaluateAutomationCondition(condition: condition, client: client) {
                return false
            }
        }

        return true
    }

    private func evaluateAutomationCondition(
        condition: AutomationCondition,
        client: Client
    ) -> Bool {
        switch condition.conditionType {
        case .hasEmail:
            return !client.email.isEmpty

        case .totalVisits:
            guard let targetValue = Int(condition.value) else { return false }
            switch condition.operator_ {
            case .equals:
                return client.totalVisits == targetValue
            case .notEquals:
                return client.totalVisits != targetValue
            case .greaterThan:
                return client.totalVisits > targetValue
            case .lessThan:
                return client.totalVisits < targetValue
            default:
                return false
            }

        case .lastVisit:
            guard let lastVisit = client.lastVisitDate,
                  let daysAgo = Int(condition.value) else { return false }
            let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            return lastVisit >= targetDate

        case .clientTag:
            let targetTag = condition.value.lowercased()
            let hasTag = client.tags.contains { $0.lowercased() == targetTag }
            switch condition.operator_ {
            case .contains:
                return hasTag
            case .notContains:
                return !hasTag
            default:
                return false
            }

        case .emailOptIn:
            // Assuming all clients with email have opted in
            return !client.email.isEmpty
        }
    }

    /// Queue automation email for client
    func queueAutomationEmail(
        rule: AutomationRule,
        client: Client,
        sendDate: Date
    ) -> EmailLog {
        let rendered = renderEmail(template: rule.template, client: client)

        return EmailLog(
            campaignId: nil,
            campaignName: "Automation: \(rule.name)",
            clientId: client.id,
            clientEmail: client.email,
            subject: rendered.subject,
            status: .queued,
            sentDate: sendDate
        )
    }

    // MARK: - Analytics

    /// Calculate marketing statistics from campaigns
    func calculateMarketingStatistics(
        campaigns: [EmailCampaign],
        marketingCost: Double = 0
    ) -> MarketingStatistics {
        let totalCampaigns = campaigns.count
        let activeCampaigns = campaigns.filter { $0.isActive }.count

        var totalEmailsSent = 0
        var totalOpened = 0
        var totalDelivered = 0
        var totalClicked = 0
        var totalConverted = 0
        var totalRevenue = 0.0

        for campaign in campaigns {
            if let metrics = campaign.metrics {
                totalEmailsSent += metrics.totalSent
                totalDelivered += metrics.totalDelivered
                totalOpened += metrics.totalOpened
                totalClicked += metrics.totalClicked
                totalConverted += metrics.totalConverted
                totalRevenue += metrics.revenue
            }
        }

        let averageOpenRate = totalDelivered > 0 ? Double(totalOpened) / Double(totalDelivered) * 100 : 0
        let averageClickRate = totalDelivered > 0 ? Double(totalClicked) / Double(totalDelivered) * 100 : 0
        let averageConversionRate = totalDelivered > 0 ? Double(totalConverted) / Double(totalDelivered) * 100 : 0

        let roi = marketingCost > 0 ? (totalRevenue - marketingCost) / marketingCost * 100 : 0

        return MarketingStatistics(
            totalCampaigns: totalCampaigns,
            activeCampaigns: activeCampaigns,
            totalEmailsSent: totalEmailsSent,
            averageOpenRate: averageOpenRate,
            averageClickRate: averageClickRate,
            averageConversionRate: averageConversionRate,
            totalRevenue: totalRevenue,
            roi: roi
        )
    }

    /// Get best performing campaigns by criteria
    func getBestPerformingCampaigns(
        campaigns: [EmailCampaign],
        by criteria: WinnerCriteria,
        limit: Int = 5
    ) -> [EmailCampaign] {
        let campaignsWithMetrics = campaigns.filter { $0.metrics != nil }

        let sorted = campaignsWithMetrics.sorted { campaign1, campaign2 in
            guard let metrics1 = campaign1.metrics,
                  let metrics2 = campaign2.metrics else { return false }

            switch criteria {
            case .openRate:
                return metrics1.openRate > metrics2.openRate
            case .clickRate:
                return metrics1.clickRate > metrics2.clickRate
            case .conversionRate:
                return metrics1.conversionRate > metrics2.conversionRate
            case .revenue:
                return metrics1.revenue > metrics2.revenue
            }
        }

        return Array(sorted.prefix(limit))
    }
}

// MARK: - Supporting Types

struct TriggerContext {
    let event: TriggerEvent
    let metadata: [String: Any]

    init(event: TriggerEvent, metadata: [String: Any] = [:]) {
        self.event = event
        self.metadata = metadata
    }
}

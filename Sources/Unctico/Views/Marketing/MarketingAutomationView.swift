import SwiftUI

struct MarketingAutomationView: View {
    @StateObject private var repository = MarketingRepository.shared
    @StateObject private var service = MarketingService.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                CampaignsListView()
                    .tabItem {
                        Label("Campaigns", systemImage: "envelope.fill")
                    }
                    .tag(0)

                TemplatesListView()
                    .tabItem {
                        Label("Templates", systemImage: "doc.text.fill")
                    }
                    .tag(1)

                AutomationRulesView()
                    .tabItem {
                        Label("Automation", systemImage: "bolt.fill")
                    }
                    .tag(2)

                MarketingStatsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
            }
            .navigationTitle("Marketing")
        }
    }
}

// MARK: - Campaigns List View

struct CampaignsListView: View {
    @StateObject private var repository = MarketingRepository.shared
    @State private var searchText = ""
    @State private var selectedStatus: CampaignStatus?
    @State private var showingNewCampaign = false

    var filteredCampaigns: [EmailCampaign] {
        var campaigns = repository.campaigns

        if let status = selectedStatus {
            campaigns = campaigns.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            campaigns = repository.searchCampaigns(query: searchText)
        }

        return campaigns.sorted { $0.createdDate > $1.createdDate }
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

                    ForEach(CampaignStatus.allCases, id: \.self) { status in
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
                if filteredCampaigns.isEmpty {
                    ContentUnavailableView(
                        "No Campaigns",
                        systemImage: "envelope",
                        description: Text("Create your first email campaign")
                    )
                } else {
                    ForEach(filteredCampaigns) { campaign in
                        NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
                            CampaignRow(campaign: campaign)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search campaigns")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCampaign = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCampaign) {
            Text("New Campaign")
        }
    }
}

struct CampaignRow: View {
    let campaign: EmailCampaign

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: campaign.campaignType.icon)
                    .foregroundColor(.blue)

                Text(campaign.name)
                    .font(.headline)

                Spacer()

                StatusBadge(status: campaign.status)
            }

            Text(campaign.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let metrics = campaign.metrics {
                HStack(spacing: 16) {
                    MetricLabel(icon: "paperplane.fill", value: "\(metrics.totalSent)", label: "Sent")
                    MetricLabel(icon: "envelope.open.fill", value: String(format: "%.1f%%", metrics.openRate), label: "Opens")
                    MetricLabel(icon: "hand.point.up.left.fill", value: String(format: "%.1f%%", metrics.clickRate), label: "Clicks")

                    if metrics.revenue > 0 {
                        MetricLabel(icon: "dollarsign.circle.fill", value: String(format: "$%.0f", metrics.revenue), label: "Revenue")
                    }
                }
                .font(.caption2)
            }

            if !campaign.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(campaign.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MetricLabel: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .fontWeight(.medium)
                Text(label)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatusBadge: View {
    let status: CampaignStatus

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

// MARK: - Campaign Detail View

struct CampaignDetailView: View {
    let campaign: EmailCampaign

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: campaign.campaignType.icon)
                            .font(.title)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(campaign.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(campaign.campaignType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        StatusBadge(status: campaign.status)
                    }

                    if !campaign.description.isEmpty {
                        Text(campaign.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Metrics
                if let metrics = campaign.metrics {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            PerformanceMetricCard(
                                title: "Sent",
                                value: "\(metrics.totalSent)",
                                icon: "paperplane.fill",
                                color: .blue
                            )

                            PerformanceMetricCard(
                                title: "Open Rate",
                                value: String(format: "%.1f%%", metrics.openRate),
                                subtitle: "\(metrics.totalOpened) opens",
                                icon: "envelope.open.fill",
                                color: .green
                            )

                            PerformanceMetricCard(
                                title: "Click Rate",
                                value: String(format: "%.1f%%", metrics.clickRate),
                                subtitle: "\(metrics.totalClicked) clicks",
                                icon: "hand.point.up.left.fill",
                                color: .purple
                            )

                            PerformanceMetricCard(
                                title: "Conversion Rate",
                                value: String(format: "%.1f%%", metrics.conversionRate),
                                subtitle: "\(metrics.totalConverted) converted",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .orange
                            )
                        }

                        if metrics.revenue > 0 {
                            PerformanceMetricCard(
                                title: "Revenue",
                                value: String(format: "$%.2f", metrics.revenue),
                                subtitle: String(format: "$%.2f per recipient", metrics.revenuePerRecipient),
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                        }
                    }
                    .padding()
                }

                // A/B Test Results
                if let abTest = campaign.abTest {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("A/B Test Results")
                            .font(.headline)

                        HStack(spacing: 16) {
                            ABTestVariantCard(
                                variant: "Variant A",
                                metrics: abTest.metricsA,
                                isWinner: abTest.winner == .variantA
                            )

                            ABTestVariantCard(
                                variant: "Variant B",
                                metrics: abTest.metricsB,
                                isWinner: abTest.winner == .variantB
                            )
                        }

                        if let winner = abTest.winner {
                            Text("Winner: \(winner.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                }

                // Schedule
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule")
                        .font(.headline)

                    Text(campaign.schedule.description)
                        .font(.body)
                        .foregroundColor(.secondary)

                    if let sentDate = campaign.sentDate {
                        Text("Sent: \(sentDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Audience
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audience")
                        .font(.headline)

                    Text(campaign.audience.targetType.rawValue)
                        .font(.body)

                    Text("\(campaign.audience.estimatedRecipients) recipients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle(campaign.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    var subtitle: String?
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

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ABTestVariantCard: View {
    let variant: String
    let metrics: CampaignMetrics
    let isWinner: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(variant)
                    .font(.headline)

                if isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Sent: \(metrics.totalSent)")
                    .font(.caption)
                Text("Open Rate: \(String(format: "%.1f%%", metrics.openRate))")
                    .font(.caption)
                Text("Click Rate: \(String(format: "%.1f%%", metrics.clickRate))")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Templates List View

struct TemplatesListView: View {
    @StateObject private var repository = MarketingRepository.shared
    @State private var selectedCategory: TemplateCategory?
    @State private var searchText = ""
    @State private var showingNewTemplate = false

    var filteredTemplates: [EmailTemplate] {
        var templates = repository.templates

        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            templates = repository.searchTemplates(query: searchText)
        }

        return templates.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )

                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = selectedCategory == category ? nil : category }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))

            List {
                if filteredTemplates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.text",
                        description: Text("Create your first email template")
                    )
                } else {
                    ForEach(filteredTemplates) { template in
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            TemplateRow(template: template)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewTemplate) {
            Text("New Template")
        }
    }
}

struct TemplateRow: View {
    let template: EmailTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.category.icon)
                    .foregroundColor(.blue)

                Text(template.name)
                    .font(.headline)

                Spacer()

                if template.isDefault {
                    Text("Default")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }

            Text(template.subject)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(template.category.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateDetailView: View {
    let template: EmailTemplate

    var body: some View {
        Form {
            Section("Template Info") {
                DetailRow(label: "Name", value: template.name)
                DetailRow(label: "Category", value: template.category.rawValue)
                if template.isDefault {
                    DetailRow(label: "Default", value: "Yes")
                }
            }

            Section("Email Content") {
                DetailRow(label: "Subject", value: template.subject)

                if !template.previewText.isEmpty {
                    DetailRow(label: "Preview", value: template.previewText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Body")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(template.body)
                        .font(.body)
                }
            }

            if !template.placeholders.isEmpty {
                Section("Placeholders") {
                    ForEach(template.placeholders, id: \.self) { placeholder in
                        Text("{{\(placeholder)}}")
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Automation Rules View

struct AutomationRulesView: View {
    @StateObject private var repository = MarketingRepository.shared
    @State private var showingNewRule = false

    var body: some View {
        List {
            if repository.automationRules.isEmpty {
                ContentUnavailableView(
                    "No Automation Rules",
                    systemImage: "bolt",
                    description: Text("Create automation rules to send emails automatically")
                )
            } else {
                ForEach(repository.automationRules) { rule in
                    AutomationRuleRow(rule: rule)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewRule = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewRule) {
            Text("New Automation Rule")
        }
    }
}

struct AutomationRuleRow: View {
    let rule: AutomationRule
    @StateObject private var repository = MarketingRepository.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(rule.isActive ? .orange : .gray)

                Text(rule.name)
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { rule.isActive },
                    set: { newValue in
                        var updatedRule = rule
                        updatedRule.isActive = newValue
                        repository.updateAutomationRule(updatedRule)
                    }
                ))
                .labelsHidden()
            }

            Text(rule.description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Trigger: \(rule.trigger.rawValue)")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("•")
                    .foregroundColor(.secondary)

                Text("Triggered \(rule.totalTriggered) times")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Marketing Stats View

struct MarketingStatsView: View {
    @StateObject private var repository = MarketingRepository.shared

    var stats: MarketingStatistics {
        repository.getStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatsCard(
                        title: "Total Campaigns",
                        value: "\(stats.totalCampaigns)",
                        icon: "envelope.fill",
                        color: .blue
                    )

                    StatsCard(
                        title: "Active Campaigns",
                        value: "\(stats.activeCampaigns)",
                        icon: "bolt.fill",
                        color: .orange
                    )

                    StatsCard(
                        title: "Emails Sent",
                        value: "\(stats.totalEmailsSent)",
                        icon: "paperplane.fill",
                        color: .green
                    )

                    StatsCard(
                        title: "Avg Open Rate",
                        value: String(format: "%.1f%%", stats.averageOpenRate),
                        icon: "envelope.open.fill",
                        color: .teal
                    )

                    StatsCard(
                        title: "Avg Click Rate",
                        value: String(format: "%.1f%%", stats.averageClickRate),
                        icon: "hand.point.up.left.fill",
                        color: .purple
                    )

                    StatsCard(
                        title: "Avg Conversion",
                        value: String(format: "%.1f%%", stats.averageConversionRate),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )
                }
                .padding()

                if stats.totalRevenue > 0 {
                    VStack(spacing: 12) {
                        StatsCard(
                            title: "Total Revenue",
                            value: String(format: "$%.2f", stats.totalRevenue),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )

                        if stats.roi != 0 {
                            StatsCard(
                                title: "ROI",
                                value: String(format: "%.1f%%", stats.roi),
                                icon: "chart.bar.fill",
                                color: stats.roi > 0 ? .green : .red
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Best Performing Campaigns
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Campaigns by Open Rate")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(repository.getBestPerformingCampaigns(by: .openRate, limit: 3)) { campaign in
                        CampaignPerformanceRow(campaign: campaign)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct CampaignPerformanceRow: View {
    let campaign: EmailCampaign

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(campaign.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let metrics = campaign.metrics {
                    Text(String(format: "%.1f%% open • %.1f%% click", metrics.openRate, metrics.clickRate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let metrics = campaign.metrics {
                Text("\(metrics.totalSent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("sent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    MarketingAutomationView()
}

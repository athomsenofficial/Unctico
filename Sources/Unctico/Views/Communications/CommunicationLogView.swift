import SwiftUI

/// Comprehensive communication log for tracking all client interactions
struct CommunicationLogView: View {
    @State private var selectedTab = 0
    @State private var showingNewLog = false
    @State private var selectedLog: CommunicationLog?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("Follow-Ups").tag(1)
                    Text("Templates").tag(2)
                    Text("Statistics").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedTab {
                case 0:
                    AllCommunicationsView(
                        showingNewLog: $showingNewLog,
                        selectedLog: $selectedLog
                    )
                case 1:
                    FollowUpsView()
                case 2:
                    TemplatesView()
                case 3:
                    StatisticsView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Communication Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewLog = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewLog) {
                NewCommunicationLogView()
            }
            .sheet(item: $selectedLog) { log in
                CommunicationDetailView(log: log)
            }
        }
    }
}

// MARK: - All Communications View

struct AllCommunicationsView: View {
    @Binding var showingNewLog: Bool
    @Binding var selectedLog: CommunicationLog?
    @State private var logs: [CommunicationLog] = [] // TODO: Load from repository
    @State private var searchText = ""
    @State private var selectedType: CommunicationType? = nil
    @State private var selectedDirection: Direction? = nil

    private var filteredLogs: [CommunicationLog] {
        var filtered = logs

        if let type = selectedType {
            filtered = filtered.filter { $0.communicationType == type }
        }

        if let direction = selectedDirection {
            filtered = filtered.filter { $0.direction == direction }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.subject.lowercased().contains(searchText.lowercased()) ||
                $0.content.lowercased().contains(searchText.lowercased())
            }
        }

        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    private var logsByDate: [(Date, [CommunicationLog])] {
        let grouped = Dictionary(grouping: filteredLogs) { log in
            Calendar.current.startOfDay(for: log.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search communications...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // Filters
                HStack(spacing: 12) {
                    Menu {
                        Button("All Types") { selectedType = nil }
                        Divider()
                        ForEach(CommunicationType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedType?.rawValue ?? "Type")
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedType != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedType != nil ? .blue : .primary)
                        .cornerRadius(8)
                    }

                    Menu {
                        Button("All") { selectedDirection = nil }
                        Divider()
                        ForEach([Direction.incoming, .outgoing], id: \.self) { direction in
                            Button {
                                selectedDirection = direction
                            } label: {
                                Label(direction.rawValue, systemImage: direction.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedDirection?.icon ?? "arrow.left.arrow.right.circle")
                            Text(selectedDirection?.rawValue ?? "Direction")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedDirection != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedDirection != nil ? .blue : .primary)
                        .cornerRadius(8)
                    }

                    if selectedType != nil || selectedDirection != nil {
                        Button {
                            selectedType = nil
                            selectedDirection = nil
                        } label: {
                            Text("Clear")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Logs list
            if filteredLogs.isEmpty {
                CommunicationEmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: logs.isEmpty ? "No Communications Yet" : "No Results",
                    message: logs.isEmpty ? "Start logging client communications here" : "Try adjusting your search or filters"
                )
            } else {
                List {
                    ForEach(logsByDate, id: \.0) { date, logs in
                        Section {
                            ForEach(logs) { log in
                                Button {
                                    selectedLog = log
                                } label: {
                                    CommunicationRowView(log: log)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if log.followUpRequired && !log.followUpCompleted {
                                        Button {
                                            // TODO: Mark follow-up complete
                                        } label: {
                                            Label("Complete", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }

                                    Button(role: .destructive) {
                                        // TODO: Delete log
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(date.formatted(date: .complete, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct CommunicationRowView: View {
    let log: CommunicationLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Type icon
                Image(systemName: log.communicationType.icon)
                    .foregroundColor(colorForType(log.communicationType.color))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    // Subject
                    Text(log.subject)
                        .font(.headline)
                        .lineLimit(1)

                    // Content preview
                    Text(log.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // Metadata
                    HStack(spacing: 12) {
                        Label(log.timestamp.formatted(date: .omitted, time: .shortened), systemImage: "clock")

                        Label(log.direction.rawValue, systemImage: log.direction.icon)

                        if log.followUpRequired && !log.followUpCompleted {
                            Label("Follow-up", systemImage: "flag.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .blue
        }
    }
}

// MARK: - Follow-Ups View

struct FollowUpsView: View {
    @State private var logs: [CommunicationLog] = [] // TODO: Load from repository

    private var pendingFollowUps: [CommunicationLog] {
        logs.filter { $0.followUpRequired && !$0.followUpCompleted }
            .sorted { ($0.followUpDate ?? Date.distantFuture) < ($1.followUpDate ?? Date.distantFuture) }
    }

    private var overdueFollowUps: [CommunicationLog] {
        pendingFollowUps.filter { log in
            if let followUpDate = log.followUpDate {
                return followUpDate < Date()
            }
            return false
        }
    }

    var body: some View {
        if pendingFollowUps.isEmpty {
            CommunicationEmptyStateView(
                icon: "checkmark.circle",
                title: "No Pending Follow-Ups",
                message: "All follow-ups are complete!"
            )
        } else {
            List {
                if !overdueFollowUps.isEmpty {
                    Section {
                        ForEach(overdueFollowUps) { log in
                            FollowUpRow(log: log)
                        }
                    } header: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }

                Section {
                    ForEach(pendingFollowUps.filter { !overdueFollowUps.contains($0) }) { log in
                        FollowUpRow(log: log)
                    }
                } header: {
                    Text("Upcoming")
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct FollowUpRow: View {
    let log: CommunicationLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: log.communicationType.icon)
                    .foregroundColor(.orange)

                Text(log.subject)
                    .font(.headline)

                Spacer()

                if let followUpDate = log.followUpDate {
                    if followUpDate < Date() {
                        Label("Overdue", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text(followUpDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(log.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text("Created: \(log.timestamp.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    // TODO: Mark complete
                } label: {
                    Text("Mark Complete")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Templates View

struct TemplatesView: View {
    @State private var searchText = ""
    @State private var selectedCategory: CommunicationCategory? = nil

    private var filteredTemplates: [CommunicationTemplate] {
        var templates = CommunicationTemplate.templateLibrary

        if let category = selectedCategory {
            templates = templates.filter { $0.communicationType.category == category }
        }

        if !searchText.isEmpty {
            templates = CommunicationTemplate.search(searchText)
        }

        return templates
    }

    private var templatesByCategory: [(CommunicationCategory, [CommunicationTemplate])] {
        let grouped = Dictionary(grouping: filteredTemplates) { $0.communicationType.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        selectedCategory = nil
                    } label: {
                        TemplateCategoryChip(title: "All", isSelected: selectedCategory == nil)
                    }

                    ForEach(CommunicationCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            TemplateCategoryChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            )
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Templates list
            if filteredTemplates.isEmpty {
                CommunicationEmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Templates Found",
                    message: "Try adjusting your search or category filter"
                )
            } else {
                List {
                    ForEach(templatesByCategory, id: \.0) { category, templates in
                        Section {
                            ForEach(templates) { template in
                                TemplateRowView(template: template)
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct TemplateCategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

struct TemplateRowView: View {
    let template: CommunicationTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.communicationType.icon)
                    .foregroundColor(.blue)

                Text(template.name)
                    .font(.headline)

                Spacer()

                Button {
                    // TODO: Use template
                } label: {
                    Text("Use")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }

            Text(template.body)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @State private var logs: [CommunicationLog] = [] // TODO: Load from repository

    private var statistics: CommunicationStatistics {
        CommunicationStatistics.calculate(from: logs)
    }

    var body: some View {
        if logs.isEmpty {
            CommunicationEmptyStateView(
                icon: "chart.bar",
                title: "No Statistics Yet",
                message: "Statistics will appear once you start logging communications"
            )
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total",
                            value: "\(statistics.totalCommunications)",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Pending Follow-Ups",
                            value: "\(statistics.pendingFollowUps)",
                            icon: "flag.fill",
                            color: .orange
                        )
                    }

                    // By category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Category")
                            .font(.headline)

                        ForEach(Array(statistics.byCategory.sorted { $0.value > $1.value }), id: \.key) { category, count in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)

                                Text(category.rawValue)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(count)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - New Communication Log View

struct NewCommunicationLogView: View {
    @State private var communicationType: CommunicationType = .phoneCall
    @State private var direction: Direction = .outgoing
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var followUpRequired: Bool = false
    @State private var followUpDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var selectedTemplate: CommunicationTemplate? = nil
    @State private var showingTemplatePicker = false
    @Environment(\.dismiss) var dismiss

    private var canSave: Bool {
        !subject.isEmpty && !content.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Type", selection: $communicationType) {
                        ForEach(CommunicationType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }

                    Picker("Direction", selection: $direction) {
                        ForEach([Direction.incoming, .outgoing], id: \.self) { dir in
                            Label(dir.rawValue, systemImage: dir.icon).tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Communication Details")
                }

                Section {
                    TextField("Subject", text: $subject)

                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                } header: {
                    HStack {
                        Text("Content")
                        Spacer()
                        Button {
                            showingTemplatePicker = true
                        } label: {
                            Label("Use Template", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                    }
                }

                Section {
                    Toggle("Follow-up Required", isOn: $followUpRequired)

                    if followUpRequired {
                        DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: [.date])
                    }
                } header: {
                    Text("Follow-Up")
                }

                Section {
                    Button {
                        saveCommunication()
                    } label: {
                        Text("Save Communication")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("New Communication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView(selectedTemplate: $selectedTemplate)
            }
            .onChange(of: selectedTemplate) { newTemplate in
                if let template = newTemplate {
                    subject = template.subject
                    content = template.body
                    communicationType = template.communicationType
                }
            }
        }
    }

    private func saveCommunication() {
        // TODO: Save to repository
        let log = CommunicationLog(
            clientId: UUID(), // TODO: Get from context
            communicationType: communicationType,
            direction: direction,
            subject: subject,
            content: content,
            followUpRequired: followUpRequired,
            followUpDate: followUpRequired ? followUpDate : nil,
            createdBy: "Current Therapist" // TODO: Get from auth
        )
        dismiss()
    }
}

// MARK: - Template Picker View

struct TemplatePickerView: View {
    @Binding var selectedTemplate: CommunicationTemplate?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(CommunicationTemplate.templateLibrary) { template in
                    Button {
                        selectedTemplate = template
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.communicationType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Communication Detail View

struct CommunicationDetailView: View {
    let log: CommunicationLog
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: log.communicationType.icon)
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(log.communicationType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(log.subject)
                                    .font(.title3.weight(.bold))
                            }

                            Spacer()

                            Label(log.direction.rawValue, systemImage: log.direction.icon)
                                .font(.caption)
                        }

                        Text(log.timestamp.formatted(date: .long, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)

                        Text(log.content)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Follow-up
                    if log.followUpRequired {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Follow-Up", systemImage: "flag.fill")
                                .font(.headline)
                                .foregroundColor(.orange)

                            if let followUpDate = log.followUpDate {
                                Text("Due: \(followUpDate.formatted(date: .long, time: .omitted))")
                                    .font(.subheadline)
                            }

                            if log.followUpCompleted {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Completed")
                                        .font(.subheadline)
                                }
                            } else {
                                Button {
                                    // TODO: Mark complete
                                } label: {
                                    Text("Mark as Complete")
                                        .frame(maxWidth: .infinity)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)

                        HStack {
                            Text("Created by:")
                            Spacer()
                            Text(log.createdBy)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Communication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // TODO: Edit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            // TODO: Export
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            // TODO: Delete
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Empty State View

struct CommunicationEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    CommunicationLogView()
}

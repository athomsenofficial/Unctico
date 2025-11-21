import SwiftUI

/// Manage appointment reminders and templates
struct AppointmentReminderView: View {
    @State private var selectedTab = 0
    @State private var showingTemplateEditor = false
    @State private var selectedTemplate: ReminderTemplate?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Templates").tag(0)
                    Text("Scheduled").tag(1)
                    Text("History").tag(2)
                    Text("Settings").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedTab {
                case 0:
                    TemplatesView(
                        showingEditor: $showingTemplateEditor,
                        selectedTemplate: $selectedTemplate
                    )
                case 1:
                    ScheduledRemindersView()
                case 2:
                    ReminderHistoryView()
                case 3:
                    ReminderSettingsView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Appointment Reminders")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTemplateEditor) {
                if let template = selectedTemplate {
                    TemplateEditorView(template: template)
                }
            }
        }
    }
}

// MARK: - Templates View

struct TemplatesView: View {
    @Binding var showingEditor: Bool
    @Binding var selectedTemplate: ReminderTemplate?
    @State private var searchText = ""
    @State private var selectedType: ReminderType? = nil

    private var filteredTemplates: [ReminderTemplate] {
        var templates = ReminderTemplate.templateLibrary

        if let type = selectedType {
            templates = templates.filter { $0.reminderType == type }
        }

        if !searchText.isEmpty {
            templates = ReminderTemplate.search(searchText)
        }

        return templates
    }

    private var templatesByType: [(ReminderType, [ReminderTemplate])] {
        let grouped = Dictionary(grouping: filteredTemplates) { $0.reminderType }
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

            // Type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        selectedType = nil
                    } label: {
                        TypeChip(
                            title: "All",
                            isSelected: selectedType == nil
                        )
                    }

                    ForEach(ReminderType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            TypeChip(
                                title: type.rawValue,
                                icon: type.icon,
                                isSelected: selectedType == type
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))

            Divider()

            // Template list
            if filteredTemplates.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No templates found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(templatesByType, id: \.0) { type, templates in
                        Section {
                            ForEach(templates) { template in
                                Button {
                                    selectedTemplate = template
                                    showingEditor = true
                                } label: {
                                    TemplateRowView(template: template)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
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

struct TypeChip: View {
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
    let template: ReminderTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.deliveryMethod.icon)
                    .foregroundColor(.blue)

                Text(template.name)
                    .font(.headline)

                Spacer()

                if template.isDefault {
                    Text("DEFAULT")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(template.messageBody)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Label(template.deliveryMethod.rawValue, systemImage: template.deliveryMethod.icon)
                Text("•")
                Text("\(template.placeholders.count) fields")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Scheduled Reminders View

struct ScheduledRemindersView: View {
    @State private var reminders: [AppointmentReminder] = [] // TODO: Load from repository

    var body: some View {
        if reminders.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("No Scheduled Reminders")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Reminders will appear here when appointments are booked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(reminders) { reminder in
                    ScheduledReminderRow(reminder: reminder)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct ScheduledReminderRow: View {
    let reminder: AppointmentReminder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminder.reminderType.icon)
                    .foregroundColor(colorForReminderType(reminder.reminderType.color))

                Text(reminder.reminderType.rawValue)
                    .font(.headline)

                Spacer()

                StatusBadge(status: reminder.status)
            }

            HStack {
                Label(
                    reminder.scheduledFor.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar.badge.clock"
                )
                Text("•")
                Label(reminder.deliveryMethod.rawValue, systemImage: reminder.deliveryMethod.icon)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func colorForReminderType(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "gray": return .gray
        case "teal": return .teal
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

struct StatusBadge: View {
    let status: ReminderStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForStatus.opacity(0.1))
            .foregroundColor(colorForStatus)
            .cornerRadius(4)
    }

    private var colorForStatus: Color {
        switch status.color {
        case "green": return .green
        case "red": return .red
        case "blue": return .blue
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Reminder History View

struct ReminderHistoryView: View {
    @State private var sentReminders: [AppointmentReminder] = [] // TODO: Load from repository
    @State private var filterStatus: ReminderStatus? = nil

    private var filteredReminders: [AppointmentReminder] {
        if let status = filterStatus {
            return sentReminders.filter { $0.status == status }
        }
        return sentReminders
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        filterStatus = nil
                    } label: {
                        TypeChip(title: "All", isSelected: filterStatus == nil)
                    }

                    ForEach([ReminderStatus.sent, .failed, .cancelled], id: \.self) { status in
                        Button {
                            filterStatus = status
                        } label: {
                            TypeChip(title: status.rawValue, isSelected: filterStatus == status)
                        }
                    }
                }
                .padding()
            }

            Divider()

            if filteredReminders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Reminder History")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Sent reminders will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredReminders) { reminder in
                        ReminderHistoryRow(reminder: reminder)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct ReminderHistoryRow: View {
    let reminder: AppointmentReminder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminder.reminderType.icon)
                    .foregroundColor(.blue)

                Text(reminder.reminderType.rawValue)
                    .font(.headline)

                Spacer()

                StatusBadge(status: reminder.status)
            }

            if let sentAt = reminder.sentAt {
                Text("Sent: \(sentAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = reminder.deliveryError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reminder Settings View

struct ReminderSettingsView: View {
    @State private var settings = ReminderSettings()

    var body: some View {
        Form {
            Section {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    Toggle(isOn: Binding(
                        get: { settings.enabledReminderTypes.contains(type) },
                        set: { enabled in
                            if enabled {
                                settings.enabledReminderTypes.insert(type)
                            } else {
                                settings.enabledReminderTypes.remove(type)
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text(type.rawValue)
                        }
                    }
                }
            } header: {
                Text("Enabled Reminder Types")
            } footer: {
                Text("Select which types of reminders will be automatically sent to clients")
            }

            Section {
                Picker("Default Method", selection: $settings.defaultDeliveryMethod) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        Label(method.rawValue, systemImage: method.icon).tag(method)
                    }
                }

                TextField("Send From Number", text: Binding(
                    get: { settings.sendFromNumber ?? "" },
                    set: { settings.sendFromNumber = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.phonePad)

                TextField("Send From Email", text: Binding(
                    get: { settings.sendFromEmail ?? "" },
                    set: { settings.sendFromEmail = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

                TextField("Reply To Email", text: Binding(
                    get: { settings.replyToEmail ?? "" },
                    set: { settings.replyToEmail = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            } header: {
                Text("Delivery Settings")
            }

            Section {
                Toggle("Auto-confirm new appointments", isOn: $settings.autoConfirmNewAppointments)

                Stepper("Follow-up after: \(settings.sendFollowUpAfterHours) hours",
                       value: $settings.sendFollowUpAfterHours,
                       in: 1...72)

                Stepper("Cancellation policy: \(settings.cancelationPolicyHours) hours",
                       value: $settings.cancelationPolicyHours,
                       in: 1...72)
            } header: {
                Text("Policies")
            } footer: {
                Text("These settings control automatic reminder behavior and cancellation policies")
            }

            Section {
                Button {
                    // TODO: Save settings
                } label: {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
            }
        }
    }
}

// MARK: - Template Editor View

struct TemplateEditorView: View {
    let template: ReminderTemplate
    @State private var editedSubject: String
    @State private var editedBody: String
    @State private var showingPlaceholderPicker = false
    @Environment(\.dismiss) var dismiss

    init(template: ReminderTemplate) {
        self.template = template
        _editedSubject = State(initialValue: template.subject)
        _editedBody = State(initialValue: template.messageBody)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: template.reminderType.icon)
                            .foregroundColor(.blue)
                        Text(template.reminderType.rawValue)
                            .font(.headline)
                    }
                } header: {
                    Text("Template Type")
                }

                if template.deliveryMethod == .email || template.deliveryMethod == .both {
                    Section {
                        TextField("Subject", text: $editedSubject)
                    } header: {
                        Text("Email Subject")
                    }
                }

                Section {
                    TextEditor(text: $editedBody)
                        .frame(minHeight: 200)
                        .font(.body)
                } header: {
                    HStack {
                        Text("Message Body")
                        Spacer()
                        Button {
                            showingPlaceholderPicker = true
                        } label: {
                            Label("Insert Field", systemImage: "plus.circle.fill")
                                .font(.caption)
                        }
                    }
                }

                Section {
                    ForEach(template.placeholders, id: \.self) { placeholder in
                        HStack {
                            Text(placeholder)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)

                            Spacer()

                            Button {
                                editedBody += placeholder
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Available Fields")
                } footer: {
                    Text("Tap the + button to insert a field into your message")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)

                        Text(editedBody)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } header: {
                    Text("Message Preview")
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        // TODO: Save template
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AppointmentReminderView()
}

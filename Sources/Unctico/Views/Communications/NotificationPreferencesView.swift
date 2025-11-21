import SwiftUI

/// Client notification preferences management
struct NotificationPreferencesView: View {
    @StateObject private var scheduler = AppointmentReminderScheduler.shared

    @State private var preferences = NotificationPreferences()
    @State private var showingSaved = false

    var body: some View {
        Form {
            // Global Scheduler Settings
            Section {
                Toggle(isOn: $scheduler.isEnabled) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.tranquilTeal)
                        Text("Enable Automatic Reminders")
                    }
                }
            } header: {
                Text("Scheduler")
            } footer: {
                Text("When enabled, appointment reminders will be sent automatically based on client preferences")
                    .font(.caption)
            }

            // Communication Channels
            Section("Communication Channels") {
                Toggle(isOn: $preferences.emailEnabled) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.purple)
                        Text("Email Notifications")
                    }
                }

                Toggle(isOn: $preferences.smsEnabled) {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                        Text("SMS Notifications")
                    }
                }

                Toggle(isOn: $preferences.pushEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text("Push Notifications")
                    }
                }
            }

            // Email Reminder Timing
            if preferences.emailEnabled {
                Section("Email Reminder Timing") {
                    ForEach([ReminderTiming.oneHourBefore, .fourHoursBefore, .oneDayBefore, .twoDaysBefore, .oneWeekBefore], id: \.self) { timing in
                        Toggle(isOn: Binding(
                            get: { preferences.emailReminders.contains(timing) },
                            set: { isEnabled in
                                if isEnabled {
                                    preferences.emailReminders.append(timing)
                                } else {
                                    preferences.emailReminders.removeAll { $0 == timing }
                                }
                            }
                        )) {
                            Label(timing.displayName, systemImage: "clock")
                        }
                    }
                }
            }

            // SMS Reminder Timing
            if preferences.smsEnabled {
                Section("SMS Reminder Timing") {
                    ForEach([ReminderTiming.oneHourBefore, .fourHoursBefore, .oneDayBefore, .twoDaysBefore, .oneWeekBefore], id: \.self) { timing in
                        Toggle(isOn: Binding(
                            get: { preferences.smsReminders.contains(timing) },
                            set: { isEnabled in
                                if isEnabled {
                                    preferences.smsReminders.append(timing)
                                } else {
                                    preferences.smsReminders.removeAll { $0 == timing }
                                }
                            }
                        )) {
                            Label(timing.displayName, systemImage: "clock")
                        }
                    }
                }
            }

            // Message Type Preferences
            Section("Message Types") {
                Toggle(isOn: $preferences.appointmentReminders) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appointment Reminders")
                            Text("Automatic reminders before appointments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.appointmentConfirmations) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appointment Confirmations")
                            Text("Confirmation when appointment is booked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.followUpMessages) {
                    HStack {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Follow-up Messages")
                            Text("Check-ins after appointments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.birthdayGreetings) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Birthday Greetings")
                            Text("Special birthday wishes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(isOn: $preferences.promotionalMessages) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Promotional Messages")
                            Text("Special offers and promotions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Preview
            Section("Preview") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your current settings will result in:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if preferences.emailEnabled && !preferences.emailReminders.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email reminders:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(preferences.emailReminders.map { $0.displayName }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if preferences.smsEnabled && !preferences.smsReminders.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SMS reminders:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(preferences.smsReminders.map { $0.displayName }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !preferences.emailEnabled && !preferences.smsEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(.gray)
                            Text("No automatic notifications enabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Best Practices
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        Text("Best Practices")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        BestPracticeRow(
                            icon: "envelope",
                            text: "Send email reminders 1 day before for details"
                        )
                        BestPracticeRow(
                            icon: "message",
                            text: "Send SMS reminders 1 hour before for urgency"
                        )
                        BestPracticeRow(
                            icon: "calendar",
                            text: "Avoid sending more than 3 reminders per appointment"
                        )
                        BestPracticeRow(
                            icon: "clock",
                            text: "Schedule campaigns during business hours"
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            // Save Button
            Section {
                Button(action: savePreferences) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Preferences")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tranquilTeal)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Settings Saved", isPresented: $showingSaved) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your notification preferences have been saved")
        }
        .onAppear {
            loadPreferences()
        }
    }

    // MARK: - Helper Methods

    private func loadPreferences() {
        // TODO: Load from UserDefaults or repository
        // For now, using default preferences
    }

    private func savePreferences() {
        // TODO: Save to UserDefaults or repository
        UserDefaults.standard.set(try? JSONEncoder().encode(preferences), forKey: "notification_preferences")

        AuditLogger.shared.log(
            event: .userAction,
            details: "Notification preferences updated"
        )

        showingSaved = true
    }
}

// MARK: - Best Practice Row

struct BestPracticeRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.tranquilTeal)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Client-Specific Preferences

struct ClientNotificationPreferencesView: View {
    let clientId: UUID
    let clientName: String

    @State private var preferences = NotificationPreferences()
    @State private var showingSaved = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.tranquilTeal)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(clientName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Notification Preferences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Communication Channels
            Section("Preferred Channels") {
                Toggle(isOn: $preferences.emailEnabled) {
                    Label("Email", systemImage: "envelope.fill")
                }

                Toggle(isOn: $preferences.smsEnabled) {
                    Label("SMS", systemImage: "message.fill")
                }
            }

            // Reminder Preferences
            if preferences.emailEnabled || preferences.smsEnabled {
                Section("Appointment Reminders") {
                    Toggle(isOn: $preferences.appointmentReminders) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Reminders")
                            Text("Send automatic appointment reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if preferences.appointmentReminders {
                        if preferences.emailEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Timing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ForEach([ReminderTiming.oneDayBefore, .twoDaysBefore, .oneWeekBefore], id: \.self) { timing in
                                    Toggle(isOn: Binding(
                                        get: { preferences.emailReminders.contains(timing) },
                                        set: { isEnabled in
                                            if isEnabled {
                                                preferences.emailReminders.append(timing)
                                            } else {
                                                preferences.emailReminders.removeAll { $0 == timing }
                                            }
                                        }
                                    )) {
                                        Text(timing.displayName)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }

                        if preferences.smsEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SMS Timing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ForEach([ReminderTiming.oneHourBefore, .oneDayBefore], id: \.self) { timing in
                                    Toggle(isOn: Binding(
                                        get: { preferences.smsReminders.contains(timing) },
                                        set: { isEnabled in
                                            if isEnabled {
                                                preferences.smsReminders.append(timing)
                                            } else {
                                                preferences.smsReminders.removeAll { $0 == timing }
                                            }
                                        }
                                    )) {
                                        Text(timing.displayName)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Other Message Types
            Section("Other Notifications") {
                Toggle(isOn: $preferences.appointmentConfirmations) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confirmations")
                        Text("When appointment is booked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle(isOn: $preferences.followUpMessages) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Follow-ups")
                        Text("After appointment check-ins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle(isOn: $preferences.birthdayGreetings) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Birthday Wishes")
                        Text("Special birthday greetings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle(isOn: $preferences.promotionalMessages) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Promotions")
                        Text("Special offers and updates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Quiet Hours
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Quiet Hours", isOn: .constant(false))
                        .disabled(true) // TODO: Implement

                    Text("Coming soon: Set hours when notifications won't be sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Quiet Hours")
            }

            // Save Button
            Section {
                Button(action: savePreferences) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Preferences")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tranquilTeal)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Client Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Preferences Saved", isPresented: $showingSaved) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Notification preferences for \(clientName) have been saved")
        }
        .onAppear {
            loadPreferences()
        }
    }

    // MARK: - Helper Methods

    private func loadPreferences() {
        // TODO: Load client-specific preferences from repository
    }

    private func savePreferences() {
        // TODO: Save to repository
        AuditLogger.shared.log(
            event: .userAction,
            details: "Client notification preferences updated for \(clientName)"
        )

        showingSaved = true
    }
}

// MARK: - Preview Helper

#Preview("Global Preferences") {
    NavigationView {
        NotificationPreferencesView()
    }
}

#Preview("Client Preferences") {
    NavigationView {
        ClientNotificationPreferencesView(
            clientId: UUID(),
            clientName: "John Doe"
        )
    }
}

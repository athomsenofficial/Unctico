// ReminderManager.swift
// Handles appointment reminders via email and SMS

import Foundation
import UserNotifications

/// Manages appointment reminders
/// Sends reminders via push notifications, email, and SMS
class ReminderManager: ObservableObject {

    // MARK: - Published Properties

    /// Are reminders enabled?
    @Published var remindersEnabled: Bool = true

    /// Default reminder time (hours before appointment)
    @Published var defaultReminderHours: Int = 24

    // MARK: - Singleton

    static let shared = ReminderManager()

    private init() {
        requestNotificationPermissions()
    }

    // MARK: - Notification Permissions

    /// Request permission for local notifications
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted")
            }
        }
    }

    // MARK: - Schedule Reminders

    /// Schedule a reminder for an appointment
    /// - Parameters:
    ///   - appointment: The appointment to remind about
    ///   - client: The client for the appointment
    func scheduleReminder(for appointment: Appointment, client: Client) {
        guard remindersEnabled else { return }

        // Schedule local notification
        scheduleLocalNotification(for: appointment, client: client)

        // TODO: Schedule email reminder (when backend is available)
        // TODO: Schedule SMS reminder (when Twilio integration is added)
    }

    /// Schedule a local push notification
    private func scheduleLocalNotification(for appointment: Appointment, client: Client) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Appointment"
        content.body = "\(client.fullName) - \(appointment.serviceType.rawValue) at \(appointment.timeRangeDisplay)"
        content.sound = .default
        content.badge = 1

        // Add appointment info to user info
        content.userInfo = [
            "appointmentId": appointment.id.uuidString,
            "clientId": client.id.uuidString
        ]

        // Calculate trigger time (24 hours before by default)
        let reminderDate = Calendar.current.date(
            byAdding: .hour,
            value: -defaultReminderHours,
            to: appointment.startDateTime
        ) ?? appointment.startDateTime

        // Only schedule if reminder is in the future
        guard reminderDate > Date() else { return }

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create unique identifier
        let identifier = "appointment-\(appointment.id.uuidString)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled notification for appointment \(appointment.id)")
            }
        }
    }

    /// Cancel a reminder for an appointment
    /// - Parameter appointmentId: ID of the appointment
    func cancelReminder(for appointmentId: UUID) {
        let identifier = "appointment-\(appointmentId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all pending reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Email Reminders

    /// Send email reminder (requires backend)
    /// - Parameters:
    ///   - appointment: The appointment
    ///   - client: The client
    ///   - email: Client's email address
    func sendEmailReminder(for appointment: Appointment, client: Client, email: String) async {
        // TODO: Implement when backend API is available
        // This would call your backend to send an email via SendGrid, AWS SES, etc.

        let emailBody = generateEmailBody(for: appointment, client: client)

        print("📧 Would send email reminder to: \(email)")
        print("Subject: Appointment Reminder - \(appointment.serviceType.rawValue)")
        print("Body: \(emailBody)")

        // Example API call (to be implemented):
        // let endpoint = "https://api.yourbackend.com/reminders/email"
        // let payload = [
        //     "to": email,
        //     "subject": "Appointment Reminder",
        //     "body": emailBody
        // ]
        // try await sendEmailRequest(to: endpoint, payload: payload)
    }

    /// Generate email body content
    private func generateEmailBody(for appointment: Appointment, client: Client) -> String {
        return """
        Hi \(client.firstName),

        This is a friendly reminder about your upcoming massage appointment:

        Date: \(appointment.startDateTime.formatted(date: .complete, time: .omitted))
        Time: \(appointment.timeRangeDisplay)
        Service: \(appointment.serviceType.rawValue)
        Duration: \(appointment.durationMinutes) minutes

        We look forward to seeing you!

        If you need to reschedule or cancel, please contact us as soon as possible.

        Thank you!
        """
    }

    // MARK: - SMS Reminders

    /// Send SMS reminder (requires Twilio or similar)
    /// - Parameters:
    ///   - appointment: The appointment
    ///   - client: The client
    ///   - phoneNumber: Client's phone number
    func sendSMSReminder(for appointment: Appointment, client: Client, phoneNumber: String) async {
        // TODO: Implement when Twilio integration is added

        let smsBody = generateSMSBody(for: appointment, client: client)

        print("📱 Would send SMS reminder to: \(phoneNumber)")
        print("Message: \(smsBody)")

        // Example Twilio integration (to be implemented):
        // let twilioEndpoint = "https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT_SID/Messages.json"
        // try await sendTwilioSMS(to: phoneNumber, body: smsBody)
    }

    /// Generate SMS body content (must be concise)
    private func generateSMSBody(for appointment: Appointment, client: Client) -> String {
        let date = appointment.startDateTime.formatted(date: .abbreviated, time: .omitted)
        let time = appointment.startDateTime.formatted(date: .omitted, time: .shortened)

        return "Reminder: \(appointment.serviceType.rawValue) on \(date) at \(time). Reply YES to confirm."
    }

    // MARK: - Batch Reminder Processing

    /// Process all appointments that need reminders sent
    /// Call this periodically (e.g., every hour)
    /// - Parameter appointments: All upcoming appointments
    func processReminders(for appointments: [Appointment]) async {
        for appointment in appointments {
            if appointment.shouldSendReminder {
                // TODO: Get client info and send reminders
                print("⏰ Appointment \(appointment.id) needs reminder sent")

                // Mark reminder as sent (this would be done in AppointmentManager)
                // appointmentManager.markReminderSent(appointment.id)
            }
        }
    }

    // MARK: - Reminder Preferences

    /// Reminder preference for a client
    struct ReminderPreference: Codable {
        var enableEmailReminders: Bool
        var enableSMSReminders: Bool
        var enablePushReminders: Bool
        var reminderHoursBefore: [Int] // e.g., [24, 1] for 24 hours and 1 hour before

        init() {
            self.enableEmailReminders = true
            self.enableSMSReminders = true
            self.enablePushReminders = true
            self.reminderHoursBefore = [24] // Default to 24 hours before
        }
    }

    /// Get reminder preference for a client (from database)
    /// - Parameter clientId: Client ID
    /// - Returns: Reminder preferences
    func getReminderPreference(for clientId: UUID) -> ReminderPreference {
        // TODO: Load from database
        return ReminderPreference()
    }

    /// Save reminder preference for a client
    /// - Parameters:
    ///   - preference: The preference to save
    ///   - clientId: Client ID
    func saveReminderPreference(_ preference: ReminderPreference, for clientId: UUID) {
        // TODO: Save to database
        print("💾 Saving reminder preferences for client \(clientId)")
    }
}

// MARK: - Notification Delegate (for app delegate)

/// Extension with helpful methods for handling notification responses
extension ReminderManager {

    /// Handle notification response (when user taps notification)
    /// - Parameter response: The notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        if let appointmentIdString = userInfo["appointmentId"] as? String,
           let appointmentId = UUID(uuidString: appointmentIdString) {

            print("📱 User tapped notification for appointment: \(appointmentId)")

            // TODO: Navigate to appointment detail view
            // This would typically post a notification that the app coordinator listens to
            NotificationCenter.default.post(
                name: Notification.Name("OpenAppointment"),
                object: nil,
                userInfo: ["appointmentId": appointmentId]
            )
        }
    }

    /// Get all pending notification requests (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Get count of pending reminders
    func getPendingReminderCount() async -> Int {
        let requests = await getPendingNotifications()
        return requests.filter { $0.identifier.starts(with: "appointment-") }.count
    }
}

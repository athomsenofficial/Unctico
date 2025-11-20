import Combine
import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Appointment Reminders

    func scheduleAppointmentReminder(for appointment: Appointment, client: Client, hoursBeforearray: [Int] = [24, 2]) {
        guard isAuthorized else { return }

        for hours in hoursBeforearray {
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -hours, to: appointment.startTime)

            guard let notificationDate = notificationDate, notificationDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Upcoming Appointment"
            content.body = "\(client.fullName) - \(appointment.serviceType.rawValue) in \(hours) hour\(hours > 1 ? "s" : "")"
            content.sound = .default
            content.categoryIdentifier = "APPOINTMENT_REMINDER"
            content.userInfo = [
                "appointmentId": appointment.id.uuidString,
                "clientId": client.id.uuidString
            ]

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let identifier = "appointment_\(appointment.id.uuidString)_\(hours)h"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }

    // MARK: - Payment Reminders

    func schedulePaymentReminder(for invoice: Invoice, client: Client) {
        guard isAuthorized else { return }

        // Reminder 3 days before due date
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: invoice.dueDate),
           reminderDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Payment Due Soon"
            content.body = "Invoice \(invoice.invoiceNumber) for \(client.fullName) is due in 3 days. Amount: $\(String(format: "%.2f", invoice.balanceDue))"
            content.sound = .default

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(identifier: "invoice_\(invoice.id.uuidString)_reminder", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }

        // Overdue notification on due date
        let content = UNMutableNotificationContent()
        content.title = "Invoice Due Today"
        content.body = "Invoice \(invoice.invoiceNumber) for \(client.fullName) is due today. Amount: $\(String(format: "%.2f", invoice.balanceDue))"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: invoice.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "invoice_\(invoice.id.uuidString)_due", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - License Renewal Reminders

    func scheduleLicenseRenewalReminder(expirationDate: Date, licenseName: String) {
        guard isAuthorized else { return }

        let reminderDays = [90, 60, 30, 7]

        for days in reminderDays {
            if let reminderDate = Calendar.current.date(byAdding: .day, value: -days, to: expirationDate),
               reminderDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "License Renewal Reminder"
                content.body = "Your \(licenseName) expires in \(days) days. Don't forget to renew!"
                content.sound = .default
                content.categoryIdentifier = "LICENSE_RENEWAL"

                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                let identifier = "license_\(licenseName)_\(days)d"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    // MARK: - Cancel Notifications

    func cancelAppointmentReminders(for appointmentId: UUID) {
        let identifiers = [
            "appointment_\(appointmentId.uuidString)_24h",
            "appointment_\(appointmentId.uuidString)_2h"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelInvoiceReminders(for invoiceId: UUID) {
        let identifiers = [
            "invoice_\(invoiceId.uuidString)_reminder",
            "invoice_\(invoiceId.uuidString)_due"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Email/SMS Service (Placeholder)

class CommunicationService {
    static let shared = CommunicationService()

    private init() {}

    // MARK: - Email

    func sendEmail(
        to email: String,
        subject: String,
        body: String,
        attachmentURL: URL? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // In production, integrate with:
        // - SendGrid
        // - Mailgun
        // - AWS SES
        // - Twilio SendGrid

        print("📧 Sending email to: \(email)")
        print("Subject: \(subject)")
        print("Body: \(body)")

        // Simulate email sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(()))
        }
    }

    // MARK: - SMS

    func sendSMS(
        to phoneNumber: String,
        message: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // In production, integrate with:
        // - Twilio
        // - AWS SNS
        // - MessageBird

        print("📱 Sending SMS to: \(phoneNumber)")
        print("Message: \(message)")

        // Simulate SMS sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(()))
        }
    }

    // MARK: - Appointment Confirmation

    func sendAppointmentConfirmation(appointment: Appointment, client: Client) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        let message = """
        Hi \(client.firstName),

        Your appointment is confirmed!

        Service: \(appointment.serviceType.rawValue)
        Date & Time: \(formatter.string(from: appointment.startTime))

        See you soon!
        """

        if let email = client.email {
            sendEmail(to: email, subject: "Appointment Confirmation", body: message) { _ in }
        }

        if let phone = client.phone,
           client.preferences.communicationMethod == .sms {
            let smsMessage = "Appointment confirmed: \(appointment.serviceType.rawValue) on \(formatter.string(from: appointment.startTime))"
            sendSMS(to: phone, message: smsMessage) { _ in }
        }
    }

    // MARK: - Invoice Delivery

    func sendInvoice(invoice: Invoice, client: Client, pdfURL: URL) {
        guard let email = client.email else { return }

        let message = """
        Hi \(client.firstName),

        Please find attached your invoice #\(invoice.invoiceNumber).

        Amount Due: $\(String(format: "%.2f", invoice.balanceDue))
        Due Date: \(invoice.dueDate.formatted(date: .long, time: .omitted))

        Thank you for your business!
        """

        sendEmail(to: email, subject: "Invoice \(invoice.invoiceNumber)", body: message, attachmentURL: pdfURL) { _ in }
    }
}

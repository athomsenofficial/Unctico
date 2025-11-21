import Foundation
import CryptoKit

/// Service for client portal operations
@MainActor
class ClientPortalService: ObservableObject {
    static let shared = ClientPortalService()

    @Published var currentSession: ClientPortalSession?
    @Published var portalConfiguration = ClientPortalConfiguration()

    init() {
        // Initialize service
    }

    // MARK: - Authentication

    /// Create portal account for client
    func createPortalAccount(
        clientId: UUID,
        email: String,
        password: String
    ) -> ClientPortalAccount {
        let passwordHash = hashPassword(password)

        return ClientPortalAccount(
            clientId: clientId,
            email: email,
            passwordHash: passwordHash
        )
    }

    /// Authenticate client and create session
    func authenticate(
        email: String,
        password: String,
        account: ClientPortalAccount
    ) -> ClientPortalSession? {
        // Verify password
        guard verifyPassword(password, hash: account.passwordHash) else {
            return nil
        }

        // Check if account is active
        guard account.isActive else {
            return nil
        }

        // Create session
        let session = ClientPortalSession(
            accountId: account.id,
            clientId: account.clientId,
            sessionToken: generateSessionToken()
        )

        currentSession = session
        return session
    }

    /// Validate session token
    func validateSession(_ session: ClientPortalSession) -> Bool {
        return session.isActive && !session.isExpired
    }

    /// Logout and invalidate session
    func logout(session: ClientPortalSession) -> ClientPortalSession {
        var updatedSession = session
        updatedSession.isActive = false
        currentSession = nil
        return updatedSession
    }

    private func hashPassword(_ password: String) -> String {
        // In production, use proper password hashing (bcrypt, Argon2, etc.)
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func verifyPassword(_ password: String, hash: String) -> Bool {
        return hashPassword(password) == hash
    }

    private func generateSessionToken() -> String {
        return UUID().uuidString
    }

    // MARK: - Online Booking

    /// Find available slots for a service
    func findAvailableSlots(
        serviceId: UUID,
        serviceDuration: TimeInterval,
        therapistId: UUID?,
        date: Date,
        staff: [StaffMember],
        appointments: [Appointment],
        scheduleEntries: [StaffScheduleEntry]
    ) -> [TimeSlot] {
        var allAvailableSlots: [TimeSlot] = []

        // Determine which therapists to check
        let therapistsToCheck: [StaffMember]
        if let specificTherapist = therapistId,
           let therapist = staff.first(where: { $0.id == specificTherapist }) {
            therapistsToCheck = [therapist]
        } else {
            // Check all active therapists
            therapistsToCheck = staff.filter { $0.isActive && $0.role.canProvideServices }
        }

        let staffService = StaffService.shared

        for therapist in therapistsToCheck {
            // Get schedule for this therapist on this date
            let schedule = scheduleEntries.first { entry in
                entry.staffId == therapist.id &&
                Calendar.current.isDate(entry.date, inSameDayAs: date)
            }

            let slots = staffService.findAvailableSlots(
                staffId: therapist.id,
                date: date,
                serviceDuration: serviceDuration,
                staff: therapist,
                existingAppointments: appointments,
                scheduleEntry: schedule
            )

            allAvailableSlots.append(contentsOf: slots)
        }

        // Remove duplicates and sort by time
        let uniqueSlots = Array(Set(allAvailableSlots.map { $0.startTime }))
            .sorted()
            .map { startTime in
                TimeSlot(
                    startTime: startTime,
                    endTime: startTime.addingTimeInterval(serviceDuration)
                )
            }

        return uniqueSlots
    }

    /// Create booking request
    func createBookingRequest(
        clientId: UUID,
        serviceId: UUID,
        serviceName: String,
        therapistId: UUID?,
        therapistName: String?,
        preferredDate: Date,
        preferredTime: Date,
        duration: TimeInterval,
        notes: String = ""
    ) -> OnlineBookingRequest {
        return OnlineBookingRequest(
            clientId: clientId,
            serviceId: serviceId,
            serviceName: serviceName,
            therapistId: therapistId,
            therapistName: therapistName,
            preferredDate: preferredDate,
            preferredTime: preferredTime,
            duration: duration,
            notes: notes
        )
    }

    /// Confirm booking request and create appointment
    func confirmBookingRequest(
        request: OnlineBookingRequest,
        processedBy: UUID
    ) -> (updatedRequest: OnlineBookingRequest, appointment: Appointment) {
        // Create appointment
        let appointment = Appointment(
            clientId: request.clientId,
            serviceId: request.serviceId,
            therapistId: request.therapistId ?? UUID(),
            dateTime: request.preferredTime,
            duration: request.duration,
            status: .scheduled
        )

        // Update request
        var updatedRequest = request
        updatedRequest.status = .confirmed
        updatedRequest.processedDate = Date()
        updatedRequest.processedBy = processedBy
        updatedRequest.appointmentId = appointment.id

        return (updatedRequest, appointment)
    }

    /// Check if booking is allowed based on cancellation policy
    func canCancelAppointment(
        appointment: Appointment,
        hoursNotice: Int
    ) -> Bool {
        let hoursUntilAppointment = appointment.dateTime.timeIntervalSinceNow / 3600
        return hoursUntilAppointment >= Double(hoursNotice)
    }

    /// Check if reschedule is allowed
    func canRescheduleAppointment(
        appointment: Appointment,
        hoursNotice: Int
    ) -> Bool {
        return canCancelAppointment(appointment: appointment, hoursNotice: hoursNotice)
    }

    // MARK: - Notifications

    /// Create notification for client
    func createNotification(
        clientId: UUID,
        type: NotificationType,
        title: String,
        message: String,
        actionUrl: String? = nil,
        expirationDate: Date? = nil
    ) -> ClientNotification {
        return ClientNotification(
            clientId: clientId,
            notificationType: type,
            title: title,
            message: message,
            actionUrl: actionUrl,
            expirationDate: expirationDate
        )
    }

    /// Create appointment confirmation notification
    func createAppointmentConfirmationNotification(
        clientId: UUID,
        appointment: Appointment,
        serviceName: String
    ) -> ClientNotification {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let message = "Your appointment for \(serviceName) on \(dateFormatter.string(from: appointment.dateTime)) has been confirmed."

        return createNotification(
            clientId: clientId,
            type: .appointmentConfirmed,
            title: "Appointment Confirmed",
            message: message,
            actionUrl: "/appointments/\(appointment.id)"
        )
    }

    /// Create appointment reminder notification
    func createAppointmentReminderNotification(
        clientId: UUID,
        appointment: Appointment,
        serviceName: String
    ) -> ClientNotification {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let message = "Reminder: You have an appointment for \(serviceName) on \(dateFormatter.string(from: appointment.dateTime))."

        let expirationDate = appointment.dateTime.addingTimeInterval(3600) // Expires 1 hour after appointment

        return createNotification(
            clientId: clientId,
            type: .appointmentReminder,
            title: "Upcoming Appointment",
            message: message,
            actionUrl: "/appointments/\(appointment.id)",
            expirationDate: expirationDate
        )
    }

    // MARK: - Documents

    /// Share document with client
    func shareDocumentWithClient(
        document: ClientDocument
    ) -> ClientDocument {
        var updatedDocument = document
        updatedDocument.isSharedWithClient = true
        return updatedDocument
    }

    /// Sign document
    func signDocument(
        document: ClientDocument
    ) -> ClientDocument {
        var updatedDocument = document
        updatedDocument.signedDate = Date()
        return updatedDocument
    }

    /// Check if client has unsigned documents
    func hasUnsignedDocuments(_ documents: [ClientDocument]) -> Bool {
        return documents.contains { $0.requiresSignature && !$0.isSigned }
    }

    // MARK: - Packages

    /// Use session from package
    func usePackageSession(
        package: ClientPackage,
        appointmentId: UUID
    ) -> ClientPackage {
        var updatedPackage = package
        updatedPackage.remainingSessions = max(0, package.remainingSessions - 1)
        return updatedPackage
    }

    /// Check if package can be used for service
    func canUsePackage(
        package: ClientPackage,
        serviceId: UUID
    ) -> Bool {
        return package.isActive &&
               !package.isExpired &&
               package.remainingSessions > 0 &&
               (package.services.isEmpty || package.services.contains(serviceId))
    }

    /// Calculate package savings
    func calculatePackageSavings(
        package: ClientPackage,
        regularPricePerSession: Double
    ) -> Double {
        let regularTotal = regularPricePerSession * Double(package.totalSessions)
        let savings = regularTotal - package.price
        return max(0, savings)
    }

    // MARK: - Referrals

    /// Create referral
    func createReferral(
        referrerId: UUID,
        referredName: String,
        referredEmail: String,
        referredPhone: String = "",
        rewardType: ReferralRewardType = .discount,
        rewardAmount: Double = 0
    ) -> ClientReferral {
        return ClientReferral(
            referrerId: referrerId,
            referredName: referredName,
            referredEmail: referredEmail,
            referredPhone: referredPhone,
            rewardType: rewardType,
            rewardAmount: rewardAmount
        )
    }

    /// Convert referral when referred client books
    func convertReferral(
        referral: ClientReferral,
        referredClientId: UUID
    ) -> ClientReferral {
        var updatedReferral = referral
        updatedReferral.status = .converted
        updatedReferral.referredClientId = referredClientId
        updatedReferral.convertedDate = Date()
        return updatedReferral
    }

    /// Issue referral reward
    func issueReferralReward(
        referral: ClientReferral
    ) -> ClientReferral {
        var updatedReferral = referral
        updatedReferral.rewardIssued = true
        return updatedReferral
    }

    /// Calculate referral conversion rate
    func calculateReferralConversionRate(
        referrals: [ClientReferral]
    ) -> Double {
        guard !referrals.isEmpty else { return 0 }
        let converted = referrals.filter { $0.status == .converted }.count
        return Double(converted) / Double(referrals.count) * 100
    }

    // MARK: - Portal Statistics

    /// Calculate portal statistics
    func calculatePortalStatistics(
        accounts: [ClientPortalAccount],
        sessions: [ClientPortalSession],
        bookings: [OnlineBookingRequest]
    ) -> ClientPortalStatistics {
        let totalAccounts = accounts.count
        let activeAccounts = accounts.filter { $0.isActive }.count

        let totalSessions = sessions.count
        let activeSessions = sessions.filter { $0.isActive && !$0.isExpired }.count

        let onlineBookings = bookings.count
        let pendingBookings = bookings.filter { $0.isPending }.count

        // Calculate average session duration
        let sessionDurations = sessions.map { session in
            session.lastActivityDate.timeIntervalSince(session.startDate)
        }
        let averageDuration = sessionDurations.isEmpty ? 0 : sessionDurations.reduce(0, +) / Double(sessionDurations.count)

        return ClientPortalStatistics(
            totalAccounts: totalAccounts,
            activeAccounts: activeAccounts,
            totalSessions: totalSessions,
            activeSessions: activeSessions,
            onlineBookings: onlineBookings,
            pendingBookings: pendingBookings,
            formCompletions: 0, // Would need form completion data
            averageSessionDuration: averageDuration
        )
    }

    // MARK: - Portal Configuration

    /// Update portal configuration
    func updatePortalConfiguration(
        _ configuration: ClientPortalConfiguration
    ) {
        portalConfiguration = configuration
    }

    /// Check if online booking is allowed
    func isOnlineBookingAllowed() -> Bool {
        return portalConfiguration.isEnabled && portalConfiguration.allowOnlineBooking
    }

    /// Check if self registration is allowed
    func isSelfRegistrationAllowed() -> Bool {
        return portalConfiguration.isEnabled && portalConfiguration.allowSelfRegistration
    }

    /// Get booking advance limit date
    func getBookingAdvanceLimit() -> Date {
        return Calendar.current.date(
            byAdding: .day,
            value: portalConfiguration.bookingAdvanceDays,
            to: Date()
        ) ?? Date()
    }

    // MARK: - Activity Tracking

    /// Update session activity
    func updateSessionActivity(
        session: ClientPortalSession
    ) -> ClientPortalSession {
        var updatedSession = session
        updatedSession.lastActivityDate = Date()
        return updatedSession
    }

    /// Generate client activity summary
    func generateActivitySummary(
        clientId: UUID,
        appointments: [Appointment],
        bookings: [OnlineBookingRequest],
        documents: [ClientDocument],
        notifications: [ClientNotification]
    ) -> ClientActivitySummary {
        let upcomingAppointments = appointments.filter {
            $0.clientId == clientId &&
            $0.dateTime > Date() &&
            $0.status == .scheduled
        }.count

        let pastAppointments = appointments.filter {
            $0.clientId == clientId &&
            $0.dateTime <= Date() &&
            $0.status == .completed
        }.count

        let pendingBookings = bookings.filter {
            $0.clientId == clientId && $0.isPending
        }.count

        let unsignedDocuments = documents.filter {
            $0.clientId == clientId &&
            $0.requiresSignature &&
            !$0.isSigned
        }.count

        let unreadNotifications = notifications.filter {
            $0.clientId == clientId &&
            !$0.isRead &&
            !$0.isExpired
        }.count

        return ClientActivitySummary(
            upcomingAppointments: upcomingAppointments,
            pastAppointments: pastAppointments,
            pendingBookings: pendingBookings,
            unsignedDocuments: unsignedDocuments,
            unreadNotifications: unreadNotifications
        )
    }
}

// MARK: - Supporting Types

struct ClientActivitySummary {
    let upcomingAppointments: Int
    let pastAppointments: Int
    let pendingBookings: Int
    let unsignedDocuments: Int
    let unreadNotifications: Int

    var hasActionItems: Bool {
        pendingBookings > 0 || unsignedDocuments > 0
    }
}

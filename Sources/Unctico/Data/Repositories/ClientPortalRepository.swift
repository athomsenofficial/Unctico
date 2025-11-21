import Foundation
import Combine

/// Repository for client portal data
@MainActor
class ClientPortalRepository: ObservableObject {
    static let shared = ClientPortalRepository()

    @Published var accounts: [ClientPortalAccount] = []
    @Published var sessions: [ClientPortalSession] = []
    @Published var bookingRequests: [OnlineBookingRequest] = []
    @Published var notifications: [ClientNotification] = []
    @Published var documents: [ClientDocument] = []
    @Published var packages: [ClientPackage] = []
    @Published var referrals: [ClientReferral] = []
    @Published var configuration = ClientPortalConfiguration()

    private let accountsKey = "portal_accounts"
    private let sessionsKey = "portal_sessions"
    private let bookingRequestsKey = "booking_requests"
    private let notificationsKey = "portal_notifications"
    private let documentsKey = "client_documents"
    private let packagesKey = "client_packages"
    private let referralsKey = "client_referrals"
    private let configKey = "portal_configuration"

    init() {
        loadData()
    }

    // MARK: - Account Management

    func addAccount(_ account: ClientPortalAccount) {
        accounts.append(account)
        saveAccounts()
    }

    func updateAccount(_ account: ClientPortalAccount) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }

    func deleteAccount(_ account: ClientPortalAccount) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }

    func getAccount(id: UUID) -> ClientPortalAccount? {
        accounts.first { $0.id == id }
    }

    func getAccount(clientId: UUID) -> ClientPortalAccount? {
        accounts.first { $0.clientId == clientId }
    }

    func getAccount(email: String) -> ClientPortalAccount? {
        accounts.first { $0.email.lowercased() == email.lowercased() }
    }

    func getActiveAccounts() -> [ClientPortalAccount] {
        accounts.filter { $0.isActive }
    }

    func updateLastLogin(accountId: UUID) {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].lastLoginDate = Date()
            saveAccounts()
        }
    }

    // MARK: - Session Management

    func addSession(_ session: ClientPortalSession) {
        sessions.append(session)
        saveSessions()
    }

    func updateSession(_ session: ClientPortalSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }

    func deleteSession(_ session: ClientPortalSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func getSession(token: String) -> ClientPortalSession? {
        sessions.first { $0.sessionToken == token && $0.isActive && !$0.isExpired }
    }

    func getActiveSessions(clientId: UUID) -> [ClientPortalSession] {
        sessions.filter { $0.clientId == clientId && $0.isActive && !$0.isExpired }
    }

    func expireOldSessions() {
        for (index, session) in sessions.enumerated() {
            if session.isExpired && session.isActive {
                sessions[index].isActive = false
            }
        }
        saveSessions()
    }

    // MARK: - Booking Request Management

    func addBookingRequest(_ request: OnlineBookingRequest) {
        bookingRequests.append(request)
        saveBookingRequests()
    }

    func updateBookingRequest(_ request: OnlineBookingRequest) {
        if let index = bookingRequests.firstIndex(where: { $0.id == request.id }) {
            bookingRequests[index] = request
            saveBookingRequests()
        }
    }

    func deleteBookingRequest(_ request: OnlineBookingRequest) {
        bookingRequests.removeAll { $0.id == request.id }
        saveBookingRequests()
    }

    func getBookingRequest(id: UUID) -> OnlineBookingRequest? {
        bookingRequests.first { $0.id == id }
    }

    func getPendingBookingRequests() -> [OnlineBookingRequest] {
        bookingRequests.filter { $0.isPending }.sorted { $0.createdDate > $1.createdDate }
    }

    func getClientBookingRequests(clientId: UUID) -> [OnlineBookingRequest] {
        bookingRequests.filter { $0.clientId == clientId }.sorted { $0.createdDate > $1.createdDate }
    }

    // MARK: - Notification Management

    func addNotification(_ notification: ClientNotification) {
        notifications.append(notification)
        saveNotifications()
    }

    func updateNotification(_ notification: ClientNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
            saveNotifications()
        }
    }

    func deleteNotification(_ notification: ClientNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }

    func getClientNotifications(clientId: UUID) -> [ClientNotification] {
        notifications.filter {
            $0.clientId == clientId && !$0.isExpired
        }.sorted { $0.createdDate > $1.createdDate }
    }

    func getUnreadNotifications(clientId: UUID) -> [ClientNotification] {
        notifications.filter {
            $0.clientId == clientId && !$0.isRead && !$0.isExpired
        }.sorted { $0.createdDate > $1.createdDate }
    }

    func markNotificationAsRead(notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }

    func markAllNotificationsAsRead(clientId: UUID) {
        for (index, notification) in notifications.enumerated() {
            if notification.clientId == clientId && !notification.isRead {
                notifications[index].isRead = true
            }
        }
        saveNotifications()
    }

    func deleteExpiredNotifications() {
        notifications.removeAll { $0.isExpired }
        saveNotifications()
    }

    // MARK: - Document Management

    func addDocument(_ document: ClientDocument) {
        documents.append(document)
        saveDocuments()
    }

    func updateDocument(_ document: ClientDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            saveDocuments()
        }
    }

    func deleteDocument(_ document: ClientDocument) {
        documents.removeAll { $0.id == document.id }
        saveDocuments()
    }

    func getClientDocuments(clientId: UUID, sharedOnly: Bool = false) -> [ClientDocument] {
        var clientDocs = documents.filter { $0.clientId == clientId }

        if sharedOnly {
            clientDocs = clientDocs.filter { $0.isSharedWithClient }
        }

        return clientDocs.sorted { $0.uploadDate > $1.uploadDate }
    }

    func getUnsignedDocuments(clientId: UUID) -> [ClientDocument] {
        documents.filter {
            $0.clientId == clientId &&
            $0.requiresSignature &&
            !$0.isSigned &&
            $0.isSharedWithClient
        }
    }

    // MARK: - Package Management

    func addPackage(_ package: ClientPackage) {
        packages.append(package)
        savePackages()
    }

    func updatePackage(_ package: ClientPackage) {
        if let index = packages.firstIndex(where: { $0.id == package.id }) {
            packages[index] = package
            savePackages()
        }
    }

    func deletePackage(_ package: ClientPackage) {
        packages.removeAll { $0.id == package.id }
        savePackages()
    }

    func getClientPackages(clientId: UUID, activeOnly: Bool = false) -> [ClientPackage] {
        var clientPackages = packages.filter { $0.clientId == clientId }

        if activeOnly {
            clientPackages = clientPackages.filter {
                $0.isActive && !$0.isExpired && $0.remainingSessions > 0
            }
        }

        return clientPackages.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    func getExpiringPackages(clientId: UUID) -> [ClientPackage] {
        packages.filter {
            $0.clientId == clientId && $0.isExpiringSoon
        }
    }

    // MARK: - Referral Management

    func addReferral(_ referral: ClientReferral) {
        referrals.append(referral)
        saveReferrals()
    }

    func updateReferral(_ referral: ClientReferral) {
        if let index = referrals.firstIndex(where: { $0.id == referral.id }) {
            referrals[index] = referral
            saveReferrals()
        }
    }

    func deleteReferral(_ referral: ClientReferral) {
        referrals.removeAll { $0.id == referral.id }
        saveReferrals()
    }

    func getClientReferrals(clientId: UUID) -> [ClientReferral] {
        referrals.filter { $0.referrerId == clientId }.sorted { $0.referralDate > $1.referralDate }
    }

    func getPendingReferrals() -> [ClientReferral] {
        referrals.filter { $0.status == .pending }
    }

    func getConvertedReferrals(clientId: UUID) -> [ClientReferral] {
        referrals.filter { $0.referrerId == clientId && $0.status == .converted }
    }

    // MARK: - Configuration

    func updateConfiguration(_ config: ClientPortalConfiguration) {
        configuration = config
        saveConfiguration()
    }

    func getConfiguration() -> ClientPortalConfiguration {
        return configuration
    }

    // MARK: - Combined Operations

    /// Create account and session for new client
    func createAccountAndSession(
        clientId: UUID,
        email: String,
        password: String
    ) -> (account: ClientPortalAccount, session: ClientPortalSession) {
        let service = ClientPortalService.shared
        let account = service.createPortalAccount(
            clientId: clientId,
            email: email,
            password: password
        )

        addAccount(account)

        let session = service.authenticate(email: email, password: password, account: account)!
        addSession(session)
        updateLastLogin(accountId: account.id)

        return (account, session)
    }

    /// Create booking and notification
    func createBookingWithNotification(
        clientId: UUID,
        serviceId: UUID,
        serviceName: String,
        therapistId: UUID?,
        therapistName: String?,
        preferredDate: Date,
        preferredTime: Date,
        duration: TimeInterval,
        notes: String = ""
    ) -> (booking: OnlineBookingRequest, notification: ClientNotification) {
        let service = ClientPortalService.shared

        let booking = service.createBookingRequest(
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

        addBookingRequest(booking)

        let notification = service.createNotification(
            clientId: clientId,
            type: .appointmentConfirmed,
            title: "Booking Request Received",
            message: "We've received your booking request for \(serviceName). We'll confirm your appointment shortly."
        )

        addNotification(notification)

        return (booking, notification)
    }

    /// Confirm booking and create notification
    func confirmBookingRequest(
        requestId: UUID,
        processedBy: UUID
    ) -> (request: OnlineBookingRequest, appointment: Appointment, notification: ClientNotification)? {
        guard let request = getBookingRequest(id: requestId) else { return nil }

        let service = ClientPortalService.shared
        let (updatedRequest, appointment) = service.confirmBookingRequest(
            request: request,
            processedBy: processedBy
        )

        updateBookingRequest(updatedRequest)

        let notification = service.createAppointmentConfirmationNotification(
            clientId: request.clientId,
            appointment: appointment,
            serviceName: request.serviceName
        )

        addNotification(notification)

        return (updatedRequest, appointment, notification)
    }

    // MARK: - Statistics

    func getStatistics() -> ClientPortalStatistics {
        let service = ClientPortalService.shared
        return service.calculatePortalStatistics(
            accounts: accounts,
            sessions: sessions,
            bookings: bookingRequests
        )
    }

    // MARK: - Persistence

    private func loadData() {
        if let accountsData = UserDefaults.standard.data(forKey: accountsKey),
           let decodedAccounts = try? JSONDecoder().decode([ClientPortalAccount].self, from: accountsData) {
            accounts = decodedAccounts
        }

        if let sessionsData = UserDefaults.standard.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([ClientPortalSession].self, from: sessionsData) {
            sessions = decodedSessions
        }

        if let bookingsData = UserDefaults.standard.data(forKey: bookingRequestsKey),
           let decodedBookings = try? JSONDecoder().decode([OnlineBookingRequest].self, from: bookingsData) {
            bookingRequests = decodedBookings
        }

        if let notificationsData = UserDefaults.standard.data(forKey: notificationsKey),
           let decodedNotifications = try? JSONDecoder().decode([ClientNotification].self, from: notificationsData) {
            notifications = decodedNotifications
        }

        if let documentsData = UserDefaults.standard.data(forKey: documentsKey),
           let decodedDocuments = try? JSONDecoder().decode([ClientDocument].self, from: documentsData) {
            documents = decodedDocuments
        }

        if let packagesData = UserDefaults.standard.data(forKey: packagesKey),
           let decodedPackages = try? JSONDecoder().decode([ClientPackage].self, from: packagesData) {
            packages = decodedPackages
        }

        if let referralsData = UserDefaults.standard.data(forKey: referralsKey),
           let decodedReferrals = try? JSONDecoder().decode([ClientReferral].self, from: referralsData) {
            referrals = decodedReferrals
        }

        if let configData = UserDefaults.standard.data(forKey: configKey),
           let decodedConfig = try? JSONDecoder().decode(ClientPortalConfiguration.self, from: configData) {
            configuration = decodedConfig
        }
    }

    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    private func saveBookingRequests() {
        if let encoded = try? JSONEncoder().encode(bookingRequests) {
            UserDefaults.standard.set(encoded, forKey: bookingRequestsKey)
        }
    }

    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: notificationsKey)
        }
    }

    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: documentsKey)
        }
    }

    private func savePackages() {
        if let encoded = try? JSONEncoder().encode(packages) {
            UserDefaults.standard.set(encoded, forKey: packagesKey)
        }
    }

    private func saveReferrals() {
        if let encoded = try? JSONEncoder().encode(referrals) {
            UserDefaults.standard.set(encoded, forKey: referralsKey)
        }
    }

    private func saveConfiguration() {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        }
    }
}

import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var currentTab: MainTab = .dashboard
    @Published var selectedClient: Client?
    @Published var isAuthenticated = false

    // HIPAA Compliance
    let auditLogRepository = AuditLogRepository()
    lazy var hipaaComplianceService: HIPAAComplianceService = {
        HIPAAComplianceService(auditLogRepository: auditLogRepository)
    }()

    // Current user for audit logging
    var currentUserId: UUID = UUID()
    var currentUserName: String = "Admin User"

    enum MainTab {
        case dashboard
        case clients
        case schedule
        case documentation
        case financial
        case settings
    }
}

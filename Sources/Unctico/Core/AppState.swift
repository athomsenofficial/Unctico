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

    // Communication System
    let communicationService = CommunicationService.shared
    let communicationRepository = CommunicationRepository.shared

    // Tax Compliance System
    let taxService = TaxService.shared
    let taxRepository = TaxRepository.shared

    // Analytics & Reporting
    let analyticsService = AnalyticsService.shared

    // Inventory Management
    let inventoryService = InventoryService.shared
    let inventoryRepository = InventoryRepository.shared

    // Team & Staff Management
    let staffService = StaffService.shared
    let staffRepository = StaffRepository.shared

    // Marketing Automation
    let marketingService = MarketingService.shared
    let marketingRepository = MarketingRepository.shared

    enum MainTab {
        case dashboard
        case clients
        case schedule
        case documentation
        case financial
        case settings
    }
}

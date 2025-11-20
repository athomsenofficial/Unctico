import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var currentTab: MainTab = .dashboard
    @Published var selectedClient: Client?
    @Published var isAuthenticated = false

    enum MainTab {
        case dashboard
        case clients
        case schedule
        case documentation
        case financial
        case settings
    }
}

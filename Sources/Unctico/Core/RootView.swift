import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.currentTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(AppState.MainTab.dashboard)

            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: "person.2.fill")
                }
                .tag(AppState.MainTab.clients)

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(AppState.MainTab.schedule)

            DocumentationView()
                .tabItem {
                    Label("SOAP Notes", systemImage: "doc.text.fill")
                }
                .tag(AppState.MainTab.documentation)

            FinancialView()
                .tabItem {
                    Label("Financial", systemImage: "dollarsign.circle.fill")
                }
                .tag(AppState.MainTab.financial)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppState.MainTab.settings)
        }
        .accentColor(.massageTheme)
    }
}

// MainTabView.swift
// Main navigation with tab bar for different sections of the app

import SwiftUI

/// Main tab view with navigation to all major sections
struct MainTabView: View {

    // MARK: - Environment

    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var databaseManager: DatabaseManager

    // MARK: - Body

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: MainTab.dashboard.icon)
                }
                .tag(MainTab.dashboard)

            // Clients Tab
            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: MainTab.clients.icon)
                }
                .tag(MainTab.clients)

            // Schedule Tab
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: MainTab.schedule.icon)
                }
                .tag(MainTab.schedule)

            // SOAP Notes Tab
            SOAPNotesView()
                .tabItem {
                    Label("SOAP Notes", systemImage: MainTab.soapNotes.icon)
                }
                .tag(MainTab.soapNotes)

            // Billing Tab
            BillingView()
                .tabItem {
                    Label("Billing", systemImage: MainTab.billing.icon)
                }
                .tag(MainTab.billing)
        }
        .tint(.blue) // Tab bar selected color
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(DatabaseManager.preview)
}

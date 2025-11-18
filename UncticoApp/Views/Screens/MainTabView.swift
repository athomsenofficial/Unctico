// MainTabView.swift
// Main tab navigation after login
// QA Note: This is the main screen with tabs at the bottom

import SwiftUI

struct MainTabView: View {

    // MARK: - State

    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {

            // Home/Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Clients Tab
            ClientListView()
                .tabItem {
                    Label("Clients", systemImage: "person.3.fill")
                }
                .tag(1)

            // Calendar Tab
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)

            // SOAP Notes Tab
            SOAPNotesListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(3)

            // More Tab
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState())
            .environmentObject(AuthManager())
            .environmentObject(DataManager())
    }
}

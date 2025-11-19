// DashboardView.swift
// Main dashboard showing key metrics and quick actions

import SwiftUI

/// Dashboard view - the main home screen of the app
struct DashboardView: View {

    // MARK: - Environment

    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateManager

    // MARK: - State

    @State private var showingProfile = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome message
                    welcomeSection

                    // Quick stats
                    statsSection

                    // Quick actions
                    quickActionsSection

                    // Recent activity
                    recentActivitySection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }

    // MARK: - View Components

    /// Welcome section with user name
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back,")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(authManager.currentUser?.fullName ?? "Therapist")
                .font(.system(size: 32, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Quick stats cards
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Today's Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "Appointments", value: "0", icon: "calendar", color: .blue)
                StatCard(title: "Clients Seen", value: "0", icon: "person.2.fill", color: .green)
                StatCard(title: "Revenue", value: "$0", icon: "dollarsign.circle.fill", color: .purple)
                StatCard(title: "Pending Notes", value: "0", icon: "doc.text.fill", color: .orange)
            }
        }
    }

    /// Quick actions section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                QuickActionButton(title: "New Appointment", icon: "calendar.badge.plus", color: .blue) {
                    appState.selectedTab = .schedule
                }

                QuickActionButton(title: "Add Client", icon: "person.badge.plus", color: .green) {
                    appState.selectedTab = .clients
                }

                QuickActionButton(title: "Write SOAP Note", icon: "doc.text.fill", color: .orange) {
                    appState.selectedTab = .soapNotes
                }

                QuickActionButton(title: "Create Invoice", icon: "dollarsign.circle", color: .purple) {
                    appState.selectedTab = .billing
                }
            }
        }
    }

    /// Recent activity section
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                Text("No recent activity")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Action Button Component

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authManager.currentUser?.fullName ?? "N/A")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "N/A")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                        dismiss()
                    } label: {
                        Text("Logout")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppStateManager())
}

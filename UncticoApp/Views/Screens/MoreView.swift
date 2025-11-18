// MoreView.swift
// More options and settings
// QA Note: Additional features and settings

import SwiftUI

struct MoreView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var authManager: AuthManager

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    NavigationLink(destination: ProfileView()) {
                        Label("My Profile", systemImage: "person.circle")
                    }

                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Security Settings", systemImage: "lock.shield")
                    }
                }

                // Business Section
                Section("Business") {
                    NavigationLink(destination: TherapistListView()) {
                        Label("Therapists", systemImage: "person.2.fill")
                    }

                    NavigationLink(destination: FinancialView()) {
                        Label("Financial Reports", systemImage: "dollarsign.circle")
                    }

                    NavigationLink(destination: InsuranceView()) {
                        Label("Insurance Billing", systemImage: "cross.case")
                    }
                }

                // Settings Section
                Section("Settings") {
                    NavigationLink(destination: AppSettingsView()) {
                        Label("App Settings", systemImage: "gearshape")
                    }

                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: BackupView()) {
                        Label("Backup & Sync", systemImage: "icloud")
                    }
                }

                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }

                // Logout Section
                Section {
                    Button(action: { authManager.logout() }) {
                        Label("Logout", systemImage: "power")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct ProfileView: View {
    var body: some View {
        Text("Profile Settings")
            .navigationTitle("Profile")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        Text("Security Settings")
            .navigationTitle("Security")
    }
}

struct TherapistListView: View {
    var body: some View {
        Text("Therapist Management")
            .navigationTitle("Therapists")
    }
}

struct FinancialView: View {
    var body: some View {
        Text("Financial Reports")
            .navigationTitle("Financial")
    }
}

struct InsuranceView: View {
    var body: some View {
        Text("Insurance Billing")
            .navigationTitle("Insurance")
    }
}

struct AppSettingsView: View {
    var body: some View {
        Text("App Settings")
            .navigationTitle("Settings")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
    }
}

struct BackupView: View {
    var body: some View {
        Text("Backup & Sync")
            .navigationTitle("Backup")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Unctico")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(AppConfig.appVersion)")
                .foregroundColor(.secondary)

            Text("Massage Therapy Management Platform")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("About")
    }
}

// MARK: - Preview

struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
            .environmentObject(AuthManager())
    }
}

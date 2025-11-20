import Combine
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = true
    @State private var biometricAuthEnabled = true
    @State private var selectedTheme: AppTheme = .calming

    enum AppTheme: String, CaseIterable {
        case calming = "Calming"
        case professional = "Professional"
        case warm = "Warm"
    }

    var body: some View {
        NavigationView {
            Form {
                ProfileSection()

                Section("Preferences") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)

                    Toggle("Biometric Authentication", isOn: $biometricAuthEnabled)

                    Picker("Color Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }

                Section("Practice Settings") {
                    NavigationLink(destination: BusinessInfoView()) {
                        SettingRow(icon: "building.2.fill", title: "Business Information", color: .calmingBlue)
                    }

                    NavigationLink(destination: ServicesView()) {
                        SettingRow(icon: "list.bullet.rectangle", title: "Services & Pricing", color: .soothingGreen)
                    }

                    NavigationLink(destination: AvailabilityView()) {
                        SettingRow(icon: "calendar.badge.clock", title: "Availability", color: .tranquilTeal)
                    }
                }

                Section("Clinical") {
                    NavigationLink(destination: TemplatesView()) {
                        SettingRow(icon: "doc.text.fill", title: "SOAP Note Templates", color: .softLavender)
                    }

                    NavigationLink(destination: IntakeFormsView()) {
                        SettingRow(icon: "list.clipboard.fill", title: "Intake Forms", color: .calmingBlue)
                    }

                    NavigationLink(destination: ConsentFormsView()) {
                        SettingRow(icon: "checkmark.seal.fill", title: "Consent Forms", color: .soothingGreen)
                    }
                }

                Section("Compliance") {
                    NavigationLink(destination: LicensesView()) {
                        SettingRow(icon: "shield.checkered", title: "Licenses & Certifications", color: .blue)
                    }

                    NavigationLink(destination: HIPAAView()) {
                        SettingRow(icon: "lock.shield.fill", title: "HIPAA Compliance", color: .red)
                    }

                    NavigationLink(destination: InsuranceView()) {
                        SettingRow(icon: "cross.case.fill", title: "Insurance Settings", color: .orange)
                    }
                }

                Section("Data & Privacy") {
                    NavigationLink(destination: BackupView()) {
                        SettingRow(icon: "icloud.fill", title: "Backup & Sync", color: .calmingBlue)
                    }

                    NavigationLink(destination: PrivacyView()) {
                        SettingRow(icon: "hand.raised.fill", title: "Privacy & Security", color: .tranquilTeal)
                    }

                    Button(action: exportData) {
                        SettingRow(icon: "square.and.arrow.up", title: "Export Data", color: .soothingGreen)
                    }
                }

                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        SettingRow(icon: "questionmark.circle.fill", title: "Help & Documentation", color: .softLavender)
                    }

                    NavigationLink(destination: ContactSupportView()) {
                        SettingRow(icon: "envelope.fill", title: "Contact Support", color: .calmingBlue)
                    }

                    NavigationLink(destination: AboutView()) {
                        SettingRow(icon: "info.circle.fill", title: "About Unctico", color: .tranquilTeal)
                    }
                }

                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func exportData() {
        // Export data functionality
    }

    private func signOut() {
        withAnimation {
            appState.isAuthenticated = false
        }
    }
}

struct ProfileSection: View {
    var body: some View {
        Section {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.calmingBlue, .tranquilTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Therapist Name")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Licensed Massage Therapist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("LMT #12345")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)

            Spacer()
        }
    }
}

// Placeholder views for navigation destinations
struct BusinessInfoView: View {
    var body: some View {
        Text("Business Information")
            .navigationTitle("Business Info")
    }
}

struct ServicesView: View {
    var body: some View {
        Text("Services & Pricing")
            .navigationTitle("Services")
    }
}

struct AvailabilityView: View {
    var body: some View {
        Text("Availability Settings")
            .navigationTitle("Availability")
    }
}

struct TemplatesView: View {
    var body: some View {
        Text("SOAP Note Templates")
            .navigationTitle("Templates")
    }
}

struct IntakeFormsView: View {
    var body: some View {
        Text("Intake Forms")
            .navigationTitle("Intake Forms")
    }
}

struct ConsentFormsView: View {
    var body: some View {
        Text("Consent Forms")
            .navigationTitle("Consent Forms")
    }
}

struct LicensesView: View {
    var body: some View {
        Text("Licenses & Certifications")
            .navigationTitle("Licenses")
    }
}

struct HIPAAView: View {
    var body: some View {
        Text("HIPAA Compliance")
            .navigationTitle("HIPAA")
    }
}

struct InsuranceView: View {
    var body: some View {
        Text("Insurance Settings")
            .navigationTitle("Insurance")
    }
}

struct BackupView: View {
    var body: some View {
        Text("Backup & Sync")
            .navigationTitle("Backup")
    }
}

struct PrivacyView: View {
    var body: some View {
        Text("Privacy & Security")
            .navigationTitle("Privacy")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Documentation")
            .navigationTitle("Help")
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("Contact Support")
            .navigationTitle("Support")
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 80))
                    .foregroundColor(.tranquilTeal)

                Text("Unctico")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Massage Therapy Practice Management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.vertical)

                Text("Built with care for massage therapists")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

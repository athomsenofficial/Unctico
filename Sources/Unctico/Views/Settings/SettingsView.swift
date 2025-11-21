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

                    NavigationLink(destination: CommunicationView()) {
                        SettingRow(icon: "envelope.badge.fill", title: "Client Communications", color: .softLavender)
                    }

                    NavigationLink(destination: AnalyticsDashboardView()) {
                        SettingRow(icon: "chart.bar.fill", title: "Analytics & Reports", color: .calmingBlue)
                    }

                    NavigationLink(destination: InventoryManagementView()) {
                        SettingRow(icon: "box.fill", title: "Inventory Management", color: .purple)
                    }

                    NavigationLink(destination: TeamManagementView()) {
                        SettingRow(icon: "person.3.fill", title: "Team Management", color: .blue)
                    }

                    NavigationLink(destination: MarketingAutomationView()) {
                        SettingRow(icon: "envelope.badge.fill", title: "Marketing Automation", color: .orange)
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

                    NavigationLink(destination: TaxComplianceView()) {
                        SettingRow(icon: "doc.text.fill", title: "Tax Compliance", color: .green)
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

// MARK: - Business Information View
struct BusinessInfoView: View {
    @ObservedObject private var repository = PracticeSettingsRepository.shared
    @State private var businessInfo: BusinessInfo
    @Environment(\.dismiss) var dismiss

    init() {
        _businessInfo = State(initialValue: PracticeSettingsRepository.shared.settings.businessInfo)
    }

    var body: some View {
        Form {
            Section("Practice Details") {
                TextField("Practice Name", text: $businessInfo.practiceName)
                TextField("Owner/Therapist Name", text: $businessInfo.ownerName)
                TextField("License Number", text: $businessInfo.licenseNumber)
                TextField("Tax ID (EIN)", text: $businessInfo.taxId)
            }

            Section("Contact Information") {
                TextField("Phone", text: $businessInfo.phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $businessInfo.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Website", text: $businessInfo.website)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }

            Section("Business Address") {
                TextField("Street Address", text: $businessInfo.address.street)
                TextField("City", text: $businessInfo.address.city)
                TextField("State", text: $businessInfo.address.state)
                TextField("ZIP Code", text: $businessInfo.address.zipCode)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Business Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    repository.updateBusinessInfo(businessInfo)
                }
            }
        }
    }
}

// MARK: - Services View
struct ServicesView: View {
    @ObservedObject private var repository = PracticeSettingsRepository.shared
    @State private var showingAddService = false

    var body: some View {
        List {
            Section {
                ForEach(repository.settings.services) { service in
                    NavigationLink(destination: EditServiceView(service: service)) {
                        ServiceRow(service: service)
                    }
                }
                .onDelete(perform: deleteService)
            }

            if repository.settings.services.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No services configured")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add services you offer to display pricing and enable booking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle("Services & Pricing")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddService = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddService) {
            AddServiceView()
        }
    }

    private func deleteService(at offsets: IndexSet) {
        offsets.forEach { index in
            let service = repository.settings.services[index]
            repository.deleteService(service)
        }
    }
}

struct ServiceRow: View {
    let service: Service

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)

                HStack {
                    Text("\(service.durationMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !service.isActive {
                        Text("• Inactive")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text(service.price, format: .currency(code: "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.tranquilTeal)
        }
    }
}

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = PracticeSettingsRepository.shared

    @State private var name = ""
    @State private var duration = 60
    @State private var price = ""
    @State private var description = ""

    let durationOptions = [30, 45, 60, 75, 90, 120]

    var body: some View {
        NavigationView {
            Form {
                Section("Service Details") {
                    TextField("Service Name", text: $name)
                        .autocapitalization(.words)

                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }

                    HStack {
                        Text("$")
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveService() }
                        .disabled(name.isEmpty || price.isEmpty)
                }
            }
        }
    }

    private func saveService() {
        guard let priceValue = Double(price), priceValue > 0 else { return }

        let service = Service(
            name: name,
            duration: TimeInterval(duration * 60),
            price: priceValue,
            description: description
        )
        repository.addService(service)
        dismiss()
    }
}

struct EditServiceView: View {
    @ObservedObject private var repository = PracticeSettingsRepository.shared
    @State private var service: Service

    init(service: Service) {
        _service = State(initialValue: service)
    }

    var body: some View {
        Form {
            Section("Service Details") {
                TextField("Service Name", text: $service.name)

                HStack {
                    Text("$")
                    TextField("Price", value: $service.price, format: .number)
                        .keyboardType(.decimalPad)
                }

                TextField("Description", text: $service.description, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Toggle("Active Service", isOn: $service.isActive)
            }
        }
        .navigationTitle("Edit Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    repository.updateService(service)
                }
            }
        }
    }
}

// MARK: - Availability View
struct AvailabilityView: View {
    @ObservedObject private var repository = PracticeSettingsRepository.shared
    @State private var availability: WeeklyAvailability

    init() {
        _availability = State(initialValue: PracticeSettingsRepository.shared.settings.availability)
    }

    var body: some View {
        Form {
            ForEach(WeeklyAvailability.Weekday.allCases, id: \.self) { weekday in
                Section(weekday.rawValue) {
                    Toggle("Available", isOn: binding(for: weekday).isAvailable)

                    if binding(for: weekday).wrappedValue.isAvailable {
                        HStack {
                            Text("Start Time")
                            Spacer()
                            TextField("09:00", text: binding(for: weekday).startTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                        }

                        HStack {
                            Text("End Time")
                            Spacer()
                            TextField("17:00", text: binding(for: weekday).endTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                        }
                    }
                }
            }
        }
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    repository.updateAvailability(availability)
                }
            }
        }
    }

    private func binding(for weekday: WeeklyAvailability.Weekday) -> Binding<DayAvailability> {
        Binding(
            get: { availability.availability(for: weekday) },
            set: { availability.setAvailability($0, for: weekday) }
        )
    }
}

struct TemplatesView: View {
    var body: some View {
        Text("SOAP Note Templates")
            .navigationTitle("Templates")
    }
}

struct IntakeFormsView: View {
    @StateObject private var repository = IntakeFormRepository.shared

    var body: some View {
        List {
            Section(header: Text("Statistics")) {
                let stats = repository.getStatistics()
                HStack {
                    Text("Total Forms")
                    Spacer()
                    Text("\(stats.totalForms)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Completed")
                    Spacer()
                    Text("\(stats.completedForms)")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("In Progress")
                    Spacer()
                    Text("\(stats.inProgressForms)")
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("Completion Rate")
                    Spacer()
                    Text("\(Int(stats.completionRate))%")
                        .foregroundColor(.blue)
                }
            }

            Section(header: Text("Templates")) {
                ForEach(repository.templates) { template in
                    HStack {
                        Image(systemName: template.category.icon)
                            .foregroundColor(template.category.color)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)

                            Text("\(template.questions.count) questions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if template.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Intake Forms")
    }
}

struct ConsentFormsView: View {
    var body: some View {
        ConsentFormsManagementView()
    }
}

struct LicensesView: View {
    var body: some View {
        LicenseManagementView()
    }
}

struct HIPAAView: View {
    var body: some View {
        HIPAAComplianceView()
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

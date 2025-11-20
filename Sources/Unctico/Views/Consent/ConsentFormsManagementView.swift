import SwiftUI

struct ConsentFormsManagementView: View {
    @StateObject private var repository = ConsentFormRepository.shared
    @State private var selectedTab = 0
    @State private var showingNewFormSheet = false
    @State private var showingTemplateEditor = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("All Forms").tag(1)
                Text("Templates").tag(2)
                Text("Compliance").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            TabView(selection: $selectedTab) {
                OverviewTab(repository: repository)
                    .tag(0)

                AllFormsTab(repository: repository)
                    .tag(1)

                TemplatesTab(repository: repository)
                    .tag(2)

                ComplianceTab(repository: repository)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Consent Forms")
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var repository: ConsentFormRepository

    var statistics: FormStatistics {
        repository.getStatistics()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics Cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Total Forms",
                        value: "\(statistics.totalForms)",
                        icon: "doc.text.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "Signed",
                        value: "\(statistics.signedForms)",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Pending",
                        value: "\(statistics.unsignedForms)",
                        icon: "clock.fill",
                        color: .orange
                    )
                }

                // Alerts
                if statistics.expiredForms > 0 {
                    AlertCard(
                        title: "Expired Forms",
                        message: "\(statistics.expiredForms) forms have expired and need renewal",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                }

                if statistics.formsNeedingRenewal > 0 {
                    AlertCard(
                        title: "Renewal Needed",
                        message: "\(statistics.formsNeedingRenewal) forms will expire soon",
                        icon: "clock.badge.exclamationmark",
                        color: .orange
                    )
                }

                // Forms by Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Forms by Type")
                        .font(.headline)

                    ForEach(ConsentFormType.allCases, id: \.self) { type in
                        if let count = statistics.formsByType[type] {
                            FormTypeRow(
                                formType: type,
                                count: count
                            )
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    NavigationLink(destination: Text("New Form")) {
                        QuickActionButton(
                            title: "Create New Form",
                            icon: "plus.circle.fill",
                            color: .blue
                        )
                    }

                    NavigationLink(destination: Text("View All")) {
                        QuickActionButton(
                            title: "View All Forms",
                            icon: "doc.text.magnifyingglass",
                            color: .purple
                        )
                    }

                    NavigationLink(destination: Text("Manage Templates")) {
                        QuickActionButton(
                            title: "Manage Templates",
                            icon: "doc.on.doc.fill",
                            color: .green
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AlertCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FormTypeRow: View {
    let formType: ConsentFormType
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: formType.icon)
                .foregroundColor(formType.color)
                .frame(width: 24)

            Text(formType.rawValue)
                .font(.subheadline)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - All Forms Tab

struct AllFormsTab: View {
    @ObservedObject var repository: ConsentFormRepository
    @State private var searchText = ""
    @State private var filterType: ConsentFormType?
    @State private var showSignedOnly = false

    var filteredForms: [ConsentForm] {
        var forms = repository.forms

        if showSignedOnly {
            forms = forms.filter { $0.isSigned }
        }

        if let type = filterType {
            forms = forms.filter { $0.formType == type }
        }

        if !searchText.isEmpty {
            forms = forms.filter { form in
                form.clientName.localizedCaseInsensitiveContains(searchText) ||
                form.formType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return forms.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search forms...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))

            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: filterType == nil,
                        action: { filterType = nil }
                    )

                    ForEach(ConsentFormType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: filterType == type,
                            action: { filterType = type }
                        )
                    }
                }
                .padding()
            }

            Toggle("Signed Only", isOn: $showSignedOnly)
                .padding()

            // Forms list
            List(filteredForms) { form in
                NavigationLink(destination: ConsentFormDetailView(form: form)) {
                    ConsentFormRow(form: form)
                }
            }
            .listStyle(.plain)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ConsentFormRow: View {
    let form: ConsentForm

    var statusColor: Color {
        if form.isExpired { return .red }
        if form.needsRenewal { return .orange }
        if form.isSigned { return .green }
        return .blue
    }

    var statusIcon: String {
        if form.isExpired { return "exclamationmark.triangle.fill" }
        if form.needsRenewal { return "clock.badge.exclamationmark" }
        if form.isSigned { return "checkmark.seal.fill" }
        return "clock.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: form.formType.icon)
                .font(.title3)
                .foregroundColor(form.formType.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(form.formType.rawValue)
                    .font(.headline)

                Text(form.clientName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text(form.isSigned ? "Signed" : "Pending")
                        .font(.caption)
                }
                .foregroundColor(statusColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(form.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let signedDate = form.signatureDate {
                    Text(signedDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Templates Tab

struct TemplatesTab: View {
    @ObservedObject var repository: ConsentFormRepository

    var body: some View {
        List {
            Section(header: Text("Default Templates")) {
                ForEach(repository.templates.filter { !$0.isCustom }) { template in
                    NavigationLink(destination: TemplateEditorView(template: template)) {
                        TemplateRow(template: template)
                    }
                }
            }

            Section(header: Text("Custom Templates")) {
                ForEach(repository.templates.filter { $0.isCustom }) { template in
                    NavigationLink(destination: TemplateEditorView(template: template)) {
                        TemplateRow(template: template)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let customTemplates = repository.templates.filter { $0.isCustom }
                        repository.deleteTemplate(customTemplates[index].id)
                    }
                }
            }
        }
    }
}

struct TemplateRow: View {
    let template: ConsentFormTemplate

    var body: some View {
        HStack {
            Image(systemName: template.formType.icon)
                .foregroundColor(template.formType.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                Text("Version \(template.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if template.isCustom {
                Text("Custom")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

struct TemplateEditorView: View {
    let template: ConsentFormTemplate

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(template.content)
                    .font(.body)
                    .padding()
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Compliance Tab

struct ComplianceTab: View {
    @ObservedObject var repository: ConsentFormRepository

    var complianceStatus: ConsentComplianceStatus {
        repository.getComplianceStatus()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Compliance Score
                ComplianceScoreCard(status: complianceStatus)

                // Issues
                if !complianceStatus.isFullyCompliant {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issues Requiring Attention")
                            .font(.headline)

                        if complianceStatus.clientsNonCompliant > 0 {
                            IssueCard(
                                title: "Clients Missing Required Forms",
                                count: complianceStatus.clientsNonCompliant,
                                severity: .high
                            )
                        }

                        if complianceStatus.totalFormsExpired > 0 {
                            IssueCard(
                                title: "Expired Forms",
                                count: complianceStatus.totalFormsExpired,
                                severity: .high
                            )
                        }

                        if complianceStatus.totalFormsNeedingRenewal > 0 {
                            IssueCard(
                                title: "Forms Needing Renewal",
                                count: complianceStatus.totalFormsNeedingRenewal,
                                severity: .medium
                            )
                        }
                    }
                }

                // Required Forms Checklist
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Forms")
                        .font(.headline)

                    RequiredFormRow(
                        formType: .informedConsent,
                        description: "Required for all clients before treatment"
                    )

                    RequiredFormRow(
                        formType: .privacyNotice,
                        description: "HIPAA requirement for all clients"
                    )

                    RequiredFormRow(
                        formType: .liabilityWaiver,
                        description: "Protects practice from liability claims"
                    )
                }
            }
            .padding()
        }
    }
}

struct ComplianceScoreCard: View {
    let status: ConsentComplianceStatus

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)

                Circle()
                    .trim(from: 0, to: status.compliancePercentage / 100)
                    .stroke(
                        status.isFullyCompliant ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int(status.compliancePercentage))%")
                        .font(.system(size: 40, weight: .bold))

                    Text("Compliant")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)

            HStack(spacing: 20) {
                VStack {
                    Text("\(status.clientsCompliant)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    Text("Compliant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(status.clientsNonCompliant)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.red)
                    Text("Non-Compliant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct IssueCard: View {
    let title: String
    let count: Int
    let severity: Severity

    enum Severity {
        case low, medium, high

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(severity.color)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text("\(count)")
                .font(.headline)
                .foregroundColor(severity.color)
        }
        .padding()
        .background(severity.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RequiredFormRow: View {
    let formType: ConsentFormType
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: formType.icon)
                .foregroundColor(formType.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(formType.rawValue)
                    .font(.subheadline)
                    .bold()

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

// MARK: - Form Detail View

struct ConsentFormDetailView: View {
    let form: ConsentForm
    @StateObject private var repository = ConsentFormRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: form.formType.icon)
                            .font(.title)
                            .foregroundColor(form.formType.color)

                        VStack(alignment: .leading) {
                            Text(form.formType.rawValue)
                                .font(.title2)
                                .bold()

                            Text(form.clientName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    if form.isSigned, let signedDate = form.signatureDate {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Signed on \(signedDate, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Form Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Form Content")
                        .font(.headline)

                    Text(form.content)
                        .font(.body)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }

                // Signature
                if form.isSigned {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Client Signature")
                            .font(.headline)

                        SignatureDisplayView(signatureData: form.signatureData)
                    }

                    if let witness = form.witnessName {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Witness: \(witness)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            SignatureDisplayView(signatureData: form.witnessSignature)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Form Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ConsentFormsManagementView()
    }
}

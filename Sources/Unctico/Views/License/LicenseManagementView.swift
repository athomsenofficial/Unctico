import SwiftUI

struct LicenseManagementView: View {
    @StateObject private var repository = LicenseRepository.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Licenses").tag(1)
                Text("CE Credits").tag(2)
                Text("Insurance").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            TabView(selection: $selectedTab) {
                LicenseOverviewTab(repository: repository)
                    .tag(0)

                LicensesTab(repository: repository)
                    .tag(1)

                CECreditsTab(repository: repository)
                    .tag(2)

                InsuranceTab(repository: repository)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Licenses & Certifications")
    }
}

// MARK: - Overview Tab

struct LicenseOverviewTab: View {
    @ObservedObject var repository: LicenseRepository

    var complianceStatus: OverallComplianceStatus {
        repository.getOverallComplianceStatus()
    }

    var upcomingDeadlines: [ComplianceDeadline] {
        repository.getUpcomingDeadlines(days: 90)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Compliance Score
                ComplianceScoreView(status: complianceStatus)

                // Critical Alerts
                if !complianceStatus.isFullyCompliant {
                    CriticalAlertsSection(status: complianceStatus)
                }

                // Upcoming Deadlines
                if !upcomingDeadlines.isEmpty {
                    UpcomingDeadlinesSection(deadlines: upcomingDeadlines)
                }

                // Quick Stats
                QuickStatsGrid(status: complianceStatus)

                // Quick Actions
                QuickActionsSection()
            }
            .padding()
        }
    }
}

struct ComplianceScoreView: View {
    let status: OverallComplianceStatus

    var complianceScore: Double {
        let total = Double(status.totalLicenses + status.totalInsurance + 1) // +1 for liability requirement
        guard total > 0 else { return 100 }

        let compliant = Double(
            status.activeLicenses +
            (status.totalInsurance - status.expiredInsurance) +
            (status.hasActiveLiability ? 1 : 0)
        )

        return (compliant / total) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: status.isFullyCompliant ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(status.isFullyCompliant ? .green : .orange)

                Text("Professional Compliance")
                    .font(.headline)

                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)

                Circle()
                    .trim(from: 0, to: complianceScore / 100)
                    .stroke(
                        status.isFullyCompliant ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int(complianceScore))%")
                        .font(.system(size: 40, weight: .bold))

                    Text(status.isFullyCompliant ? "Compliant" : "Action Needed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)

            if status.criticalIssues > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\(status.criticalIssues) critical issue(s) require immediate attention")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CriticalAlertsSection: View {
    let status: OverallComplianceStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Critical Alerts")
                .font(.headline)
                .foregroundColor(.red)

            if status.expiredLicenses > 0 {
                AlertCard(
                    icon: "exclamationmark.octagon.fill",
                    title: "Expired Licenses",
                    message: "\(status.expiredLicenses) license(s) have expired",
                    color: .red
                )
            }

            if status.expiredInsurance > 0 {
                AlertCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Expired Insurance",
                    message: "\(status.expiredInsurance) policy/policies have expired",
                    color: .red
                )
            }

            if !status.hasActiveLiability {
                AlertCard(
                    icon: "shield.slash.fill",
                    title: "No Active Liability Insurance",
                    message: "Professional liability insurance is required",
                    color: .red
                )
            }

            if status.licensesNeedingRenewal > 0 {
                AlertCard(
                    icon: "clock.badge.exclamationmark",
                    title: "Renewal Needed",
                    message: "\(status.licensesNeedingRenewal) license(s) expiring soon",
                    color: .orange
                )
            }
        }
    }
}

struct AlertCard: View {
    let icon: String
    let title: String
    let message: String
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

struct UpcomingDeadlinesSection: View {
    let deadlines: [ComplianceDeadline]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Deadlines (Next 90 Days)")
                .font(.headline)

            ForEach(deadlines.prefix(5)) { deadline in
                DeadlineRow(deadline: deadline)
            }

            if deadlines.count > 5 {
                Text("+ \(deadlines.count - 5) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)
            }
        }
    }
}

struct DeadlineRow: View {
    let deadline: ComplianceDeadline

    var body: some View {
        HStack {
            Circle()
                .fill(deadline.priority.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.name)
                    .font(.subheadline)
                    .bold()

                Text("Due in \(deadline.daysUntilDue) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(deadline.dueDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct QuickStatsGrid: View {
    let status: OverallComplianceStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatBox(
                    title: "Active Licenses",
                    value: "\(status.activeLicenses)",
                    icon: "doc.text.fill",
                    color: .blue
                )

                StatBox(
                    title: "Certifications",
                    value: "\(status.totalCertifications)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )

                StatBox(
                    title: "Insurance Policies",
                    value: "\(status.totalInsurance)",
                    icon: "shield.fill",
                    color: .purple
                )

                StatBox(
                    title: "Issues",
                    value: "\(status.criticalIssues)",
                    icon: "exclamationmark.triangle.fill",
                    color: status.criticalIssues > 0 ? .red : .green
                )
            }
        }
    }
}

struct StatBox: View {
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

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            QuickActionButton(
                title: "Add License",
                icon: "plus.circle.fill",
                color: .blue
            )

            QuickActionButton(
                title: "Log CE Credits",
                icon: "graduationcap.fill",
                color: .green
            )

            QuickActionButton(
                title: "Update Insurance",
                icon: "shield.fill",
                color: .purple
            )
        }
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

// MARK: - Licenses Tab

struct LicensesTab: View {
    @ObservedObject var repository: LicenseRepository
    @State private var showingAddLicense = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                if !repository.licenses.isEmpty {
                    ForEach(repository.licenses) { license in
                        LicenseRow(license: license)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            repository.deleteLicense(repository.licenses[index].id)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "doc.text.fill",
                        title: "No Licenses",
                        message: "Add your professional licenses to track renewals"
                    )
                }
            }
            .listStyle(.plain)

            Button(action: { showingAddLicense = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add License")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddLicense) {
            AddLicenseView()
        }
    }
}

struct LicenseRow: View {
    let license: ProfessionalLicense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: license.licenseType.icon)
                .font(.title3)
                .foregroundColor(license.licenseType.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(license.licenseType.rawValue)
                    .font(.headline)

                Text("\(license.state) • #\(license.licenseNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(license.alertLevel.color)
                        .frame(width: 8, height: 8)

                    if license.isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Expires in \(license.daysUntilExpiration) days")
                            .font(.caption)
                            .foregroundColor(license.alertLevel.color)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(license.expirationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: license.isExpired ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(license.isExpired ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddLicenseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = LicenseRepository.shared

    @State private var licenseType: LicenseType = .massageTherapy
    @State private var state = ""
    @State private var licenseNumber = ""
    @State private var issueDate = Date()
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
    @State private var renewalFee = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("License Details") {
                    Picker("License Type", selection: $licenseType) {
                        ForEach(LicenseType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    TextField("State", text: $state)
                        .autocapitalization(.words)

                    TextField("License Number", text: $licenseNumber)
                        .autocapitalization(.characters)
                }

                Section("Dates") {
                    DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }

                Section("Additional Information") {
                    HStack {
                        Text("$")
                        TextField("Renewal Fee", text: $renewalFee)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLicense() }
                        .disabled(state.isEmpty || licenseNumber.isEmpty)
                }
            }
        }
    }

    private func saveLicense() {
        let fee = Double(renewalFee)

        let license = ProfessionalLicense(
            licenseType: licenseType,
            state: state,
            licenseNumber: licenseNumber,
            issueDate: issueDate,
            expirationDate: expirationDate,
            renewalFee: fee,
            notes: notes
        )

        repository.addLicense(license)
        dismiss()
    }
}

// MARK: - CE Credits Tab

struct CECreditsTab: View {
    @ObservedObject var repository: LicenseRepository
    @State private var showingAddCredit = false
    @State private var selectedState = "California"
    @State private var renewalPeriodStart = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()

    var ceStatus: CEComplianceStatus {
        repository.checkCECompliance(for: selectedState, renewalPeriodStart: renewalPeriodStart)
    }

    var body: some View {
        VStack(spacing: 0) {
            // CE Compliance Status
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CEComplianceCard(status: ceStatus)

                    CECreditsList(repository: repository)
                }
                .padding()
            }

            Button(action: { showingAddCredit = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log CE Credits")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddCredit) {
            AddCECreditView()
        }
    }
}

struct CEComplianceCard: View {
    let status: CEComplianceStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: status.isCompliant ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(status.isCompliant ? .green : .orange)

                Text("CE Compliance - \(status.state)")
                    .font(.headline)

                Spacer()
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Credits")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.1f", status.totalCreditsEarned)) / \(String(format: "%.0f", status.totalCreditsRequired))")
                        .font(.subheadline)
                        .bold()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(status.isCompliant ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * (status.progressPercentage / 100), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)

                Text("\(Int(status.progressPercentage))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if status.ethicsCreditsRequired > 0 {
                HStack {
                    Text("Ethics Credits")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.1f", status.ethicsCreditsEarned)) / \(String(format: "%.0f", status.ethicsCreditsRequired))")
                        .font(.subheadline)
                        .foregroundColor(status.ethicsCreditsEarned >= status.ethicsCreditsRequired ? .green : .orange)
                }
            }

            if !status.isCompliant {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(String(format: "%.1f", status.creditsNeeded)) more credits needed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CECreditsList: View {
    @ObservedObject var repository: LicenseRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent CE Credits")
                .font(.headline)

            if repository.ceCredits.isEmpty {
                Text("No CE credits logged yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(repository.ceCredits.sorted(by: { $0.completionDate > $1.completionDate }).prefix(10)) { credit in
                    CECreditRow(credit: credit)
                }
            }
        }
    }
}

struct CECreditRow: View {
    let credit: ContinuingEducation

    var body: some View {
        HStack {
            Image(systemName: credit.category.icon)
                .foregroundColor(credit.category.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(credit.courseName)
                    .font(.subheadline)
                    .bold()

                Text(credit.provider)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", credit.credits)) hrs")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.green)

                Text(credit.completionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct AddCECreditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = LicenseRepository.shared

    @State private var courseName = ""
    @State private var provider = ""
    @State private var category: CECategory = .modalities
    @State private var credits = ""
    @State private var completionDate = Date()
    @State private var cost = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Course Details") {
                    TextField("Course Name", text: $courseName)

                    TextField("Provider", text: $provider)

                    Picker("Category", selection: $category) {
                        ForEach(CECategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Credits & Date") {
                    HStack {
                        TextField("Credits (hours)", text: $credits)
                            .keyboardType(.decimalPad)
                        Text("hours")
                            .foregroundColor(.secondary)
                    }

                    DatePicker("Completion Date", selection: $completionDate, displayedComponents: .date)
                }

                Section("Additional Information") {
                    HStack {
                        Text("$")
                        TextField("Cost", text: $cost)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log CE Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCredit() }
                        .disabled(courseName.isEmpty || credits.isEmpty)
                }
            }
        }
    }

    private func saveCredit() {
        guard let creditHours = Double(credits), creditHours > 0 else { return }
        let costValue = Double(cost)

        let ceCredit = ContinuingEducation(
            courseName: courseName,
            provider: provider,
            category: category,
            credits: creditHours,
            completionDate: completionDate,
            cost: costValue,
            notes: notes
        )

        repository.addCECredit(ceCredit)
        dismiss()
    }
}

// MARK: - Insurance Tab

struct InsuranceTab: View {
    @ObservedObject var repository: LicenseRepository
    @State private var showingAddInsurance = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                if !repository.insurancePolicies.isEmpty {
                    ForEach(repository.insurancePolicies) { insurance in
                        InsuranceRow(insurance: insurance)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            repository.deleteInsurance(repository.insurancePolicies[index].id)
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "shield.fill",
                        title: "No Insurance Policies",
                        message: "Add your professional insurance to track renewals"
                    )
                }
            }
            .listStyle(.plain)

            Button(action: { showingAddInsurance = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Insurance")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddInsurance) {
            AddInsuranceView()
        }
    }
}

struct InsuranceRow: View {
    let insurance: ProfessionalInsurance

    var body: some View {
        HStack {
            Image(systemName: insurance.insuranceType.icon)
                .foregroundColor(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(insurance.insuranceType.rawValue)
                    .font(.subheadline)
                    .bold()

                Text(insurance.provider)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(insurance.isExpired ? Color.red : (insurance.needsRenewal ? Color.orange : Color.green))
                        .frame(width: 6, height: 6)

                    Text(insurance.isExpired ? "Expired" : "Active")
                        .font(.caption2)
                        .foregroundColor(insurance.isExpired ? .red : .green)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(insurance.expirationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("$\(Int(insurance.coverageAmount / 1000))K")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddInsuranceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = LicenseRepository.shared

    @State private var insuranceType: InsuranceType = .liability
    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var coverageAmount = ""
    @State private var effectiveDate = Date()
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var premium = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Insurance Details") {
                    Picker("Type", selection: $insuranceType) {
                        ForEach(InsuranceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    TextField("Provider", text: $provider)

                    TextField("Policy Number", text: $policyNumber)
                }

                Section("Coverage") {
                    HStack {
                        Text("$")
                        TextField("Coverage Amount", text: $coverageAmount)
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Text("$")
                        TextField("Annual Premium", text: $premium)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Dates") {
                    DatePicker("Effective Date", selection: $effectiveDate, displayedComponents: .date)
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Insurance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveInsurance() }
                        .disabled(provider.isEmpty || coverageAmount.isEmpty)
                }
            }
        }
    }

    private func saveInsurance() {
        guard let coverage = Double(coverageAmount),
              let premiumValue = Double(premium) else { return }

        let insurance = ProfessionalInsurance(
            insuranceType: insuranceType,
            provider: provider,
            policyNumber: policyNumber,
            coverageAmount: coverage,
            effectiveDate: effectiveDate,
            expirationDate: expirationDate,
            premium: premiumValue
        )

        repository.addInsurance(insurance)
        dismiss()
    }
}

// MARK: - Shared Components

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    NavigationView {
        LicenseManagementView()
    }
}

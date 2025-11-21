import SwiftUI

/// View for managing contraindications and red flag symptoms
struct ContraindicationManagementView: View {
    @StateObject private var service = ContraindicationService()
    @State private var selectedTab = 0
    @State private var showingAddContraindication = false
    @State private var showingAddRedFlag = false
    @State private var searchText = ""
    @State private var selectedClient: UUID?

    var filteredContraindications: [ContraindicationAlert] {
        if searchText.isEmpty {
            return service.contraindications
        }
        return service.contraindications.filter {
            $0.condition.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredRedFlags: [RedFlagAlert] {
        if searchText.isEmpty {
            return service.redFlags
        }
        return service.redFlags.filter {
            $0.symptom.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Contraindications").tag(0)
                    Text("Red Flags").tag(1)
                    Text("Statistics").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedTab == 0 {
                    contraindicationsView
                } else if selectedTab == 1 {
                    redFlagsView
                } else {
                    statisticsView
                }
            }
            .navigationTitle("Safety Alerts")
            .searchable(text: $searchText, prompt: "Search alerts...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddContraindication = true
                        } label: {
                            Label("Add Contraindication", systemImage: "exclamationmark.triangle")
                        }

                        Button {
                            showingAddRedFlag = true
                        } label: {
                            Label("Add Red Flag", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContraindication) {
                AddContraindicationView(service: service)
            }
            .sheet(isPresented: $showingAddRedFlag) {
                AddRedFlagView(service: service)
            }
        }
    }

    // MARK: - Contraindications View

    private var contraindicationsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Active alerts
                if !activeContraindications.isEmpty {
                    Section {
                        ForEach(activeContraindications) { contraindication in
                            ContraindicationCard(
                                contraindication: contraindication,
                                service: service
                            )
                        }
                    } header: {
                        HStack {
                            Text("Active Alerts")
                                .font(.headline)
                            Spacer()
                            Text("\(activeContraindications.count)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }

                // Resolved alerts
                if !resolvedContraindications.isEmpty {
                    Section {
                        ForEach(resolvedContraindications) { contraindication in
                            ContraindicationCard(
                                contraindication: contraindication,
                                service: service
                            )
                            .opacity(0.6)
                        }
                    } header: {
                        HStack {
                            Text("Resolved")
                                .font(.headline)
                            Spacer()
                            Text("\(resolvedContraindications.count)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }

                if filteredContraindications.isEmpty {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "No Contraindications",
                        message: "Contraindications will appear here when detected"
                    )
                }
            }
            .padding()
        }
    }

    private var activeContraindications: [ContraindicationAlert] {
        filteredContraindications.filter { !$0.isResolved }
            .sorted { $0.severity.rawValue < $1.severity.rawValue }
    }

    private var resolvedContraindications: [ContraindicationAlert] {
        filteredContraindications.filter { $0.isResolved }
            .sorted { $0.resolvedDate ?? Date() > $1.resolvedDate ?? Date() }
    }

    // MARK: - Red Flags View

    private var redFlagsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRedFlags.sorted { $0.symptom.urgency.rawValue < $1.symptom.urgency.rawValue }) { redFlag in
                    RedFlagCard(
                        redFlag: redFlag,
                        service: service
                    )
                }

                if filteredRedFlags.isEmpty {
                    EmptyStateView(
                        icon: "flag",
                        title: "No Red Flags",
                        message: "Red flag symptoms will appear here when detected"
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Statistics View

    private var statisticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Contraindication statistics
                ContraindicationStatisticsCard(
                    statistics: service.getContraindicationStatistics()
                )

                // Red flag statistics
                RedFlagStatisticsCard(
                    statistics: service.getRedFlagStatistics()
                )

                // Safety guidelines
                SafetyGuidelinesCard()
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ContraindicationCard: View {
    let contraindication: ContraindicationAlert
    let service: ContraindicationService

    @State private var showingDetail = false
    @State private var showingResolve = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: contraindication.severity.icon)
                        .foregroundColor(contraindication.severity.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(contraindication.condition.rawValue)
                            .font(.headline)

                        Text(contraindication.severity.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if contraindication.isResolved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                if !contraindication.notes.isEmpty {
                    Text(contraindication.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Text(contraindication.detectedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !contraindication.isResolved {
                        Button("Resolve") {
                            showingResolve = true
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(contraindication.severity.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            ContraindicationDetailView(
                contraindication: contraindication,
                service: service
            )
        }
        .sheet(isPresented: $showingResolve) {
            ResolveContraindicationView(
                contraindication: contraindication,
                service: service
            )
        }
    }
}

struct RedFlagCard: View {
    let redFlag: RedFlagAlert
    let service: ContraindicationService

    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: redFlag.symptom.icon)
                        .foregroundColor(redFlag.symptom.color)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(redFlag.symptom.rawValue)
                            .font(.headline)

                        Text(redFlag.symptom.urgency.rawValue)
                            .font(.caption)
                            .foregroundColor(redFlag.symptom.color)
                    }

                    Spacer()

                    if redFlag.wasReferred {
                        VStack {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundColor(.green)
                            Text("Referred")
                                .font(.caption2)
                        }
                    }
                }

                Text(redFlag.symptom.recommendedAction)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(redFlag.symptom.color.opacity(0.1))
                    .cornerRadius(6)

                if !redFlag.notes.isEmpty {
                    Text(redFlag.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(redFlag.detectedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(redFlag.symptom.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            RedFlagDetailView(
                redFlag: redFlag,
                service: service
            )
        }
    }
}

struct ContraindicationStatisticsCard: View {
    let statistics: ContraindicationStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contraindication Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatBox(title: "Total", value: "\(statistics.total)", color: .blue)
                StatBox(title: "Active", value: "\(statistics.active)", color: .orange)
                StatBox(title: "Resolved", value: "\(statistics.resolved)", color: .green)
                StatBox(title: "Absolute", value: "\(statistics.absolute)", color: .red)
                StatBox(title: "Local", value: "\(statistics.local)", color: .orange)
                StatBox(title: "Caution", value: "\(statistics.caution)", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RedFlagStatisticsCard: View {
    let statistics: RedFlagStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Red Flag Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatBox(title: "Total", value: "\(statistics.total)", color: .blue)
                StatBox(title: "Emergency", value: "\(statistics.emergency)", color: .red)
                StatBox(title: "Urgent", value: "\(statistics.urgent)", color: .orange)
                StatBox(title: "Referred", value: "\(statistics.referred)", color: .green)
            }

            if statistics.total > 0 {
                HStack {
                    Text("Referral Rate")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", statistics.referralRate))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafetyGuidelinesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Guidelines")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                GuidelineRow(
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    text: "Never massage with absolute contraindications"
                )

                GuidelineRow(
                    icon: "phone.fill",
                    color: .red,
                    text: "Call 911 for emergency symptoms"
                )

                GuidelineRow(
                    icon: "stethoscope",
                    color: .blue,
                    text: "Obtain physician clearance when required"
                )

                GuidelineRow(
                    icon: "bubble.left.and.bubble.right",
                    color: .green,
                    text: "Communicate openly with clients about concerns"
                )

                GuidelineRow(
                    icon: "doc.text",
                    color: .orange,
                    text: "Document all contraindications and actions taken"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GuidelineRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Add/Edit Views

struct AddContraindicationView: View {
    let service: ContraindicationService

    @State private var selectedCondition: ContraindicationAlert.ContraindicationCondition = .pain
    @State private var notes = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Condition") {
                    Picker("Type", selection: $selectedCondition) {
                        ForEach(ContraindicationAlert.ContraindicationCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }

                    HStack {
                        Image(systemName: selectedCondition.defaultSeverity.icon)
                            .foregroundColor(selectedCondition.defaultSeverity.color)
                        Text(selectedCondition.defaultSeverity.rawValue)
                            .font(.subheadline)
                    }
                }

                Section("Recommendations") {
                    ForEach(selectedCondition.recommendations, id: \.self) { recommendation in
                        Text(recommendation)
                            .font(.subheadline)
                    }
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Contraindication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Get selected client ID
                        let alert = ContraindicationAlert(
                            clientId: UUID(), // Replace with actual client
                            condition: selectedCondition,
                            severity: selectedCondition.defaultSeverity,
                            notes: notes
                        )
                        service.addContraindication(alert)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddRedFlagView: View {
    let service: ContraindicationService

    @State private var selectedSymptom: RedFlagAlert.RedFlagSymptom = .chestPain
    @State private var notes = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Symptom") {
                    Picker("Type", selection: $selectedSymptom) {
                        ForEach(RedFlagAlert.RedFlagSymptom.allCases, id: \.self) { symptom in
                            Text(symptom.rawValue).tag(symptom)
                        }
                    }

                    HStack {
                        Image(systemName: selectedSymptom.icon)
                            .foregroundColor(selectedSymptom.color)
                        Text(selectedSymptom.urgency.rawValue)
                            .font(.subheadline)
                    }
                }

                Section("Recommended Action") {
                    Text(selectedSymptom.recommendedAction)
                        .font(.subheadline)
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Red Flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Get selected client ID
                        let alert = RedFlagAlert(
                            clientId: UUID(), // Replace with actual client
                            symptom: selectedSymptom,
                            notes: notes
                        )
                        service.addRedFlag(alert)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContraindicationDetailView: View {
    let contraindication: ContraindicationAlert
    let service: ContraindicationService

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Condition") {
                    HStack {
                        Image(systemName: contraindication.severity.icon)
                            .foregroundColor(contraindication.severity.color)
                        Text(contraindication.condition.rawValue)
                            .font(.headline)
                    }

                    Text(contraindication.severity.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("Recommendations") {
                    ForEach(contraindication.condition.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            Text(recommendation)
                                .font(.subheadline)
                        }
                    }

                    if contraindication.condition.requiresPhysicianClearance {
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundColor(.orange)
                            Text("Physician clearance required")
                                .font(.subheadline)
                                .bold()
                        }
                    }
                }

                if !contraindication.notes.isEmpty {
                    Section("Notes") {
                        Text(contraindication.notes)
                    }
                }

                Section("Details") {
                    LabeledContent("Detected", value: contraindication.detectedDate, format: .dateTime)

                    if contraindication.isResolved {
                        LabeledContent("Resolved", value: contraindication.resolvedDate ?? Date(), format: .dateTime)

                        if let action = contraindication.actionTaken {
                            LabeledContent("Action Taken") {
                                Text(action)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Contraindication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RedFlagDetailView: View {
    let redFlag: RedFlagAlert
    let service: ContraindicationService

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Symptom") {
                    HStack {
                        Image(systemName: redFlag.symptom.icon)
                            .foregroundColor(redFlag.symptom.color)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(redFlag.symptom.rawValue)
                                .font(.headline)
                            Text(redFlag.symptom.urgency.rawValue)
                                .font(.subheadline)
                                .foregroundColor(redFlag.symptom.color)
                        }
                    }
                }

                Section("Recommended Action") {
                    Text(redFlag.symptom.recommendedAction)
                        .font(.subheadline)
                }

                if !redFlag.notes.isEmpty {
                    Section("Notes") {
                        Text(redFlag.notes)
                    }
                }

                Section("Status") {
                    LabeledContent("Detected", value: redFlag.detectedDate, format: .dateTime)

                    LabeledContent("Referred") {
                        if redFlag.wasReferred {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Yes")
                            }
                        } else {
                            Text("No")
                                .foregroundColor(.secondary)
                        }
                    }

                    if let referralDetails = redFlag.referralDetails {
                        LabeledContent("Referral Details") {
                            Text(referralDetails)
                        }
                    }
                }
            }
            .navigationTitle("Red Flag Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ResolveContraindicationView: View {
    let contraindication: ContraindicationAlert
    let service: ContraindicationService

    @State private var actionTaken = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Contraindication") {
                    Text(contraindication.condition.rawValue)
                        .font(.headline)
                }

                Section("Action Taken") {
                    TextField("Describe the action taken...", text: $actionTaken, axis: .vertical)
                        .lineLimit(3...6)

                    Text("Example: Client received physician clearance, Client's condition improved, Treatment modified successfully")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Resolve Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Resolve") {
                        service.resolveContraindication(
                            id: contraindication.id,
                            actionTaken: actionTaken
                        )
                        dismiss()
                    }
                    .disabled(actionTaken.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContraindicationManagementView()
}

import SwiftUI

/// Browse and apply evidence-based treatment protocols
struct TreatmentProtocolLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: ConditionCategory? = nil
    @State private var selectedProtocol: TreatmentProtocol? = nil
    @State private var showingProtocolDetail = false

    private var filteredProtocols: [TreatmentProtocol] {
        var protocols = TreatmentProtocol.protocolLibrary

        // Filter by category
        if let category = selectedCategory {
            protocols = protocols.filter { $0.condition.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            protocols = TreatmentProtocol.search(searchText)
        }

        return protocols
    }

    private var protocolsByCategory: [(ConditionCategory, [TreatmentProtocol])] {
        let grouped = Dictionary(grouping: filteredProtocols) { $0.condition.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search protocols or conditions...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button {
                            selectedCategory = nil
                        } label: {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil
                            )
                        }

                        ForEach(ConditionCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                CategoryChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category
                                )
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))

                Divider()

                // Protocol list
                if filteredProtocols.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No protocols found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try adjusting your search or category filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(protocolsByCategory, id: \.0) { category, protocols in
                            Section {
                                ForEach(protocols) { protocol in
                                    Button {
                                        selectedProtocol = protocol
                                        showingProtocolDetail = true
                                    } label: {
                                        ProtocolRowView(protocol: protocol)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: protocols.first?.condition.icon ?? "heart.fill")
                                    Text(category.rawValue)
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Treatment Protocols")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProtocolDetail) {
                if let protocol = selectedProtocol {
                    ProtocolDetailView(protocol: protocol)
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
    }
}

// MARK: - Protocol Row

struct ProtocolRowView: View {
    let protocol: TreatmentProtocol

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: protocol.condition.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(protocol.name)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(protocol.condition.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(protocol.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 16) {
                Label("\(protocol.phases.count) phases", systemImage: "list.number")
                Label("\(protocol.homecare.count) exercises", systemImage: "figure.flexibility")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Protocol Detail View

struct ProtocolDetailView: View {
    let protocol: TreatmentProtocol
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Phases").tag(1)
                    Text("Home Care").tag(2)
                    Text("Outcomes").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            OverviewSection(protocol: protocol)
                        case 1:
                            PhasesSection(protocol: protocol)
                        case 2:
                            HomeCareSection(protocol: protocol)
                        case 3:
                            OutcomesSection(protocol: protocol)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(protocol.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // TODO: Apply protocol to client
                        } label: {
                            Label("Apply to Client", systemImage: "person.badge.plus")
                        }

                        Button {
                            // TODO: Export as PDF
                        } label: {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            // TODO: Print
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Overview Section

struct OverviewSection: View {
    let protocol: TreatmentProtocol

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Condition
            InfoCard(
                title: "Condition",
                icon: "stethoscope",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(protocol.condition.rawValue)
                        .font(.headline)
                    Text(protocol.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Assessment Findings
            InfoCard(
                title: "Typical Assessment Findings",
                icon: "checkmark.square",
                color: .purple
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(protocol.assessmentFindings, id: \.self) { finding in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(finding)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Treatment Goals
            InfoCard(
                title: "Treatment Goals",
                icon: "target",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(protocol.treatmentGoals, id: \.self) { goal in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(goal)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Contraindications
            if !protocol.contraindications.isEmpty {
                InfoCard(
                    title: "Contraindications",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(protocol.contraindications, id: \.self) { contra in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(contra)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // Precautions
            if !protocol.precautions.isEmpty {
                InfoCard(
                    title: "Precautions",
                    icon: "exclamationmark.shield.fill",
                    color: .orange
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(protocol.precautions, id: \.self) { precaution in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(precaution)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // References
            if !protocol.references.isEmpty {
                InfoCard(
                    title: "References",
                    icon: "book.fill",
                    color: .secondary
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(protocol.references, id: \.self) { reference in
                            Text(reference)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Phases Section

struct PhasesSection: View {
    let protocol: TreatmentProtocol

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(protocol.phases) { phase in
                PhaseCard(phase: phase)
            }
        }
    }
}

struct PhaseCard: View {
    let phase: TreatmentPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Phase header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(phase.phaseNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(phase.name)
                        .font(.title3.weight(.bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label(phase.duration, systemImage: "clock")
                        .font(.caption)
                    Label(phase.frequency, systemImage: "calendar")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Divider()

            // Goals
            VStack(alignment: .leading, spacing: 8) {
                Text("Goals")
                    .font(.subheadline.weight(.semibold))
                ForEach(phase.goals, id: \.self) { goal in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(goal)
                            .font(.subheadline)
                    }
                }
            }

            Divider()

            // Techniques
            VStack(alignment: .leading, spacing: 12) {
                Text("Techniques")
                    .font(.subheadline.weight(.semibold))
                ForEach(phase.techniques) { technique in
                    TechniqueRow(technique: technique)
                }
            }

            Divider()

            // Progression criteria
            VStack(alignment: .leading, spacing: 8) {
                Text("Progress to Next Phase When:")
                    .font(.subheadline.weight(.semibold))
                ForEach(phase.progressionCriteria, id: \.self) { criteria in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(criteria)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TechniqueRow: View {
    let technique: PhaseTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(technique.name)
                .font(.subheadline.weight(.medium))

            HStack(spacing: 16) {
                Label(technique.targetArea, systemImage: "mappin.and.ellipse")
                Label(technique.duration, systemImage: "clock")
                Label(technique.pressure, systemImage: "hand.raised.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if !technique.notes.isEmpty {
                Text(technique.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Home Care Section

struct HomeCareSection: View {
    let protocol: TreatmentProtocol

    private var homecareByCategory: [(HomecareCategory, [HomecareRecommendation])] {
        let grouped = Dictionary(grouping: protocol.homecare) { $0.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(homecareByCategory, id: \.0) { category, recommendations in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                        Text(category.rawValue)
                            .font(.headline)
                    }

                    ForEach(recommendations) { recommendation in
                        HomecareCard(recommendation: recommendation)
                    }
                }
            }
        }
    }
}

struct HomecareCard: View {
    let recommendation: HomecareRecommendation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            Label(recommendation.frequency, systemImage: "repeat")
                            if let duration = recommendation.duration {
                                Label(duration, systemImage: "hourglass")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Instructions")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(recommendation.instructions)
                            .font(.subheadline)
                    }

                    if !recommendation.precautions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Precautions")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange)
                            ForEach(recommendation.precautions, id: \.self) { precaution in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                    Text(precaution)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Outcomes Section

struct OutcomesSection: View {
    let protocol: TreatmentProtocol

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expected Treatment Outcomes")
                .font(.title2.weight(.bold))

            Text("These outcomes are based on evidence-based research and typical clinical responses. Individual results may vary.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(protocol.expectedOutcomes) { outcome in
                OutcomeCard(outcome: outcome)
            }
        }
    }
}

struct OutcomeCard: View {
    let outcome: ExpectedOutcome

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title2)

            VStack(alignment: .leading, spacing: 6) {
                Text(outcome.timeframe)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Text(outcome.outcome)
                    .font(.subheadline)

                if let measure = outcome.measure {
                    Text("Measured by: \(measure)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Card

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TreatmentProtocolLibraryView()
}

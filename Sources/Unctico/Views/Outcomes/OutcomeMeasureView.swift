import SwiftUI
import Charts

/// Administer and track standardized outcome measures
struct OutcomeMeasureView: View {
    @State private var selectedTab = 0
    @State private var showingMeasureSelector = false
    @State private var selectedMeasureType: MeasureType?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Measures").tag(0)
                    Text("Administer").tag(1)
                    Text("Results").tag(2)
                    Text("Trends").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedTab {
                case 0:
                    MeasuresLibraryView(
                        showingSelector: $showingMeasureSelector,
                        selectedType: $selectedMeasureType
                    )
                case 1:
                    if let measureType = selectedMeasureType {
                        AdministerMeasureView(measureType: measureType)
                    } else {
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "Select a Measure",
                            message: "Choose a measure from the library to administer it to a client"
                        )
                    }
                case 2:
                    ResultsHistoryView()
                case 3:
                    TrendsView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Outcome Tracking")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Measures Library View

struct MeasuresLibraryView: View {
    @Binding var showingSelector: Bool
    @Binding var selectedType: MeasureType?
    @State private var searchText = ""
    @State private var selectedCategory: MeasureCategory? = nil

    private var filteredMeasures: [MeasureType] {
        var measures = MeasureType.allCases

        if let category = selectedCategory {
            measures = measures.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            measures = measures.filter {
                $0.rawValue.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }

        return measures
    }

    private var measuresByCategory: [(MeasureCategory, [MeasureType])] {
        let grouped = Dictionary(grouping: filteredMeasures) { $0.category }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search measures...", text: $searchText)
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
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        )
                    }

                    ForEach(MeasureCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            CategoryFilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))

            Divider()

            // Measures list
            if filteredMeasures.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Measures Found",
                    message: "Try adjusting your search or category filter"
                )
            } else {
                List {
                    ForEach(measuresByCategory, id: \.0) { category, measures in
                        Section {
                            ForEach(measures, id: \.self) { measure in
                                Button {
                                    selectedType = measure
                                } label: {
                                    MeasureRowView(measureType: measure)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
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
    }
}

struct CategoryFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

struct MeasureRowView: View {
    let measureType: MeasureType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: measureType.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(measureType.rawValue)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(measureType.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Administer Measure View

struct AdministerMeasureView: View {
    let measureType: MeasureType
    @State private var responses: [String: Int] = [:]
    @State private var customActivities: [String] = ["", "", ""] // For PSFS
    @State private var activityRatings: [Int] = [5, 5, 5] // For PSFS
    @State private var notes: String = ""
    @State private var showingResults = false
    @Environment(\.dismiss) var dismiss

    private var scale: OutcomeScale {
        OutcomeScale.getScale(for: measureType)
    }

    private var canSubmit: Bool {
        // Check if all questions are answered
        if measureType == .psfs {
            return customActivities.filter { !$0.isEmpty }.count >= 3
        }
        return responses.count == scale.questions.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: measureType.icon)
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text(measureType.rawValue)
                        .font(.title3.weight(.bold))
                }
                Text(measureType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))

            // Questions
            ScrollView {
                VStack(spacing: 20) {
                    if measureType == .psfs {
                        PSFSQuestionsView(
                            activities: $customActivities,
                            ratings: $activityRatings
                        )
                    } else {
                        ForEach(Array(scale.questions.enumerated()), id: \.element.id) { index, question in
                            QuestionCard(
                                question: question,
                                questionNumber: index + 1,
                                selectedOption: Binding(
                                    get: { responses[question.id] },
                                    set: { responses[question.id] = $0 }
                                )
                            )
                        }
                    }

                    // Notes section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes (Optional)")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }

            // Submit button
            Button {
                submitMeasure()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Assessment")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canSubmit)
            .padding()
        }
        .sheet(isPresented: $showingResults) {
            ResultsView(measureType: measureType, responses: responses)
        }
    }

    private func submitMeasure() {
        // TODO: Save to repository
        var measure = OutcomeMeasure(
            clientId: UUID(), // TODO: Get from context
            measureType: measureType,
            responses: responses,
            notes: notes.isEmpty ? nil : notes
        )
        measure.calculateScore()
        showingResults = true
    }
}

// MARK: - Question Card

struct QuestionCard: View {
    let question: OutcomeQuestion
    let questionNumber: Int
    @Binding var selectedOption: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question header
            HStack(alignment: .top) {
                Text("\(questionNumber).")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(question.text)
                    .font(.headline)
            }

            // Options
            if question.options.isEmpty {
                // Special handling for PSFS instructions
                Text(question.text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        Button {
                            selectedOption = index
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedOption == index ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedOption == index ? .blue : .gray)
                                    .font(.title3)

                                Text(option)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding()
                            .background(selectedOption == index ? Color.blue.opacity(0.1) : Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - PSFS Questions View

struct PSFSQuestionsView: View {
    @Binding var activities: [String]
    @Binding var ratings: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identify 3-5 activities that are difficult for you")
                .font(.headline)

            Text("Rate your ability to perform each activity:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("0 = Unable to perform")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("10 = Able to perform at prior level")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(0..<3) { index in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity \(index + 1)")
                        .font(.subheadline.weight(.semibold))

                    TextField("Describe activity...", text: $activities[index])
                        .textFieldStyle(.roundedBorder)

                    if !activities[index].isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current ability:")
                                Spacer()
                                Text("\(ratings[index])/10")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }

                            Slider(value: Binding(
                                get: { Double(ratings[index]) },
                                set: { ratings[index] = Int($0) }
                            ), in: 0...10, step: 1)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Results View

struct ResultsView: View {
    let measureType: MeasureType
    let responses: [String: Int]
    @State private var measure: OutcomeMeasure
    @Environment(\.dismiss) var dismiss

    init(measureType: MeasureType, responses: [String: Int]) {
        self.measureType = measureType
        self.responses = responses
        var tempMeasure = OutcomeMeasure(
            clientId: UUID(),
            measureType: measureType,
            responses: responses
        )
        tempMeasure.calculateScore()
        _measure = State(initialValue: tempMeasure)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Score card
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Assessment Complete")
                            .font(.title2.weight(.bold))

                        VStack(spacing: 8) {
                            Text("Total Score")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("\(measure.totalScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        Text(measure.interpretation)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding()

                    // Interpretation
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Clinical Interpretation", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text(measure.interpretation)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Recommendations", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("Consider re-assessment in 4-6 weeks to track progress. Combine with functional assessments and client feedback for comprehensive outcome tracking.")
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            // TODO: Save to repository
                            dismiss()
                        } label: {
                            Label("Save to Client Record", systemImage: "folder.badge.plus")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }

                        Button {
                            // TODO: Share/Export
                        } label: {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Results History View

struct ResultsHistoryView: View {
    @State private var measures: [OutcomeMeasure] = [] // TODO: Load from repository

    var body: some View {
        if measures.isEmpty {
            EmptyStateView(
                icon: "chart.bar.doc.horizontal",
                title: "No Results Yet",
                message: "Administered assessments will appear here"
            )
        } else {
            List {
                ForEach(measures) { measure in
                    ResultHistoryRow(measure: measure)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct ResultHistoryRow: View {
    let measure: OutcomeMeasure

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: measure.measureType.icon)
                    .foregroundColor(.blue)

                Text(measure.measureType.rawValue)
                    .font(.headline)

                Spacer()

                Text("\(measure.totalScore)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.blue)
            }

            Text(measure.administeredDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(measure.interpretation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trends View

struct TrendsView: View {
    @State private var measures: [OutcomeMeasure] = [] // TODO: Load from repository
    @State private var selectedMeasureType: MeasureType?

    var body: some View {
        if measures.isEmpty {
            EmptyStateView(
                icon: "chart.line.uptrend.xyaxis",
                title: "No Trend Data",
                message: "Complete multiple assessments to see progress trends"
            )
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    // Measure type picker
                    Picker("Measure Type", selection: $selectedMeasureType) {
                        Text("All").tag(nil as MeasureType?)
                        ForEach(MeasureType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as MeasureType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()

                    // TODO: Add chart showing score progression over time
                    Text("Chart visualization coming soon")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Empty State View

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
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    OutcomeMeasureView()
}

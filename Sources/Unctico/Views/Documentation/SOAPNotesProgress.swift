import SwiftUI
import Charts

/// Progress tracking, modality usage, and client feedback components

// MARK: - Progress Tracking Visualization
struct ProgressTrackingView: View {
    let clientHistory: [SOAPNote]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Progress Over Time")
                .font(.title2)
                .fontWeight(.bold)

            if clientHistory.isEmpty {
                EmptyProgressView()
            } else {
                // Pain Trend Chart
                PainTrendChart(history: clientHistory)

                // Key Metrics Grid
                ProgressMetricsGrid(history: clientHistory)

                // Session Comparison
                SessionComparisonView(history: clientHistory)

                // Goal Progress
                GoalProgressView(history: clientHistory)
            }
        }
    }
}

struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Progress Data Yet")
                .font(.headline)

            Text("Complete at least 2 sessions to see progress tracking")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Pain Trend Chart
struct PainTrendChart: View {
    let history: [SOAPNote]

    private var painData: [(Date, Int)] {
        history
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.subjective.painLevel) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.tranquilTeal)
                Text("Pain Level Trend")
                    .font(.headline)
            }

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(painData.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("Session", index + 1),
                            y: .value("Pain", data.1)
                        )
                        .foregroundStyle(Color.tranquilTeal)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Session", index + 1),
                            y: .value("Pain", data.1)
                        )
                        .foregroundStyle(Color.tranquilTeal)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...10)
            } else {
                // Fallback for iOS 15
                SimplePainChart(data: painData)
            }

            // Summary
            if let first = painData.first, let last = painData.last {
                let improvement = first.1 - last.1
                HStack {
                    if improvement > 0 {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Pain reduced by \(improvement) points")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if improvement < 0 {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                        Text("Pain increased by \(abs(improvement)) points")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "equal.circle.fill")
                            .foregroundColor(.orange)
                        Text("Pain level stable")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SimplePainChart: View {
    let data: [(Date, Int)]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Background grid
                ForEach(0...10, id: \.self) { level in
                    let y = height - (CGFloat(level) / 10.0 * height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // Pain line
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                        let y = height - (CGFloat(point.1) / 10.0 * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.tranquilTeal, lineWidth: 3)

                // Points
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                    let y = height - (CGFloat(point.1) / 10.0 * height)

                    Circle()
                        .fill(Color.tranquilTeal)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Progress Metrics Grid
struct ProgressMetricsGrid: View {
    let history: [SOAPNote]

    private var metrics: ProgressMetrics {
        calculateMetrics(from: history)
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Total Sessions",
                value: "\(history.count)",
                icon: "calendar",
                color: .blue
            )

            MetricCard(
                title: "Avg Pain Level",
                value: String(format: "%.1f/10", metrics.averagePain),
                icon: "exclamationmark.triangle",
                color: .orange
            )

            MetricCard(
                title: "Areas Worked",
                value: "\(metrics.uniqueAreasWorked)",
                icon: "figure.walk",
                color: .green
            )

            MetricCard(
                title: "Improvement",
                value: "\(metrics.improvementPercentage)%",
                icon: metrics.improvementPercentage > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                color: metrics.improvementPercentage > 0 ? .green : .red
            )
        }
    }

    private func calculateMetrics(from history: [SOAPNote]) -> ProgressMetrics {
        let totalPain = history.reduce(0) { $0 + $1.subjective.painLevel }
        let avgPain = history.isEmpty ? 0.0 : Double(totalPain) / Double(history.count)

        let allAreas = history.flatMap { $0.objective.areasWorked }
        let uniqueAreas = Set(allAreas.map { $0.displayName }).count

        var improvement = 0
        if history.count >= 2 {
            let sorted = history.sorted { $0.date < $1.date }
            let first = sorted.first!.subjective.painLevel
            let last = sorted.last!.subjective.painLevel
            let change = first - last
            improvement = first > 0 ? Int((Double(change) / Double(first)) * 100) : 0
        }

        return ProgressMetrics(
            averagePain: avgPain,
            uniqueAreasWorked: uniqueAreas,
            improvementPercentage: improvement
        )
    }
}

struct ProgressMetrics {
    let averagePain: Double
    let uniqueAreasWorked: Int
    let improvementPercentage: Int
}

struct MetricCard: View {
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
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Session Comparison View
struct SessionComparisonView: View {
    let history: [SOAPNote]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            if history.count >= 2 {
                let recent = Array(history.sorted { $0.date > $1.date }.prefix(3))

                ForEach(recent) { note in
                    SessionComparisonCard(note: note)
                }
            }
        }
    }
}

struct SessionComparisonCard: View {
    let note: SOAPNote

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Pain: \(note.subjective.painLevel)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(note.objective.areasWorked.count) areas treated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Goal Progress View
struct GoalProgressView: View {
    let history: [SOAPNote]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Treatment Goals")
                .font(.headline)

            if let latestNote = history.sorted(by: { $0.date > $1.date }).first,
               !latestNote.subjective.patientGoals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(latestNote.subjective.patientGoals)
                        .font(.subheadline)

                    ProgressView(value: 0.6)
                        .tint(.tranquilTeal)

                    Text("60% towards goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Modality Usage Tracker
struct ModalityTrackerView: View {
    @Binding var modalitiesUsed: [ModalityUsed]
    @State private var showingAddModality = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Modalities Used")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddModality = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.tranquilTeal)
                }
            }

            if modalitiesUsed.isEmpty {
                Text("No modalities recorded for this session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(modalitiesUsed) { modality in
                    ModalityCard(modality: modality) {
                        modalitiesUsed.removeAll { $0.id == modality.id }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddModality) {
            AddModalityView(modalities: $modalitiesUsed)
        }
    }
}

struct ModalityCard: View {
    let modality: ModalityUsed
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: modality.modality.icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(modality.modality.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if modality.duration > 0 {
                    Text("\(Int(modality.duration / 60)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !modality.notes.isEmpty {
                    Text(modality.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddModalityView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var modalities: [ModalityUsed]

    @State private var selectedModality: Modality = .heat
    @State private var duration: Double = 10 // minutes
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Modality Type") {
                    Picker("Select Modality", selection: $selectedModality) {
                        ForEach(Modality.allCases, id: \.self) { modality in
                            HStack {
                                Image(systemName: modality.icon)
                                Text(modality.rawValue)
                            }
                            .tag(modality)
                        }
                    }
                }

                Section("Duration") {
                    HStack {
                        Text("\(Int(duration)) minutes")
                            .font(.headline)
                        Spacer()
                    }

                    Slider(value: $duration, in: 1...60, step: 1)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Modality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newModality = ModalityUsed(
                            modality: selectedModality,
                            duration: duration * 60, // Convert to seconds
                            notes: notes
                        )
                        modalities.append(newModality)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Client Feedback Capture System
struct ClientFeedbackView: View {
    @Binding var feedback: ClientFeedback
    @State private var showingFeedbackForm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.bubble")
                    .foregroundColor(.orange)
                Text("Client Feedback")
                    .font(.headline)

                Spacer()

                if !feedback.hasResponded {
                    Button(action: { showingFeedbackForm = true }) {
                        Text("Capture")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.tranquilTeal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }

            if feedback.hasResponded {
                FeedbackSummaryCard(feedback: feedback)
            } else {
                Text("No feedback captured yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingFeedbackForm) {
            ClientFeedbackFormView(feedback: $feedback)
        }
    }
}

struct ClientFeedback: Codable {
    var overallSatisfaction: Int = 0 // 1-5 stars
    var pressureRating: PressureRating = .perfect
    var areasOfFocus: String = ""
    var painRelief: Int = 0 // 0-10
    var wouldRecommend: Bool = false
    var comments: String = ""
    var timestamp: Date?

    var hasResponded: Bool {
        timestamp != nil
    }

    enum PressureRating: String, Codable, CaseIterable {
        case tooLight = "Too Light"
        case slightlyLight = "Slightly Light"
        case perfect = "Perfect"
        case slightlyFirm = "Slightly Firm"
        case tooFirm = "Too Firm"
    }
}

struct FeedbackSummaryCard: View {
    let feedback: ClientFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Star Rating
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= feedback.overallSatisfaction ? "star.fill" : "star")
                        .foregroundColor(.orange)
                }

                Spacer()

                if let timestamp = feedback.timestamp {
                    Text(timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Pressure Rating
            HStack {
                Text("Pressure:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(feedback.pressureRating.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Pain Relief
            HStack {
                Text("Pain Relief:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(feedback.painRelief)/10")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Recommendation
            if feedback.wouldRecommend {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                    Text("Would recommend")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Comments
            if !feedback.comments.isEmpty {
                Text(feedback.comments)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ClientFeedbackFormView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var feedback: ClientFeedback

    @State private var satisfaction: Int = 5
    @State private var pressureRating: ClientFeedback.PressureRating = .perfect
    @State private var painRelief: Int = 8
    @State private var wouldRecommend = true
    @State private var comments = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Overall Satisfaction") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                satisfaction = star
                            }) {
                                Image(systemName: star <= satisfaction ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Pressure Level") {
                    Picker("How was the pressure?", selection: $pressureRating) {
                        ForEach(ClientFeedback.PressureRating.allCases, id: \.self) { rating in
                            Text(rating.rawValue).tag(rating)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Pain Relief") {
                    HStack {
                        Text("0")
                        Slider(value: Binding(
                            get: { Double(painRelief) },
                            set: { painRelief = Int($0) }
                        ), in: 0...10, step: 1)
                        Text("10")
                    }

                    Text("Pain relief: \(painRelief)/10")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section {
                    Toggle("Would you recommend this treatment?", isOn: $wouldRecommend)
                }

                Section("Additional Comments") {
                    TextEditor(text: $comments)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Session Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        feedback.overallSatisfaction = satisfaction
                        feedback.pressureRating = pressureRating
                        feedback.painRelief = painRelief
                        feedback.wouldRecommend = wouldRecommend
                        feedback.comments = comments
                        feedback.timestamp = Date()
                        dismiss()
                    }
                }
            }
        }
    }
}

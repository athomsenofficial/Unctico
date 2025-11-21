import SwiftUI
import Charts

/// Interactive session timer for tracking massage treatment in real-time
struct SessionTimerView: View {
    @StateObject private var service = SessionTimerService()
    @State private var showingSegmentSelection = false
    @State private var showingNoteEntry = false
    @State private var noteText = ""
    @State private var showingSummary = false
    @State private var sessionSummary: SessionSummary?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Timer display
                timerDisplay

                Divider()

                // Current segment info
                if let segment = service.currentSegment {
                    currentSegmentView(segment)
                        .padding()
                    Divider()
                }

                // Segments list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !service.completedSegments.isEmpty {
                            ForEach(service.completedSegments) { segment in
                                SegmentCard(segment: segment)
                            }
                        }

                        if service.completedSegments.isEmpty && service.currentSegment == nil {
                            EmptySessionStateView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Session Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if service.isRunning {
                        Button {
                            service.pauseSession()
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                        }
                    } else if service.elapsedTime > 0 {
                        Button {
                            service.resumeSession()
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if !service.isRunning && service.elapsedTime == 0 {
                            Button {
                                service.startSession()
                            } label: {
                                Label("Start Session", systemImage: "play.fill")
                            }
                        }

                        if service.elapsedTime > 0 {
                            Button {
                                showingSegmentSelection = true
                            } label: {
                                Label("New Segment", systemImage: "plus.circle")
                            }

                            Button {
                                showingNoteEntry = true
                            } label: {
                                Label("Add Note", systemImage: "note.text")
                            }

                            Divider()

                            Button(role: .destructive) {
                                sessionSummary = service.endSession()
                                showingSummary = true
                            } label: {
                                Label("End Session", systemImage: "stop.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSegmentSelection) {
                SegmentSelectionView(service: service)
            }
            .sheet(isPresented: $showingNoteEntry) {
                NoteEntryView(noteText: $noteText) {
                    service.addNote(noteText)
                    noteText = ""
                    showingNoteEntry = false
                }
            }
            .sheet(isPresented: $showingSummary) {
                if let summary = sessionSummary {
                    SessionSummaryView(summary: summary)
                }
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(formatTime(service.elapsedTime))
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(service.isRunning ? .blue : .secondary)

            HStack(spacing: 16) {
                if service.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if service.elapsedTime > 0 {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Ready to start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
    }

    private func currentSegmentView(_ segment: TreatmentSegment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Segment")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Image(systemName: segment.technique.icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(segment.bodyArea.rawValue)
                        .font(.headline)

                    HStack(spacing: 12) {
                        Text(segment.technique.rawValue)
                            .font(.caption)

                        Circle()
                            .fill(segment.pressure.color)
                            .frame(width: 8, height: 8)

                        Text(segment.pressure.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Text(segment.formattedDuration)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct SegmentCard: View {
    let segment: TreatmentSegment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: segment.technique.icon)
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(segment.bodyArea.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(segment.technique.rawValue)
                        .font(.caption)

                    Circle()
                        .fill(segment.pressure.color)
                        .frame(width: 6, height: 6)

                    Text(segment.pressure.rawValue)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                if !segment.notes.isEmpty {
                    Text(segment.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(segment.formattedDuration)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SegmentSelectionView: View {
    let service: SessionTimerService

    @State private var selectedArea: BodyLocation = .back
    @State private var selectedTechnique: MassageTechnique = .swedish
    @State private var selectedPressure: PressureLevel = .moderate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Body Area") {
                    Picker("Area", selection: $selectedArea) {
                        ForEach(BodyLocation.allCases, id: \.self) { area in
                            Text(area.rawValue).tag(area)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Technique") {
                    Picker("Technique", selection: $selectedTechnique) {
                        ForEach(MassageTechnique.allCases, id: \.self) { technique in
                            Label(technique.rawValue, systemImage: technique.icon).tag(technique)
                        }
                    }
                }

                Section("Pressure Level") {
                    Picker("Pressure", selection: $selectedPressure) {
                        ForEach(PressureLevel.allCases, id: \.self) { pressure in
                            HStack {
                                Circle()
                                    .fill(pressure.color)
                                    .frame(width: 12, height: 12)
                                Text(pressure.rawValue)
                            }
                            .tag(pressure)
                        }
                    }
                }
            }
            .navigationTitle("New Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        service.startSegment(
                            bodyArea: selectedArea,
                            technique: selectedTechnique,
                            pressure: selectedPressure
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NoteEntryView: View {
    @Binding var noteText: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Note") {
                    TextField("Enter note...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(noteText.isEmpty)
                }
            }
        }
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Duration")
                            .font(.headline)

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)

                            Text(summary.formattedDuration)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Segments
                    if !summary.segments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Treatment Segments (\(summary.segments.count))")
                                .font(.headline)

                            ForEach(summary.segments) { segment in
                                SegmentCard(segment: segment)
                            }
                        }
                    }

                    // Notes
                    if !summary.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Notes")
                                .font(.headline)

                            ForEach(summary.notes) { note in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(note.formattedTimestamp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 50, alignment: .leading)

                                    Text(note.text)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }

                    // SOAP Note Generation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SOAP Note Findings")
                            .font(.headline)

                        Text(summary.generateObjectiveFindings())
                            .font(.subheadline)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // TODO: Export to SOAP note
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct EmptySessionStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Session Active")
                .font(.headline)

            Text("Start a session to track treatment time and details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    SessionTimerView()
}

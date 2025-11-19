import SwiftUI
import Speech

struct DocumentationView: View {
    @ObservedObject private var repository = SOAPNoteRepository.shared
    @State private var showingNewNote = false

    var body: some View {
        NavigationView {
            VStack {
                if repository.soapNotes.isEmpty {
                    EmptyStateView(message: "No SOAP notes yet")
                        .padding()
                } else {
                    List {
                        ForEach(repository.soapNotes.sorted(by: { $0.date > $1.date })) { note in
                            NavigationLink(destination: SOAPNoteDetailView(note: note)) {
                                SOAPNoteRowView(note: note)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("SOAP Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NewSOAPNoteView()
            }
        }
    }
}

struct SOAPNoteRowView: View {
    let note: SOAPNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.date, style: .date)
                    .font(.headline)

                Spacer()

                Text(note.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !note.subjective.chiefComplaint.isEmpty {
                Text(note.subjective.chiefComplaint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                if note.subjective.painLevel > 0 {
                    Label("\(note.subjective.painLevel)/10", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if !note.objective.areasWorked.isEmpty {
                    Label("\(note.objective.areasWorked.count) areas", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.tranquilTeal)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct NewSOAPNoteView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = SOAPNoteRepository.shared

    @State private var currentSection: SOAPSection = .subjective
    @State private var note = SOAPNote(clientId: UUID(), sessionId: UUID())

    enum SOAPSection: String, CaseIterable {
        case subjective = "Subjective"
        case objective = "Objective"
        case assessment = "Assessment"
        case plan = "Plan"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SOAPSectionPicker(selection: $currentSection)
                    .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        switch currentSection {
                        case .subjective:
                            SubjectiveSection(subjective: $note.subjective)
                        case .objective:
                            ObjectiveSection(objective: $note.objective)
                        case .assessment:
                            AssessmentSection(assessment: $note.assessment)
                        case .plan:
                            PlanSection(plan: $note.plan)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                }
            }
        }
    }

    private func saveNote() {
        repository.addSOAPNote(note)
        dismiss()
    }
}

struct SOAPSectionPicker: View {
    @Binding var selection: NewSOAPNoteView.SOAPSection

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NewSOAPNoteView.SOAPSection.allCases, id: \.self) { section in
                    SectionTab(title: section.rawValue, isSelected: selection == section) {
                        selection = section
                    }
                }
            }
        }
    }
}

struct SectionTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .tranquilTeal : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.tranquilTeal : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SubjectiveSection: View {
    @Binding var subjective: Subjective
    @State private var isRecording = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCard(title: "Chief Complaint", icon: "text.bubble.fill") {
                VStack(spacing: 12) {
                    TextEditor(text: $subjective.chiefComplaint)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    VoiceInputButton(text: $subjective.chiefComplaint, isRecording: $isRecording)
                }
            }

            SectionCard(title: "Pain Level", icon: "exclamationmark.triangle.fill") {
                VStack(spacing: 8) {
                    HStack {
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(value: Binding(
                            get: { Double(subjective.painLevel) },
                            set: { subjective.painLevel = Int($0) }
                        ), in: 0...10, step: 1)

                        Text("10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(subjective.painLevel)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(painColor(for: subjective.painLevel))
                }
            }

            SectionCard(title: "Sleep Quality", icon: "bed.double.fill") {
                Picker("Sleep Quality", selection: $subjective.sleepQuality) {
                    ForEach(Subjective.SleepQuality.allCases, id: \.self) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .pickerStyle(.segmented)
            }

            SectionCard(title: "Stress Level", icon: "brain.head.profile") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(value: Binding(
                            get: { Double(subjective.stressLevel) },
                            set: { subjective.stressLevel = Int($0) }
                        ), in: 1...10, step: 1)

                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(subjective.stressLevel)/10")
                        .font(.headline)
                }
            }

            SectionCard(title: "Additional Notes", icon: "note.text") {
                TextEditor(text: $subjective.voiceNotes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }

    private func painColor(for level: Int) -> Color {
        switch level {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
}

struct ObjectiveSection: View {
    @Binding var objective: Objective

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCard(title: "Areas Worked", icon: "figure.walk") {
                Text("Interactive body map would go here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            SectionCard(title: "Palpation Findings", icon: "hand.raised.fill") {
                TextEditor(text: $objective.palpationFindings)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Tissue Texture", icon: "waveform.path") {
                TextEditor(text: $objective.tissueTexture)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Posture Findings", icon: "figure.stand") {
                TextEditor(text: $objective.postureFindings)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

struct AssessmentSection: View {
    @Binding var assessment: Assessment

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCard(title: "Clinical Reasoning", icon: "brain") {
                TextEditor(text: $assessment.clinicalReasoning)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Progress Notes", icon: "chart.line.uptrend.xyaxis") {
                TextEditor(text: $assessment.progressNotes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Treatment Response", icon: "checkmark.seal.fill") {
                Picker("Response", selection: $assessment.treatmentResponse) {
                    ForEach(Assessment.TreatmentResponse.allCases, id: \.self) { response in
                        Text(response.rawValue).tag(response)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

struct PlanSection: View {
    @Binding var plan: Plan

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCard(title: "Treatment Frequency", icon: "calendar.badge.clock") {
                TextField("e.g., 1-2 times per week", text: $plan.treatmentFrequency)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Home Care Instructions", icon: "house.fill") {
                TextEditor(text: Binding(
                    get: { plan.homeCareInstructions.joined(separator: "\n") },
                    set: { plan.homeCareInstructions = $0.components(separatedBy: "\n") }
                ))
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            SectionCard(title: "Next Session Focus", icon: "target") {
                TextField("Focus areas for next visit", text: $plan.nextSessionFocus)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            SectionCard(title: "Follow-up Date", icon: "calendar.badge.checkmark") {
                DatePicker("Follow-up", selection: Binding(
                    get: { plan.followUpDate ?? Date() },
                    set: { plan.followUpDate = $0 }
                ), displayedComponents: .date)
                .padding(.horizontal)
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.tranquilTeal)

                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct VoiceInputButton: View {
    @Binding var text: String
    @Binding var isRecording: Bool
    @StateObject private var speechService = SpeechRecognitionService.shared

    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .foregroundColor(isRecording ? .red : .tranquilTeal)

                Text(isRecording ? "Stop Recording" : "Voice Input")
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isRecording ? Color.red.opacity(0.1) : Color.tranquilTeal.opacity(0.1))
            .cornerRadius(10)
        }
    }

    private func toggleRecording() {
        if isRecording {
            speechService.stopRecording()
            isRecording = false
        } else {
            speechService.requestAuthorization { authorized in
                guard authorized else {
                    print("Speech recognition not authorized")
                    return
                }

                do {
                    try speechService.startRecording { recognizedText in
                        text = recognizedText
                    }
                    isRecording = true
                } catch {
                    print("Error starting recording: \(error)")
                    isRecording = false
                }
            }
        }
    }
}

struct SOAPNoteDetailView: View {
    let note: SOAPNote

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SOAP Note Detail View")
                    .font(.headline)
            }
            .padding()
        }
        .navigationTitle("SOAP Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

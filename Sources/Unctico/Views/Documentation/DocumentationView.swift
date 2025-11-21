import Combine
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
    @State private var showQuickPhrases = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionCard(title: "Chief Complaint", icon: "text.bubble.fill") {
                VStack(spacing: 12) {
                    TextEditor(text: $subjective.chiefComplaint)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    HStack(spacing: 12) {
                        VoiceInputButton(text: $subjective.chiefComplaint, isRecording: $isRecording)

                        Button(action: { showQuickPhrases.toggle() }) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.tranquilTeal)
                                Text("Quick Phrases")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.tranquilTeal.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }

                    if showQuickPhrases {
                        QuickPhrasesView(selectedText: $subjective.chiefComplaint)
                    }
                }
            }

            SectionCard(title: "Pain Level", icon: "exclamationmark.triangle.fill") {
                VStack(spacing: 16) {
                    // Visual Pain Scale with Faces
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0...10, id: \.self) { level in
                                PainFaceButton(level: level, isSelected: subjective.painLevel == level) {
                                    subjective.painLevel = level
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Traditional Slider (backup)
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

                    HStack {
                        Text("\(subjective.painLevel)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(painColor(for: subjective.painLevel))

                        Spacer()

                        Text(painDescription(for: subjective.painLevel))
                            .font(.headline)
                            .foregroundColor(painColor(for: subjective.painLevel))
                    }
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

    private func painDescription(for level: Int) -> String {
        switch level {
        case 0: return "No Pain"
        case 1...2: return "Mild"
        case 3...4: return "Moderate"
        case 5...6: return "Uncomfortable"
        case 7...8: return "Severe"
        case 9...10: return "Extreme"
        default: return ""
        }
    }
}

struct ObjectiveSection: View {
    @Binding var objective: Objective
    @State private var sessionDuration: TimeInterval = 0
    @State private var selectedTechniques: [MassageTechnique] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Interactive Body Diagram
            InteractiveBodyDiagramView(selectedAreas: $objective.areasWorked)

            // Session Timer
            SessionTimerView(duration: $sessionDuration)

            // Technique Checklist
            TechniqueChecklistView(selectedTechniques: $selectedTechniques)

            // Palpation Findings
            SectionCard(title: "Palpation Findings", icon: "hand.raised.fill") {
                TextEditor(text: $objective.palpationFindings)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Muscle Tension Grading
            SectionCard(title: "Muscle Tension (1-5 Scale)", icon: "flame.fill") {
                VStack(spacing: 12) {
                    ForEach(objective.areasWorked, id: \.displayName) { area in
                        HStack {
                            Text(area.displayName)
                                .font(.subheadline)

                            Spacer()

                            ForEach(1...5, id: \.self) { level in
                                Button(action: {
                                    updateTensionLevel(for: area, level: level)
                                }) {
                                    Circle()
                                        .fill(tensionForArea(area) == level ? Color.orange : Color.gray.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text("\(level)")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                    }

                    if objective.areasWorked.isEmpty {
                        Text("Select areas on the body diagram above to grade muscle tension")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }

            // Tissue Texture
            SectionCard(title: "Tissue Texture", icon: "waveform.path") {
                TextEditor(text: $objective.tissueTexture)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Posture Findings
            SectionCard(title: "Posture Findings", icon: "figure.stand") {
                TextEditor(text: $objective.postureFindings)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }

    private func updateTensionLevel(for area: BodyLocation, level: Int) {
        // Remove existing tension reading for this area
        objective.muscleTension.removeAll { $0.location.displayName == area.displayName }
        // Add new tension reading
        objective.muscleTension.append(
            Objective.MuscleTensionReading(location: area, tensionLevel: level)
        )
    }

    private func tensionForArea(_ area: BodyLocation) -> Int? {
        objective.muscleTension.first { $0.location.displayName == area.displayName }?.tensionLevel
    }
}

struct AssessmentSection: View {
    @Binding var assessment: Assessment
    @State private var showingContraindicationPicker = false
    @State private var newContraindication = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Contraindication Alerts (CRITICAL SAFETY FEATURE)
            ContraindicationAlertView(contraindications: assessment.contraindications)

            SectionCard(title: "Contraindications & Safety Alerts", icon: "exclamationmark.shield.fill") {
                VStack(spacing: 12) {
                    // Add contraindication button
                    Button(action: { showingContraindicationPicker.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("Add Contraindication")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Common contraindications quick-add
                    if showingContraindicationPicker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common Contraindications:")
                                .font(.caption)
                                .fontWeight(.semibold)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(CommonContraindications.all, id: \.self) { contraindication in
                                    Button(action: {
                                        if !assessment.contraindications.contains(contraindication) {
                                            assessment.contraindications.append(contraindication)
                                        }
                                    }) {
                                        Text(contraindication)
                                            .font(.caption)
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                assessment.contraindications.contains(contraindication) ?
                                                Color.red.opacity(0.2) : Color.gray.opacity(0.1)
                                            )
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Currently selected contraindications
                    if !assessment.contraindications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Contraindications:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)

                            ForEach(assessment.contraindications, id: \.self) { contraindication in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)

                                    Text(contraindication)
                                        .font(.caption)

                                    Spacer()

                                    Button(action: {
                                        assessment.contraindications.removeAll { $0 == contraindication }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }

            // ICD-10 Codes
            SectionCard(title: "Diagnosis Codes (ICD-10)", icon: "cross.case.fill") {
                VStack(spacing: 12) {
                    ForEach(assessment.icdCodes, id: \.self) { code in
                        HStack {
                            Text(code)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Button(action: {
                                assessment.icdCodes.removeAll { $0 == code }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }

                    Button(action: {
                        // TODO: Implement ICD-10 code selector
                        assessment.icdCodes.append("M79.1 - Myalgia")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.tranquilTeal)
                            Text("Add ICD-10 Code")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.tranquilTeal.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }

            // Clinical Reasoning
            SectionCard(title: "Clinical Reasoning", icon: "brain") {
                TextEditor(text: $assessment.clinicalReasoning)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Progress Notes
            SectionCard(title: "Progress Notes", icon: "chart.line.uptrend.xyaxis") {
                TextEditor(text: $assessment.progressNotes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            // Treatment Response
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

// MARK: - Common Contraindications
struct CommonContraindications {
    static let all: [String] = [
        "Acute Inflammation",
        "Fever/Infection",
        "Recent Surgery (<6 weeks)",
        "Blood Clot/DVT",
        "Uncontrolled Hypertension",
        "Skin Condition/Rash",
        "Pregnancy (1st trimester)",
        "Cancer (without clearance)",
        "Severe Osteoporosis",
        "Open Wounds",
        "Recent Fracture",
        "Acute Injury (<72 hours)"
    ]
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

// MARK: - Pain Face Button
struct PainFaceButton: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(painEmoji(for: level))
                    .font(.system(size: 32))

                Text("\(level)")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 60, height: 70)
            .background(isSelected ? painColor(for: level) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(painColor(for: level), lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func painEmoji(for level: Int) -> String {
        switch level {
        case 0: return "😊"
        case 1: return "🙂"
        case 2: return "😐"
        case 3: return "😕"
        case 4: return "😟"
        case 5: return "😣"
        case 6: return "😖"
        case 7: return "😫"
        case 8: return "😩"
        case 9: return "😭"
        case 10: return "😱"
        default: return "😐"
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

// MARK: - Quick Phrases View
struct QuickPhrasesView: View {
    @Binding var selectedText: String
    private let library = QuickPhrasesLibrary.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(PhraseCategory.allCases, id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.tranquilTeal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(library.getPhrases(for: category), id: \.self) { phrase in
                                Button(action: {
                                    if !selectedText.isEmpty && !selectedText.hasSuffix(" ") && !selectedText.hasSuffix("\n") {
                                        selectedText += " "
                                    }
                                    selectedText += phrase
                                    if !phrase.hasSuffix(".") {
                                        selectedText += "."
                                    }
                                }) {
                                    Text(phrase)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.tranquilTeal.opacity(0.15))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Interactive Body Diagram
struct InteractiveBodyDiagramView: View {
    @Binding var selectedAreas: [BodyLocation]
    @State private var annotations: [BodyDiagramAnnotation] = []

    var body: some View {
        VStack(spacing: 16) {
            Text("Tap body regions to mark areas")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                // Front View
                VStack(spacing: 8) {
                    Text("Front")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ZStack {
                        // Body outline (simplified)
                        BodyOutlineFront()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 150, height: 300)

                        // Clickable regions
                        BodyRegionButtons(side: .front, selectedAreas: $selectedAreas)
                    }
                }

                // Back View
                VStack(spacing: 8) {
                    Text("Back")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ZStack {
                        BodyOutlineBack()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 150, height: 300)

                        BodyRegionButtons(side: .back, selectedAreas: $selectedAreas)
                    }
                }
            }

            // Selected Areas List
            if !selectedAreas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Areas:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedAreas, id: \.displayName) { area in
                                HStack(spacing: 4) {
                                    Text(area.displayName)
                                        .font(.caption)

                                    Button(action: {
                                        selectedAreas.removeAll { $0.displayName == area.displayName }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.tranquilTeal.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Body Outline Shapes
struct BodyOutlineFront: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Head
        path.addEllipse(in: CGRect(x: width * 0.35, y: 0, width: width * 0.3, height: height * 0.1))

        // Neck
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.15))
        path.move(to: CGPoint(x: width * 0.55, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.15))

        // Torso
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.6))
        path.move(to: CGPoint(x: width * 0.8, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.6))

        // Arms
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.5))
        path.move(to: CGPoint(x: width * 0.8, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.5))

        // Legs
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.4, y: height))
        path.move(to: CGPoint(x: width * 0.65, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.6, y: height))

        return path
    }
}

struct BodyOutlineBack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Head
        path.addEllipse(in: CGRect(x: width * 0.35, y: 0, width: width * 0.3, height: height * 0.1))

        // Neck
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.15))
        path.move(to: CGPoint(x: width * 0.55, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.15))

        // Back/Torso
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.6))
        path.move(to: CGPoint(x: width * 0.8, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.6))

        // Arms
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.5))
        path.move(to: CGPoint(x: width * 0.8, y: height * 0.15))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.5))

        // Legs
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.4, y: height))
        path.move(to: CGPoint(x: width * 0.65, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.6, y: height))

        return path
    }
}

// MARK: - Body Region Buttons
struct BodyRegionButtons: View {
    enum BodySide {
        case front, back
    }

    let side: BodySide
    @Binding var selectedAreas: [BodyLocation]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if side == .front {
                    // Front view regions
                    bodyRegionButton(region: .neck, bodyX: 0.5, bodyY: 0.12, geometry: geometry)
                    bodyRegionButton(region: .chest, bodyX: 0.5, bodyY: 0.3, geometry: geometry)
                    bodyRegionButton(region: .shoulders, bodyX: 0.25, bodyY: 0.15, geometry: geometry, bodySide: .left)
                    bodyRegionButton(region: .shoulders, bodyX: 0.75, bodyY: 0.15, geometry: geometry, bodySide: .right)
                    bodyRegionButton(region: .arms, bodyX: 0.1, bodyY: 0.35, geometry: geometry, bodySide: .left)
                    bodyRegionButton(region: .arms, bodyX: 0.9, bodyY: 0.35, geometry: geometry, bodySide: .right)
                    bodyRegionButton(region: .hips, bodyX: 0.5, bodyY: 0.55, geometry: geometry)
                    bodyRegionButton(region: .legs, bodyX: 0.35, bodyY: 0.8, geometry: geometry, bodySide: .left)
                    bodyRegionButton(region: .legs, bodyX: 0.65, bodyY: 0.8, geometry: geometry, bodySide: .right)
                } else {
                    // Back view regions
                    bodyRegionButton(region: .neck, bodyX: 0.5, bodyY: 0.12, geometry: geometry)
                    bodyRegionButton(region: .upperBack, bodyX: 0.5, bodyY: 0.3, geometry: geometry)
                    bodyRegionButton(region: .lowerBack, bodyX: 0.5, bodyY: 0.5, geometry: geometry)
                    bodyRegionButton(region: .shoulders, bodyX: 0.25, bodyY: 0.15, geometry: geometry, bodySide: .left)
                    bodyRegionButton(region: .shoulders, bodyX: 0.75, bodyY: 0.15, geometry: geometry, bodySide: .right)
                    bodyRegionButton(region: .hips, bodyX: 0.5, bodyY: 0.55, geometry: geometry)
                    bodyRegionButton(region: .legs, bodyX: 0.35, bodyY: 0.8, geometry: geometry, bodySide: .left)
                    bodyRegionButton(region: .legs, bodyX: 0.65, bodyY: 0.8, geometry: geometry, bodySide: .right)
                }
            }
        }
    }

    private func bodyRegionButton(region: BodyLocation.BodyRegion, bodyX: CGFloat, bodyY: CGFloat, geometry: GeometryProxy, bodySide: BodyLocation.BodySide = .central) -> some View {
        let location = BodyLocation(region: region, side: bodySide)
        let isSelected = selectedAreas.contains { $0.region == region && $0.side == bodySide }

        return Button(action: {
            if isSelected {
                selectedAreas.removeAll { $0.region == region && $0.side == bodySide }
            } else {
                selectedAreas.append(location)
            }
        }) {
            Circle()
                .fill(isSelected ? Color.tranquilTeal : Color.clear)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.tranquilTeal, lineWidth: 2)
                )
        }
        .position(x: bodyX * geometry.size.width, y: bodyY * geometry.size.height)
    }
}

// MARK: - Session Timer View
struct SessionTimerView: View {
    @Binding var duration: TimeInterval
    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var timer: Timer?

    var body: some View {
        SectionCard(title: "Session Timer", icon: "timer") {
            VStack(spacing: 16) {
                Text(timeString(from: duration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.tranquilTeal)

                HStack(spacing: 12) {
                    Button(action: toggleTimer) {
                        HStack {
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            Text(isRunning ? "Pause" : "Start")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.tranquilTeal)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: resetTimer) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("Reset")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                duration += 1
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        duration = 0
    }

    private func timeString(from seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Technique Checklist View
struct TechniqueChecklistView: View {
    @Binding var selectedTechniques: [MassageTechnique]

    var body: some View {
        SectionCard(title: "Techniques Used", icon: "hand.raised.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MassageTechnique.allCases, id: \.self) { technique in
                    TechniqueButton(
                        technique: technique,
                        isSelected: selectedTechniques.contains(technique)
                    ) {
                        if selectedTechniques.contains(technique) {
                            selectedTechniques.removeAll { $0 == technique }
                        } else {
                            selectedTechniques.append(technique)
                        }
                    }
                }
            }
        }
    }
}

struct TechniqueButton: View {
    let technique: MassageTechnique
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: technique.icon)
                    .foregroundColor(isSelected ? .white : .tranquilTeal)

                Text(technique.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.tranquilTeal : Color.tranquilTeal.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contraindication Alert View
struct ContraindicationAlertView: View {
    let contraindications: [String]
    @State private var showingAlert = false

    var body: some View {
        if !contraindications.isEmpty {
            Button(action: { showingAlert = true }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)

                    Text("\(contraindications.count) Contraindication\(contraindications.count > 1 ? "s" : "") Detected")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .alert("⚠️ Contraindications", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(contraindications.joined(separator: "\n"))
            }
        }
    }
}

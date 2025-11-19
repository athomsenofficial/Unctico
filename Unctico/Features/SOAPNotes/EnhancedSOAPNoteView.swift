// EnhancedSOAPNoteView.swift
// Full-featured SOAP note creation with voice transcription

import SwiftUI
import Speech

/// Enhanced SOAP note creation view with voice-to-text
struct EnhancedSOAPNoteView: View {
    @Environment(\.dismiss) var dismiss

    // MARK: - State

    @State private var selectedClient: Client?
    @State private var sessionDate = Date()
    @State private var sessionDuration: Int = 60

    // SOAP components
    @State private var subjective = ""
    @State private var objective = ""
    @State private var assessment = ""
    @State private var plan = ""

    // Additional details
    @State private var selectedTechniques: Set<MassageTechnique> = []
    @State private var selectedAreas: Set<BodyArea> = []
    @State private var pressureLevel: PressureLevel = .medium
    @State private var selectedModalities: Set<Modality> = []
    @State private var clientResponse = ""
    @State private var adverseReactions = ""

    // Voice transcription
    @StateObject private var voiceManager = VoiceTranscriptionManager()
    @State private var currentSOAPSection: SOAPSection = .subjective
    @State private var showingVoicePermission = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                sessionInfoSection
                soapNotesSection
                techniquesSection
                areasSection
                additionalDetailsSection
            }
            .navigationTitle("SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSoapNote()
                    }
                    .disabled(selectedClient == nil || !isMinimallyComplete)
                }
            }
            .onAppear {
                voiceManager.requestAuthorization()
            }
            .alert("Speech Recognition", isPresented: $showingVoicePermission) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enable Speech Recognition in Settings to use voice dictation.")
            }
        }
    }

    // MARK: - Sections

    private var sessionInfoSection: some View {
        Section("Session Information") {
            Button {
                // TODO: Show client picker
            } label: {
                HStack {
                    Text("Client")
                    Spacer()
                    if let client = selectedClient {
                        Text(client.fullName)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select Client")
                            .foregroundStyle(.blue)
                    }
                }
            }

            DatePicker("Date", selection: $sessionDate, displayedComponents: [.date])

            Picker("Duration", selection: $sessionDuration) {
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
                Text("90 minutes").tag(90)
                Text("120 minutes").tag(120)
            }
        }
    }

    private var soapNotesSection: some View {
        Group {
            // Subjective
            Section {
                soapSectionHeader(
                    title: "Subjective",
                    subtitle: "Client's reported symptoms, pain, concerns",
                    section: .subjective
                )

                TextEditor(text: $subjective)
                    .frame(minHeight: 100)
            }

            // Objective
            Section {
                soapSectionHeader(
                    title: "Objective",
                    subtitle: "Observed findings, palpation, ROM",
                    section: .objective
                )

                TextEditor(text: $objective)
                    .frame(minHeight: 100)
            }

            // Assessment
            Section {
                soapSectionHeader(
                    title: "Assessment",
                    subtitle: "Analysis and professional opinion",
                    section: .assessment
                )

                TextEditor(text: $assessment)
                    .frame(minHeight: 100)
            }

            // Plan
            Section {
                soapSectionHeader(
                    title: "Plan",
                    subtitle: "Treatment plan and recommendations",
                    section: .plan
                )

                TextEditor(text: $plan)
                    .frame(minHeight: 100)
            }
        }
    }

    private var techniquesSection: some View {
        Section("Techniques Used") {
            ForEach(MassageTechnique.allCases, id: \.self) { technique in
                Toggle(technique.rawValue, isOn: Binding(
                    get: { selectedTechniques.contains(technique) },
                    set: { isSelected in
                        if isSelected {
                            selectedTechniques.insert(technique)
                        } else {
                            selectedTechniques.remove(technique)
                        }
                    }
                ))
            }
        }
    }

    private var areasSection: some View {
        Section("Areas Worked") {
            ForEach(BodyArea.allCases, id: \.self) { area in
                Toggle(area.rawValue, isOn: Binding(
                    get: { selectedAreas.contains(area) },
                    set: { isSelected in
                        if isSelected {
                            selectedAreas.insert(area)
                        } else {
                            selectedAreas.remove(area)
                        }
                    }
                ))
            }
        }
    }

    private var additionalDetailsSection: some View {
        Group {
            Section("Pressure Level") {
                Picker("Pressure", selection: $pressureLevel) {
                    ForEach(PressureLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Modalities") {
                ForEach(Modality.allCases, id: \.self) { modality in
                    Toggle(modality.rawValue, isOn: Binding(
                        get: { selectedModalities.contains(modality) },
                        set: { isSelected in
                            if isSelected {
                                selectedModalities.insert(modality)
                            } else {
                                selectedModalities.remove(modality)
                            }
                        }
                    ))
                }
            }

            Section("Client Response") {
                TextEditor(text: $clientResponse)
                    .frame(minHeight: 60)
            }

            Section("Adverse Reactions (if any)") {
                TextEditor(text: $adverseReactions)
                    .frame(minHeight: 60)
            }
        }
    }

    // MARK: - Helper Views

    private func soapSectionHeader(title: String, subtitle: String, section: SOAPSection) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                startVoiceTranscription(for: section)
            } label: {
                Image(systemName: voiceManager.isRecording && currentSOAPSection == section ? "mic.fill" : "mic")
                    .foregroundStyle(voiceManager.isRecording && currentSOAPSection == section ? .red : .blue)
                    .font(.title3)
            }
            .disabled(!voiceManager.isAvailable)
        }
    }

    // MARK: - Computed Properties

    private var isMinimallyComplete: Bool {
        !subjective.isEmpty || !objective.isEmpty || !assessment.isEmpty || !plan.isEmpty
    }

    // MARK: - Actions

    private func startVoiceTranscription(for section: SOAPSection) {
        if voiceManager.isRecording {
            // Stop recording and append text
            voiceManager.stopRecording()

            let transcribed = voiceManager.transcribedText

            switch currentSOAPSection {
            case .subjective:
                subjective += (subjective.isEmpty ? "" : "\n") + transcribed
            case .objective:
                objective += (objective.isEmpty ? "" : "\n") + transcribed
            case .assessment:
                assessment += (assessment.isEmpty ? "" : "\n") + transcribed
            case .plan:
                plan += (plan.isEmpty ? "" : "\n") + transcribed
            }

            voiceManager.clearTranscription()
        } else {
            // Start recording for this section
            currentSOAPSection = section
            voiceManager.startRecording()
        }
    }

    private func saveSoapNote() {
        // TODO: Save to database with encryption
        // For now, just dismiss
        dismiss()
    }
}

// MARK: - SOAP Section Enum

enum SOAPSection {
    case subjective
    case objective
    case assessment
    case plan
}

// MARK: - Preview

#Preview {
    EnhancedSOAPNoteView()
}

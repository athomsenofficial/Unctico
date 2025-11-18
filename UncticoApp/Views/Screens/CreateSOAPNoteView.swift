// CreateSOAPNoteView.swift
// Create a new SOAP note with voice input
// QA Note: This is where clinical documentation is created

import SwiftUI

struct CreateSOAPNoteView: View {

    // MARK: - Properties

    var preSelectedClient: Client? = nil

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager

    // MARK: - State

    @State private var selectedClient: Client?
    @State private var showingClientPicker = false

    // SOAP components
    @State private var chiefComplaint = ""
    @State private var painLevel = 0
    @State private var stressLevel = 0
    @State private var objectives = ""
    @State private var assessment = ""
    @State private var plan = ""

    // Voice input
    @StateObject private var voiceService = VoiceInputService()
    @State private var activeField: SOAPField?
    @State private var showingVoicePermission = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Client Selection
                Section("Client") {
                    if let client = selectedClient {
                        HStack {
                            Text(client.fullName)
                                .fontWeight(.medium)
                            Spacer()
                            Button("Change") {
                                showingClientPicker = true
                            }
                            .font(.caption)
                        }
                    } else {
                        Button(action: { showingClientPicker = true }) {
                            Text("Select Client")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Subjective Section
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Chief Complaint")
                                .font(.headline)
                            Spacer()
                            voiceButton(for: .chiefComplaint)
                        }

                        TextEditor(text: $chiefComplaint)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pain Level: \(painLevel)/10")
                            .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(painLevel) },
                            set: { painLevel = Int($0) }
                        ), in: 0...10, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stress Level: \(stressLevel)/10")
                            .font(.subheadline)
                        Slider(value: Binding(
                            get: { Double(stressLevel) },
                            set: { stressLevel = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                } header: {
                    Text("Subjective (What client tells you)")
                }

                // Objective Section
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Observations")
                                .font(.headline)
                            Spacer()
                            voiceButton(for: .objective)
                        }

                        TextEditor(text: $objectives)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                    }
                } header: {
                    Text("Objective (What you observe)")
                }

                // Assessment Section
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Clinical Assessment")
                                .font(.headline)
                            Spacer()
                            voiceButton(for: .assessment)
                        }

                        TextEditor(text: $assessment)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                    }
                } header: {
                    Text("Assessment (Your professional judgment)")
                }

                // Plan Section
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Treatment Plan")
                                .font(.headline)
                            Spacer()
                            voiceButton(for: .plan)
                        }

                        TextEditor(text: $plan)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                    }
                } header: {
                    Text("Plan (Treatment plan and recommendations)")
                }

                // Save Button
                Section {
                    Button(action: saveSOAPNote) {
                        HStack {
                            Spacer()
                            Text("Save SOAP Note")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedClient == nil || chiefComplaint.isEmpty)
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
            }
            .sheet(isPresented: $showingClientPicker) {
                ClientPickerView(selectedClient: $selectedClient)
            }
            .alert("Microphone Permission", isPresented: $showingVoicePermission) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to use voice input.")
            }
            .onChange(of: voiceService.transcribedText) { newText in
                // Update the active field with transcribed text
                if let field = activeField {
                    updateField(field, with: newText)
                }
            }
            .onAppear {
                if let client = preSelectedClient {
                    selectedClient = client
                }
            }
        }
    }

    // MARK: - Voice Button

    /// Voice input button for a specific field
    @ViewBuilder
    private func voiceButton(for field: SOAPField) -> some View {
        Button(action: {
            toggleVoiceInput(for: field)
        }) {
            Image(systemName: activeField == field && voiceService.isRecording ? "mic.fill" : "mic")
                .foregroundColor(activeField == field && voiceService.isRecording ? .red : .blue)
                .font(.title3)
        }
    }

    // MARK: - Methods

    /// Toggle voice input for a field
    private func toggleVoiceInput(for field: SOAPField) {
        // Check authorization
        if !voiceService.isAuthorized && voiceService.authorizationStatus == .notDetermined {
            voiceService.requestAuthorization { authorized in
                if authorized {
                    startVoiceInput(for: field)
                } else {
                    showingVoicePermission = true
                }
            }
        } else if voiceService.isAuthorized {
            if activeField == field && voiceService.isRecording {
                // Stop recording
                voiceService.stopRecording()
                activeField = nil
            } else {
                // Start recording
                startVoiceInput(for: field)
            }
        } else {
            showingVoicePermission = true
        }
    }

    /// Start voice input for a field
    private func startVoiceInput(for field: SOAPField) {
        activeField = field
        voiceService.clearText()
        voiceService.startRecording()
    }

    /// Update field with transcribed text
    private func updateField(_ field: SOAPField, with text: String) {
        switch field {
        case .chiefComplaint:
            chiefComplaint = text
        case .objective:
            objectives = text
        case .assessment:
            assessment = text
        case .plan:
            plan = text
        }
    }

    /// Save SOAP note
    private func saveSOAPNote() {
        guard let client = selectedClient else { return }
        guard let userId = authManager.currentUser?.id else { return }

        // Create new appointment for this session (simplified)
        let appointment = Appointment(
            clientId: client.id,
            therapistId: userId,
            startTime: Date(),
            serviceType: .custom,
            price: 0
        )
        dataManager.addAppointment(appointment)

        // Create SOAP note
        var note = SOAPNote(
            clientId: client.id,
            sessionId: appointment.id,
            therapistId: userId
        )

        // Fill in subjective
        note.subjective.chiefComplaint = chiefComplaint
        note.subjective.painLevel = painLevel
        note.subjective.stressLevel = stressLevel
        note.subjective.voiceNotes = voiceService.transcribedText

        // Fill in objective
        note.objective.observations = objectives

        // Fill in assessment
        note.assessment.clinicalReasoning = assessment

        // Fill in plan
        note.plan.treatmentPlan = plan

        // Save note
        dataManager.addSOAPNote(note)

        // Dismiss view
        dismiss()
    }
}

// MARK: - SOAP Field Enum

enum SOAPField {
    case chiefComplaint
    case objective
    case assessment
    case plan
}

// MARK: - Client Picker View

struct ClientPickerView: View {
    @Binding var selectedClient: Client?
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(dataManager.clients) { client in
                Button(action: {
                    selectedClient = client
                    dismiss()
                }) {
                    HStack {
                        Text(client.fullName)
                        Spacer()
                        if selectedClient?.id == client.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Client")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct CreateSOAPNoteView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSOAPNoteView()
            .environmentObject(DataManager())
            .environmentObject(AuthManager())
    }
}

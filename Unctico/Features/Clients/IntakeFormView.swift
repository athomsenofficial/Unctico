// IntakeFormView.swift
// Comprehensive client intake form

import SwiftUI

/// Client intake form for initial assessment
struct IntakeFormView: View {
    @Environment(\.dismiss) var dismiss

    let client: Client
    @State private var intakeForm: IntakeForm

    // Form sections expanded state
    @State private var expandedSections: Set<IntakeSection> = [.personalInfo]

    init(client: Client) {
        self.client = client
        self._intakeForm = State(initialValue: IntakeForm(clientId: client.id))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Personal Information
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.personalInfo) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.personalInfo)
                            } else {
                                expandedSections.remove(.personalInfo)
                            }
                        }
                    )
                ) {
                    personalInfoSection
                } label: {
                    sectionLabel("Personal Information", icon: "person.fill")
                }

                // Chief Complaint
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.chiefComplaint) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.chiefComplaint)
                            } else {
                                expandedSections.remove(.chiefComplaint)
                            }
                        }
                    )
                ) {
                    chiefComplaintSection
                } label: {
                    sectionLabel("Chief Complaint", icon: "cross.case.fill")
                }

                // Medical History
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.medicalHistory) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.medicalHistory)
                            } else {
                                expandedSections.remove(.medicalHistory)
                            }
                        }
                    )
                ) {
                    medicalHistorySection
                } label: {
                    sectionLabel("Medical History", icon: "heart.text.square.fill")
                }

                // Lifestyle Factors
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.lifestyle) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.lifestyle)
                            } else {
                                expandedSections.remove(.lifestyle)
                            }
                        }
                    )
                ) {
                    lifestyleSection
                } label: {
                    sectionLabel("Lifestyle Factors", icon: "figure.walk")
                }

                // Massage Preferences
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.preferences) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.preferences)
                            } else {
                                expandedSections.remove(.preferences)
                            }
                        }
                    )
                ) {
                    massagePreferencesSection
                } label: {
                    sectionLabel("Massage Preferences", icon: "hand.raised.fill")
                }

                // Consents
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(.consents) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(.consents)
                            } else {
                                expandedSections.remove(.consents)
                            }
                        }
                    )
                ) {
                    consentsSection
                } label: {
                    sectionLabel("Consents & Agreements", icon: "signature")
                }
            }
            .navigationTitle("Intake Form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIntakeForm()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var personalInfoSection: some View {
        Group {
            TextField("Occupation", text: Binding(
                get: { intakeForm.occupation ?? "" },
                set: { intakeForm.occupation = $0.isEmpty ? nil : $0 }
            ))

            Picker("Marital Status", selection: Binding(
                get: { intakeForm.maritalStatus ?? .single },
                set: { intakeForm.maritalStatus = $0 }
            )) {
                ForEach(MaritalStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status as MaritalStatus?)
                }
            }

            TextField("How did you hear about us?", text: Binding(
                get: { intakeForm.referralSource ?? "" },
                set: { intakeForm.referralSource = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var chiefComplaintSection: some View {
        Group {
            TextEditor(text: $intakeForm.chiefComplaint)
                .frame(minHeight: 80)

            VStack(alignment: .leading) {
                Text("Pain Level: \(intakeForm.painLevel)")
                    .font(.subheadline)
                Slider(value: Binding(
                    get: { Double(intakeForm.painLevel) },
                    set: { intakeForm.painLevel = Int($0) }
                ), in: 0...10, step: 1)
            }

            TextField("How long have you had this issue?", text: Binding(
                get: { intakeForm.symptomDuration ?? "" },
                set: { intakeForm.symptomDuration = $0.isEmpty ? nil : $0 }
            ))

            TextField("What makes it better?", text: Binding(
                get: { intakeForm.relievingFactors ?? "" },
                set: { intakeForm.relievingFactors = $0.isEmpty ? nil : $0 }
            ))

            TextField("What makes it worse?", text: Binding(
                get: { intakeForm.aggravatingFactors ?? "" },
                set: { intakeForm.aggravatingFactors = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var medicalHistorySection: some View {
        Group {
            Toggle("Currently Pregnant", isOn: $intakeForm.isPregnant)

            if intakeForm.isPregnant {
                Stepper("Weeks: \(intakeForm.pregnancyWeeks ?? 0)", value: Binding(
                    get: { intakeForm.pregnancyWeeks ?? 0 },
                    set: { intakeForm.pregnancyWeeks = $0 }
                ), in: 0...42)
            }

            Toggle("Uses Tobacco", isOn: $intakeForm.usesTobacco)

            Picker("Alcohol Consumption", selection: Binding(
                get: { intakeForm.alcoholConsumption ?? .never },
                set: { intakeForm.alcoholConsumption = $0 }
            )) {
                ForEach(AlcoholFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq as AlcoholFrequency?)
                }
            }

            NavigationLink("Health Conditions") {
                // TODO: Health conditions list
                Text("Health Conditions List")
            }

            NavigationLink("Medications") {
                // TODO: Medications list
                Text("Medications List")
            }

            NavigationLink("Allergies") {
                // TODO: Allergies list
                Text("Allergies List")
            }
        }
    }

    private var lifestyleSection: some View {
        Group {
            if let sleepQuality = intakeForm.sleepQuality {
                VStack(alignment: .leading) {
                    Text("Sleep Quality: \(sleepQuality)/5")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(sleepQuality) },
                        set: { intakeForm.sleepQuality = Int($0) }
                    ), in: 1...5, step: 1)
                }
            } else {
                Button("Add Sleep Quality Rating") {
                    intakeForm.sleepQuality = 3
                }
            }

            if let stressLevel = intakeForm.stressLevel {
                VStack(alignment: .leading) {
                    Text("Stress Level: \(stressLevel)/5")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(stressLevel) },
                        set: { intakeForm.stressLevel = Int($0) }
                    ), in: 1...5, step: 1)
                }
            } else {
                Button("Add Stress Level Rating") {
                    intakeForm.stressLevel = 3
                }
            }

            Picker("Exercise Frequency", selection: Binding(
                get: { intakeForm.exerciseFrequency ?? .none },
                set: { intakeForm.exerciseFrequency = $0 }
            )) {
                ForEach(ExerciseFrequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq as ExerciseFrequency?)
                }
            }

            if let waterIntake = intakeForm.waterIntake {
                Stepper("Water Intake: \(waterIntake) glasses/day", value: Binding(
                    get: { waterIntake },
                    set: { intakeForm.waterIntake = $0 }
                ), in: 0...20)
            } else {
                Button("Add Water Intake Tracking") {
                    intakeForm.waterIntake = 8
                }
            }
        }
    }

    private var massagePreferencesSection: some View {
        Group {
            Toggle("Previous Massage Experience", isOn: $intakeForm.hasPreviousMassageExperience)

            if intakeForm.hasPreviousMassageExperience {
                Picker("Preferred Pressure", selection: Binding(
                    get: { intakeForm.preferredPressure ?? .medium },
                    set: { intakeForm.preferredPressure = $0 }
                )) {
                    ForEach(PressureLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level as PressureLevel?)
                    }
                }
            }

            NavigationLink("Areas to Focus On") {
                BodyAreaSelector(
                    selectedAreas: $intakeForm.areasToFocus,
                    title: "Focus Areas"
                )
            }

            NavigationLink("Areas to Avoid") {
                BodyAreaSelector(
                    selectedAreas: $intakeForm.areasToAvoid,
                    title: "Avoid Areas"
                )
            }

            TextField("Any concerns about massage?", text: Binding(
                get: { intakeForm.massageConcerns ?? "" },
                set: { intakeForm.massageConcerns = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var consentsSection: some View {
        Group {
            Toggle("SMS Reminders", isOn: $intakeForm.smsConsentGiven)

            Toggle("Photo/Video Consent", isOn: $intakeForm.photoConsentGiven)

            if intakeForm.informedConsentDate == nil {
                Button("Sign Informed Consent") {
                    intakeForm.informedConsentDate = Date()
                }
            } else {
                HStack {
                    Text("Informed Consent")
                    Spacer()
                    Text(intakeForm.informedConsentDate!, style: .date)
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if intakeForm.hipaaConsentDate == nil {
                Button("Sign HIPAA Notice") {
                    intakeForm.hipaaConsentDate = Date()
                }
            } else {
                HStack {
                    Text("HIPAA Notice")
                    Spacer()
                    Text(intakeForm.hipaaConsentDate!, style: .date)
                        .foregroundStyle(.secondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Actions

    private func saveIntakeForm() {
        intakeForm.updatedAt = Date()
        intakeForm.isComplete = true
        // TODO: Save to database
        dismiss()
    }
}

// MARK: - Supporting Views

struct BodyAreaSelector: View {
    @Binding var selectedAreas: [BodyArea]
    let title: String

    var body: some View {
        List {
            ForEach(BodyArea.allCases, id: \.self) { area in
                Toggle(area.rawValue, isOn: Binding(
                    get: { selectedAreas.contains(area) },
                    set: { isSelected in
                        if isSelected {
                            selectedAreas.append(area)
                        } else {
                            selectedAreas.removeAll { $0 == area }
                        }
                    }
                ))
            }
        }
        .navigationTitle(title)
    }
}

// MARK: - Intake Section Enum

enum IntakeSection: Hashable {
    case personalInfo
    case chiefComplaint
    case medicalHistory
    case lifestyle
    case preferences
    case consents
}

// MARK: - Preview

#Preview {
    IntakeFormView(client: Client(firstName: "John", lastName: "Doe"))
}

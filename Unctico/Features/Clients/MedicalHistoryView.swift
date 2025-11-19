// MedicalHistoryView.swift
// Comprehensive medical history tracking for clients

import SwiftUI

/// Medical history management view
struct MedicalHistoryView: View {
    @Environment(\.dismiss) var dismiss

    let client: Client
    @State private var medicalHistory: MedicalHistory

    @State private var showingAddCondition = false
    @State private var showingAddMedication = false
    @State private var showingAddAllergy = false
    @State private var showingAddSurgery = false
    @State private var showingAddInjury = false

    init(client: Client) {
        self.client = client
        self._medicalHistory = State(initialValue: MedicalHistory(clientId: client.id))
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                summarySection

                // Active Conditions
                activeConditionsSection

                // Medications
                medicationsSection

                // Allergies
                allergiesSection

                // Surgical History
                surgicalHistorySection

                // Injuries
                injuriesSection

                // Women's Health (if applicable)
                womensHealthSection

                // Lifestyle
                lifestyleSection

                // Physicians
                physiciansSection
            }
            .navigationTitle("Medical History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedicalHistory()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        Section {
            HStack {
                Label("Active Conditions", systemImage: "cross.case.fill")
                Spacer()
                Text("\(medicalHistory.activeConditions.count)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Medications", systemImage: "pills.fill")
                Spacer()
                Text("\(medicalHistory.medicationCount)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Allergies", systemImage: "exclamationmark.triangle.fill")
                Spacer()
                Text("\(medicalHistory.allergyCount)")
                    .foregroundStyle(.secondary)
            }

            if medicalHistory.hasAbsoluteContraindications {
                HStack {
                    Label("Contraindications", systemImage: "hand.raised.fill")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("Present")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
            }
        } header: {
            Text("Summary")
        }
    }

    private var activeConditionsSection: some View {
        Section {
            if medicalHistory.activeConditions.isEmpty {
                Button {
                    showingAddCondition = true
                } label: {
                    Label("Add Health Condition", systemImage: "plus.circle")
                }
            } else {
                ForEach(medicalHistory.activeConditions) { condition in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(condition.name)
                            .font(.body)

                        if let diagnosedDate = condition.diagnosedDate {
                            Text("Diagnosed: \(diagnosedDate, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    medicalHistory.activeConditions.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddCondition = true
                } label: {
                    Label("Add Condition", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Health Conditions")
        }
        .sheet(isPresented: $showingAddCondition) {
            AddHealthConditionView { condition in
                medicalHistory.activeConditions.append(condition)
            }
        }
    }

    private var medicationsSection: some View {
        Section {
            if medicalHistory.currentMedications.isEmpty {
                Button {
                    showingAddMedication = true
                } label: {
                    Label("Add Medication", systemImage: "plus.circle")
                }
            } else {
                ForEach(medicalHistory.currentMedications) { medication in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.body)

                        if let dosage = medication.dosage {
                            Text(dosage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let purpose = medication.purpose {
                            Text("For: \(purpose)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    medicalHistory.currentMedications.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddMedication = true
                } label: {
                    Label("Add Medication", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Current Medications")
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView { medication in
                medicalHistory.currentMedications.append(medication)
            }
        }
    }

    private var allergiesSection: some View {
        Section {
            if medicalHistory.allergies.isEmpty {
                Button {
                    showingAddAllergy = true
                } label: {
                    Label("Add Allergy", systemImage: "plus.circle")
                }
            } else {
                ForEach(medicalHistory.allergies) { allergy in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(allergy.allergen)
                                .font(.body)

                            if let reaction = allergy.reaction {
                                Text(reaction)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(allergy.severity.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor(allergy.severity))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .onDelete { indexSet in
                    medicalHistory.allergies.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddAllergy = true
                } label: {
                    Label("Add Allergy", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Allergies")
        }
        .sheet(isPresented: $showingAddAllergy) {
            AddAllergyView { allergy in
                medicalHistory.allergies.append(allergy)
            }
        }
    }

    private var surgicalHistorySection: some View {
        Section {
            if medicalHistory.surgeries.isEmpty {
                Button {
                    showingAddSurgery = true
                } label: {
                    Label("Add Surgery", systemImage: "plus.circle")
                }
            } else {
                ForEach(medicalHistory.surgeries) { surgery in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(surgery.procedureName)
                            .font(.body)

                        if let date = surgery.surgeryDate {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    medicalHistory.surgeries.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddSurgery = true
                } label: {
                    Label("Add Surgery", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Surgical History")
        }
        .sheet(isPresented: $showingAddSurgery) {
            AddSurgeryView { surgery in
                medicalHistory.surgeries.append(surgery)
            }
        }
    }

    private var injuriesSection: some View {
        Section {
            if medicalHistory.injuries.isEmpty {
                Button {
                    showingAddInjury = true
                } label: {
                    Label("Add Injury", systemImage: "plus.circle")
                }
            } else {
                ForEach(medicalHistory.injuries) { injury in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(injury.description)
                                .font(.body)

                            Spacer()

                            if injury.isResolved {
                                Text("Resolved")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }

                        if let date = injury.injuryDate {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    medicalHistory.injuries.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddInjury = true
                } label: {
                    Label("Add Injury", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Injury History")
        }
        .sheet(isPresented: $showingAddInjury) {
            AddInjuryView { injury in
                medicalHistory.injuries.append(injury)
            }
        }
    }

    private var womensHealthSection: some View {
        Section {
            Toggle("Currently Pregnant", isOn: $medicalHistory.isPregnant)

            if medicalHistory.isPregnant {
                if let trimester = medicalHistory.trimester {
                    Picker("Trimester", selection: Binding(
                        get: { trimester },
                        set: { medicalHistory.trimester = $0 }
                    )) {
                        Text("First").tag(1)
                        Text("Second").tag(2)
                        Text("Third").tag(3)
                    }
                    .pickerStyle(.segmented)
                } else {
                    Button("Set Trimester") {
                        medicalHistory.trimester = 1
                    }
                }

                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { medicalHistory.dueDate ?? Date() },
                        set: { medicalHistory.dueDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
            }

            Toggle("Currently Nursing", isOn: $medicalHistory.isNursing)
        } header: {
            Text("Women's Health")
        }
    }

    private var lifestyleSection: some View {
        Section {
            if let sleepHours = medicalHistory.averageSleepHours {
                Stepper("Sleep: \(String(format: "%.1f", sleepHours)) hours/night", value: Binding(
                    get: { sleepHours },
                    set: { medicalHistory.averageSleepHours = $0 }
                ), in: 0...12, step: 0.5)
            } else {
                Button("Add Sleep Tracking") {
                    medicalHistory.averageSleepHours = 8
                }
            }

            if let stressLevel = medicalHistory.stressLevel {
                VStack(alignment: .leading) {
                    Text("Stress Level: \(stressLevel)/10")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(stressLevel) },
                        set: { medicalHistory.stressLevel = Int($0) }
                    ), in: 1...10, step: 1)
                }
            } else {
                Button("Add Stress Level") {
                    medicalHistory.stressLevel = 5
                }
            }

            TextField("Exercise Routine", text: Binding(
                get: { medicalHistory.exerciseRoutine ?? "" },
                set: { medicalHistory.exerciseRoutine = $0.isEmpty ? nil : $0 }
            ))
        } header: {
            Text("Lifestyle Factors")
        }
    }

    private var physiciansSection: some View {
        Section {
            if let pcp = medicalHistory.primaryCarePhysician {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pcp.name)
                        .font(.body)

                    if let phone = pcp.phoneNumber {
                        Text(phone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button("Add Primary Care Physician") {
                    // TODO: Add PCP
                }
            }
        } header: {
            Text("Physicians")
        }
    }

    // MARK: - Helper Methods

    private func severityColor(_ severity: AllergySeverity) -> Color {
        switch severity {
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe, .anaphylactic:
            return .red
        }
    }

    private func saveMedicalHistory() {
        medicalHistory.updatedAt = Date()
        // TODO: Save to database with encryption
        dismiss()
    }
}

// MARK: - Add Forms

struct AddHealthConditionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var diagnosedDate: Date?
    @State private var isCurrent = true

    let onSave: (HealthCondition) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Condition Name", text: $name)

                Toggle("Currently Active", isOn: $isCurrent)

                Toggle("Known Diagnosis Date", isOn: Binding(
                    get: { diagnosedDate != nil },
                    set: { hasDate in
                        diagnosedDate = hasDate ? Date() : nil
                    }
                ))

                if diagnosedDate != nil {
                    DatePicker("Diagnosed", selection: Binding(
                        get: { diagnosedDate ?? Date() },
                        set: { diagnosedDate = $0 }
                    ), displayedComponents: [.date])
                }
            }
            .navigationTitle("Add Condition")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var condition = HealthCondition(name: name, isCurrent: isCurrent)
                        condition.diagnosedDate = diagnosedDate
                        onSave(condition)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddMedicationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var purpose = ""

    let onSave: (Medication) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Medication Name", text: $name)
                TextField("Dosage", text: $dosage)
                TextField("Frequency", text: $frequency)
                TextField("Purpose", text: $purpose)
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var medication = Medication(name: name, dosage: dosage.isEmpty ? nil : dosage)
                        medication.frequency = frequency.isEmpty ? nil : frequency
                        medication.purpose = purpose.isEmpty ? nil : purpose
                        onSave(medication)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddAllergyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var allergen = ""
    @State private var reaction = ""
    @State private var severity: AllergySeverity = .moderate

    let onSave: (Allergy) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Allergen", text: $allergen)

                TextField("Reaction", text: $reaction)

                Picker("Severity", selection: $severity) {
                    Text("Mild").tag(AllergySeverity.mild)
                    Text("Moderate").tag(AllergySeverity.moderate)
                    Text("Severe").tag(AllergySeverity.severe)
                    Text("Anaphylactic").tag(AllergySeverity.anaphylactic)
                }
            }
            .navigationTitle("Add Allergy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var allergy = Allergy(allergen: allergen, severity: severity)
                        allergy.reaction = reaction.isEmpty ? nil : reaction
                        onSave(allergy)
                        dismiss()
                    }
                    .disabled(allergen.isEmpty)
                }
            }
        }
    }
}

struct AddSurgeryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var procedureName = ""
    @State private var surgeryDate: Date?
    @State private var notes = ""

    let onSave: (Surgery) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Procedure Name", text: $procedureName)

                Toggle("Known Surgery Date", isOn: Binding(
                    get: { surgeryDate != nil },
                    set: { hasDate in
                        surgeryDate = hasDate ? Date() : nil
                    }
                ))

                if surgeryDate != nil {
                    DatePicker("Surgery Date", selection: Binding(
                        get: { surgeryDate ?? Date() },
                        set: { surgeryDate = $0 }
                    ), displayedComponents: [.date])
                }

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Add Surgery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var surgery = Surgery(procedureName: procedureName, surgeryDate: surgeryDate)
                        surgery.notes = notes.isEmpty ? nil : notes
                        onSave(surgery)
                        dismiss()
                    }
                    .disabled(procedureName.isEmpty)
                }
            }
        }
    }
}

struct AddInjuryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var description = ""
    @State private var injuryDate: Date?
    @State private var affectedAreas: [BodyArea] = []
    @State private var isResolved = false

    let onSave: (Injury) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...4)

                Toggle("Known Injury Date", isOn: Binding(
                    get: { injuryDate != nil },
                    set: { hasDate in
                        injuryDate = hasDate ? Date() : nil
                    }
                ))

                if injuryDate != nil {
                    DatePicker("Injury Date", selection: Binding(
                        get: { injuryDate ?? Date() },
                        set: { injuryDate = $0 }
                    ), displayedComponents: [.date])
                }

                Toggle("Resolved", isOn: $isResolved)

                NavigationLink("Affected Areas") {
                    BodyAreaSelector(selectedAreas: $affectedAreas, title: "Affected Areas")
                }
            }
            .navigationTitle("Add Injury")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var injury = Injury(description: description, affectedAreas: affectedAreas)
                        injury.injuryDate = injuryDate
                        injury.isResolved = isResolved
                        onSave(injury)
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MedicalHistoryView(client: Client(firstName: "John", lastName: "Doe"))
}

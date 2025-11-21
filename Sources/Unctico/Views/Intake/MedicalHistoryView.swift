import SwiftUI

/// Medical history tracker with critical safety alerts
struct MedicalHistoryView: View {
    @State private var medicalHistory: MedicalHistory
    @State private var showingAddAllergy = false
    @State private var showingAddMedication = false
    @State private var showingAddCondition = false

    init(medicalHistory: MedicalHistory) {
        _medicalHistory = State(initialValue: medicalHistory)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // CRITICAL ALERTS (TOP OF PAGE - ALWAYS VISIBLE)
                if medicalHistory.hasActiveContraindications || !medicalHistory.criticalAlerts.isEmpty {
                    CriticalAlertsSection(alerts: medicalHistory.criticalAlerts)
                }

                // Allergy Alerts (PATIENT SAFETY)
                AllergiesSection(
                    allergies: $medicalHistory.allergies,
                    showingAdd: $showingAddAllergy
                )

                // Current Medications
                MedicationsSection(
                    medications: $medicalHistory.medications,
                    showingAdd: $showingAddMedication
                )

                // Health Conditions
                HealthConditionsSection(
                    conditions: $medicalHistory.healthConditions,
                    showingAdd: $showingAddCondition
                )

                // Surgeries & Procedures
                SurgeriesSection(surgeries: $medicalHistory.surgeries)

                // Lifestyle Factors
                LifestyleSection(lifestyle: $medicalHistory.lifestyle)

                // Emergency Contacts
                EmergencyContactSection(
                    emergencyContact: $medicalHistory.emergencyContact,
                    physicianInfo: $medicalHistory.physicianInfo
                )
            }
            .padding()
        }
        .navigationTitle("Medical History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddAllergy = true }) {
                        Label("Add Allergy", systemImage: "allergens")
                    }
                    Button(action: { showingAddMedication = true }) {
                        Label("Add Medication", systemImage: "pills")
                    }
                    Button(action: { showingAddCondition = true }) {
                        Label("Add Health Condition", systemImage: "heart.text.square")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.tranquilTeal)
                }
            }
        }
        .sheet(isPresented: $showingAddAllergy) {
            AddAllergyView(allergies: $medicalHistory.allergies)
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(medications: $medicalHistory.medications)
        }
        .sheet(isPresented: $showingAddCondition) {
            AddConditionView(conditions: $medicalHistory.healthConditions)
        }
    }
}

// MARK: - Critical Alerts Section (TOP PRIORITY)
struct CriticalAlertsSection: View {
    let alerts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)

                Text("CRITICAL SAFETY ALERTS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            ForEach(alerts, id: \.self) { alert in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)

                    Text(alert)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .border(Color.red, width: 2)
        .cornerRadius(12)
    }
}

// MARK: - Allergies Section
struct AllergiesSection: View {
    @Binding var allergies: [Allergy]
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Allergies",
                icon: "allergens",
                color: .orange,
                action: { showingAdd = true }
            )

            if allergies.isEmpty {
                EmptyStateCard(
                    icon: "allergens",
                    message: "No allergies recorded",
                    subMessage: "Tap + to add allergies to oils, lotions, or fragrances"
                )
            } else {
                ForEach(allergies) { allergy in
                    AllergyCard(allergy: allergy) {
                        allergies.removeAll { $0.id == allergy.id }
                    }
                }
            }
        }
    }
}

struct AllergyCard: View {
    let allergy: Allergy
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(allergy.allergen)
                        .font(.headline)

                    Spacer()

                    SeverityBadge(severity: allergy.severity)
                }

                Text(allergy.reaction)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(allergy.severity == .severe ? Color.red.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(allergy.severity == .severe ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

struct SeverityBadge: View {
    let severity: AllergySeverity

    var body: some View {
        Text(severity.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .cornerRadius(6)
    }
}

// MARK: - Medications Section
struct MedicationsSection: View {
    @Binding var medications: [Medication]
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Current Medications",
                icon: "pills.fill",
                color: .blue,
                action: { showingAdd = true }
            )

            if medications.isEmpty {
                EmptyStateCard(
                    icon: "pills",
                    message: "No medications recorded",
                    subMessage: "Include all prescriptions, over-the-counter medications, and supplements"
                )
            } else {
                ForEach(medications) { medication in
                    MedicationCard(medication: medication)
                }
            }
        }
    }
}

struct MedicationCard: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.name)
                    .font(.headline)

                Spacer()

                Text(medication.dosage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !medication.purpose.isEmpty {
                Text(medication.purpose)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !medication.interactionsWithMassage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text(medication.interactionsWithMassage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Health Conditions Section
struct HealthConditionsSection: View {
    @Binding var conditions: [HealthCondition]
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Health Conditions",
                icon: "heart.text.square.fill",
                color: .red,
                action: { showingAdd = true }
            )

            if conditions.isEmpty {
                EmptyStateCard(
                    icon: "heart.text.square",
                    message: "No health conditions recorded",
                    subMessage: "Add any relevant medical conditions"
                )
            } else {
                ForEach(conditions) { condition in
                    HealthConditionCard(condition: condition)
                }
            }
        }
    }
}

struct HealthConditionCard: View {
    let condition: HealthCondition

    var body: some View {
        HStack {
            Image(systemName: condition.category.icon)
                .font(.title2)
                .foregroundColor(condition.category.color)
                .frame(width: 40, height: 40)
                .background(condition.category.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(condition.name)
                    .font(.headline)

                Text(condition.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !condition.notes.isEmpty {
                    Text(condition.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack {
                SeverityBadge(severity: condition.severity)

                if condition.isActive {
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    struct SeverityBadge: View {
        let severity: ConditionSeverity

        var body: some View {
            Text(severity.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(severity.color.opacity(0.2))
                .foregroundColor(severity.color)
                .cornerRadius(4)
        }
    }
}

// MARK: - Surgeries Section
struct SurgeriesSection: View {
    @Binding var surgeries: [Surgery]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Surgeries & Procedures",
                icon: "cross.case.fill",
                color: .purple
            )

            if surgeries.isEmpty {
                EmptyStateCard(
                    icon: "cross.case",
                    message: "No surgeries recorded",
                    subMessage: "Include all past surgeries and medical procedures"
                )
            } else {
                ForEach(surgeries) { surgery in
                    SurgeryCard(surgery: surgery)
                }
            }
        }
    }
}

struct SurgeryCard: View {
    let surgery: Surgery

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(surgery.procedure)
                    .font(.headline)

                Spacer()

                Text(surgery.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if surgery.affectsTreatmentArea {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Affects treatment area")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Lifestyle Section
struct LifestyleSection: View {
    @Binding var lifestyle: LifestyleFactors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Lifestyle Factors",
                icon: "figure.walk",
                color: .green
            )

            VStack(spacing: 12) {
                LifestyleRow(label: "Exercise Frequency", value: lifestyle.exerciseFrequency.rawValue)
                LifestyleRow(label: "Sleep Quality", value: lifestyle.sleepQuality.rawValue)
                LifestyleRow(label: "Stress Level", value: "\(lifestyle.stressLevel)/10")
                LifestyleRow(label: "Alcohol Consumption", value: lifestyle.alcoholConsumption.rawValue)
                LifestyleRow(label: "Tobacco Use", value: lifestyle.tobaccoUse.rawValue)

                if !lifestyle.occupation.isEmpty {
                    LifestyleRow(label: "Occupation", value: lifestyle.occupation)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct LifestyleRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Emergency Contact Section
struct EmergencyContactSection: View {
    @Binding var emergencyContact: EmergencyContact?
    @Binding var physicianInfo: PhysicianInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Emergency Contact",
                icon: "phone.fill",
                color: .red
            )

            if let contact = emergencyContact {
                VStack(alignment: .leading, spacing: 8) {
                    ContactRow(label: "Name", value: contact.name)
                    ContactRow(label: "Relationship", value: contact.relationship)
                    ContactRow(label: "Phone", value: contact.phone)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            } else {
                EmptyStateCard(
                    icon: "phone",
                    message: "No emergency contact",
                    subMessage: "Add emergency contact information"
                )
            }

            if let physician = physicianInfo {
                SectionHeader(
                    title: "Primary Physician",
                    icon: "stethoscope",
                    color: .blue
                )

                VStack(alignment: .leading, spacing: 8) {
                    ContactRow(label: "Name", value: physician.name)
                    if !physician.specialty.isEmpty {
                        ContactRow(label: "Specialty", value: physician.specialty)
                    }
                    ContactRow(label: "Phone", value: physician.phone)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}

struct ContactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.tranquilTeal)
                }
            }
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let message: String
    let subMessage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.gray)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(subMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Add Forms (Simplified - Full implementation would be more detailed)
struct AddAllergyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var allergies: [Allergy]

    @State private var allergen = ""
    @State private var reaction = ""
    @State private var severity: AllergySeverity = .moderate

    var body: some View {
        NavigationView {
            Form {
                Section("Allergen Details") {
                    TextField("Allergen (e.g., Lavender oil)", text: $allergen)
                    TextField("Reaction", text: $reaction)
                    Picker("Severity", selection: $severity) {
                        ForEach([AllergySeverity.mild, .moderate, .severe], id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Add Allergy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newAllergy = Allergy(
                            allergen: allergen,
                            reaction: reaction,
                            severity: severity,
                            diagnosedDate: Date()
                        )
                        allergies.append(newAllergy)
                        dismiss()
                    }
                    .disabled(allergen.isEmpty)
                }
            }
        }
    }
}

struct AddMedicationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var medications: [Medication]

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var purpose = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage (e.g., 50mg)", text: $dosage)
                    TextField("Frequency (e.g., Daily)", text: $frequency)
                    TextField("Purpose", text: $purpose)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newMed = Medication(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            purpose: purpose
                        )
                        medications.append(newMed)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddConditionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var conditions: [HealthCondition]

    @State private var name = ""
    @State private var category: ConditionCategory = .other
    @State private var severity: ConditionSeverity = .moderate

    var body: some View {
        NavigationView {
            Form {
                Section("Condition Details") {
                    TextField("Condition Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(ConditionCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Severity", selection: $severity) {
                        ForEach([ConditionSeverity.mild, .moderate, .severe], id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Add Health Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newCondition = HealthCondition(
                            name: name,
                            category: category,
                            severity: severity
                        )
                        conditions.append(newCondition)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

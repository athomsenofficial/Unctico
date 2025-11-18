// ClientDetailView.swift
// Detailed view of a single client
// QA Note: Shows all client information and history

import SwiftUI

struct ClientDetailView: View {

    // MARK: - Properties

    let client: Client

    // MARK: - Environment

    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var showingEditClient = false
    @State private var showingAddAppointment = false

    // MARK: - Body

    var body: some View {
        List {
            // Basic Info Section
            Section("Basic Information") {
                InfoRow(label: "Name", value: client.fullName)
                InfoRow(label: "Email", value: client.email)
                InfoRow(label: "Phone", value: client.phone)
                InfoRow(label: "Age", value: "\(client.age) years")
                InfoRow(label: "Status", value: client.isActive ? "Active" : "Inactive")
            }

            // Medical History Section
            Section("Medical History") {
                if client.medicalHistory.hasHeartCondition {
                    Label("Heart Condition", systemImage: "heart.fill")
                        .foregroundColor(.red)
                }
                if client.medicalHistory.hasHighBloodPressure {
                    Label("High Blood Pressure", systemImage: "waveform.path.ecg")
                        .foregroundColor(.orange)
                }
                if client.medicalHistory.hasDiabetes {
                    Label("Diabetes", systemImage: "drop.fill")
                        .foregroundColor(.blue)
                }
                if client.medicalHistory.isPregnant {
                    Label("Pregnant", systemImage: "figure.walk")
                        .foregroundColor(.purple)
                }

                if !client.allergies.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allergies:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(client.allergies, id: \.self) { allergy in
                            Text("• \(allergy)")
                                .foregroundColor(.red)
                        }
                    }
                }

                if client.medicalHistory.hasHeartCondition == false &&
                   client.medicalHistory.hasHighBloodPressure == false &&
                   client.medicalHistory.hasDiabetes == false &&
                   client.allergies.isEmpty {
                    Text("No known medical conditions")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }

            // Preferences Section
            Section("Preferences") {
                InfoRow(label: "Pressure", value: client.preferences.pressureLevel.rawValue)
                InfoRow(label: "Temperature", value: client.preferences.temperaturePreference.rawValue)
                InfoRow(label: "Music", value: client.preferences.musicType.rawValue)
            }

            // Appointment History
            Section("Appointment History") {
                let appointments = dataManager.getAppointments(forClient: client.id)

                if appointments.isEmpty {
                    Text("No appointments yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appointments.prefix(5)) { appointment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appointment.startTime, formatter: DateFormatter.mediumDate)
                                .font(.subheadline)
                            Text(appointment.serviceType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if appointments.count > 5 {
                        Text("+ \(appointments.count - 5) more appointments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // SOAP Notes
            Section("Recent SOAP Notes") {
                let notes = dataManager.getSOAPNotes(forClient: client.id)

                if notes.isEmpty {
                    Text("No clinical notes yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notes.prefix(3)) { note in
                        NavigationLink(destination: SOAPNoteDetailView(note: note)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.createdDate, formatter: DateFormatter.mediumDate)
                                    .font(.subheadline)
                                if !note.subjective.chiefComplaint.isEmpty {
                                    Text(note.subjective.chiefComplaint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }

                    if notes.count > 3 {
                        Text("+ \(notes.count - 3) more notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Quick Actions
            Section("Quick Actions") {
                Button(action: { showingAddAppointment = true }) {
                    Label("Schedule Appointment", systemImage: "calendar.badge.plus")
                }

                NavigationLink(destination: CreateSOAPNoteView(preSelectedClient: client)) {
                    Label("Create SOAP Note", systemImage: "doc.text.fill")
                }
            }
        }
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditClient = true
                }
            }
        }
        .sheet(isPresented: $showingEditClient) {
            EditClientView(client: client)
        }
        .sheet(isPresented: $showingAddAppointment) {
            AddAppointmentView(preSelectedClient: client)
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Placeholder Views

struct EditClientView: View {
    let client: Client

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Text("Edit Client: \(client.fullName)")
                .navigationTitle("Edit Client")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct AddAppointmentView: View {
    var selectedDate: Date = Date()
    var preSelectedClient: Client? = nil

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Text("Add Appointment")
                .navigationTitle("New Appointment")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

struct ClientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClientDetailView(
                client: Client(
                    firstName: "John",
                    lastName: "Doe",
                    email: "john@example.com",
                    phone: "(555) 123-4567",
                    dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!
                )
            )
        }
        .environmentObject(DataManager())
    }
}

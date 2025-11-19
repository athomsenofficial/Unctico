// ScheduleView.swift
// Calendar and appointment scheduling view

import SwiftUI

/// Schedule management view with calendar
struct ScheduleView: View {

    // MARK: - State

    @State private var selectedDate = Date()
    @State private var showingAddAppointment = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar picker
                calendarSection

                Divider()

                // Appointments for selected date
                appointmentsSection
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAppointment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView()
            }
        }
    }

    // MARK: - View Components

    /// Calendar date picker section
    private var calendarSection: some View {
        DatePicker(
            "Select Date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .padding()
    }

    /// Appointments list for selected date
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Appointments")
                    .font(.headline)

                Spacer()

                Text(selectedDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)

            // Empty state
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("No appointments scheduled")
                    .foregroundStyle(.secondary)

                Button {
                    showingAddAppointment = true
                } label: {
                    Text("Schedule Appointment")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)

            Spacer()
        }
    }
}

// MARK: - Add Appointment View

struct AddAppointmentView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedClient: Client?
    @State private var appointmentDate = Date()
    @State private var duration: AppointmentDuration = .sixty
    @State private var serviceType: ServiceType = .swedish
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    Button {
                        // TODO: Show client picker
                    } label: {
                        HStack {
                            Text("Select Client")
                            Spacer()
                            if let client = selectedClient {
                                Text(client.fullName)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Date & Time") {
                    DatePicker("Date & Time", selection: $appointmentDate)

                    Picker("Duration", selection: $duration) {
                        ForEach(AppointmentDuration.allCases) { duration in
                            Text(duration.label).tag(duration)
                        }
                    }
                }

                Section("Service") {
                    Picker("Type", selection: $serviceType) {
                        ForEach(ServiceType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Save appointment
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum AppointmentDuration: Int, CaseIterable, Identifiable {
    case thirty = 30
    case sixty = 60
    case ninety = 90
    case oneTwenty = 120

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) minutes"
    }
}

enum ServiceType: String, CaseIterable, Identifiable {
    case swedish = "Swedish Massage"
    case deepTissue = "Deep Tissue"
    case sports = "Sports Massage"
    case prenatal = "Prenatal Massage"
    case hotStone = "Hot Stone"
    case aromatherapy = "Aromatherapy"

    var id: String { rawValue }
}

// MARK: - Preview

#Preview {
    ScheduleView()
}

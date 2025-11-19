// BookAppointmentView.swift
// Comprehensive appointment booking interface with time slot selection

import SwiftUI

/// Full-featured appointment booking view
struct BookAppointmentView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var appointmentManager: AppointmentManager

    // MARK: - State

    @State private var selectedClient: Client?
    @State private var selectedDate: Date
    @State private var selectedTimeSlot: Date?
    @State private var serviceType: ServiceType = .swedish
    @State private var durationMinutes: Int = 60
    @State private var notes = ""
    @State private var price: String = ""

    // Recurrence
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .weekly
    @State private var recurrenceInterval = 1
    @State private var recurrenceEndType: RecurrenceEndType = .never
    @State private var recurrenceEndDate = Date()
    @State private var recurrenceOccurrences = 10

    @State private var showError = false
    @State private var errorMessage = ""

    init(appointmentManager: AppointmentManager, selectedDate: Date = Date()) {
        self.appointmentManager = appointmentManager
        self._selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Client selection
                clientSection

                // Date and time
                dateTimeSection

                // Service details
                serviceSection

                // Recurrence (optional)
                recurrenceSection

                // Notes and price
                additionalSection
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") {
                        bookAppointment()
                    }
                    .disabled(!canBook)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    private var clientSection: some View {
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var dateTimeSection: some View {
        Section("Date & Time") {
            DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                .onChange(of: selectedDate) { _, _ in
                    selectedTimeSlot = nil // Reset time slot when date changes
                }

            NavigationLink {
                TimeSlotPickerView(
                    date: selectedDate,
                    duration: durationMinutes,
                    appointmentManager: appointmentManager,
                    selectedSlot: $selectedTimeSlot
                )
            } label: {
                HStack {
                    Text("Time")
                    Spacer()
                    if let slot = selectedTimeSlot {
                        Text(slot, style: .time)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select")
                            .foregroundStyle(.blue)
                    }
                }
            }

            Picker("Duration", selection: $durationMinutes) {
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
                Text("90 minutes").tag(90)
                Text("120 minutes").tag(120)
            }
            .onChange(of: durationMinutes) { _, _ in
                selectedTimeSlot = nil // Reset time slot when duration changes
            }
        }
    }

    private var serviceSection: some View {
        Section("Service") {
            Picker("Type", selection: $serviceType) {
                ForEach(ServiceType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            TextField("Price (optional)", text: $price)
                .keyboardType(.decimalPad)
        }
    }

    private var recurrenceSection: some View {
        Section {
            Toggle("Recurring Appointment", isOn: $isRecurring)

            if isRecurring {
                Picker("Frequency", selection: $recurrenceFrequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }

                if recurrenceFrequency != .custom {
                    Stepper("Every \(recurrenceInterval) \(frequencyUnit)", value: $recurrenceInterval, in: 1...12)
                }

                Picker("Ends", selection: $recurrenceEndType) {
                    ForEach([RecurrenceEndType.never, .onDate, .afterOccurrences], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                if recurrenceEndType == .onDate {
                    DatePicker("End Date", selection: $recurrenceEndDate, displayedComponents: [.date])
                } else if recurrenceEndType == .afterOccurrences {
                    Stepper("\(recurrenceOccurrences) occurrences", value: $recurrenceOccurrences, in: 1...100)
                }
            }
        } header: {
            Text("Recurrence")
        }
    }

    private var additionalSection: some View {
        Section("Additional Information") {
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Computed Properties

    private var canBook: Bool {
        return selectedClient != nil && selectedTimeSlot != nil
    }

    private var frequencyUnit: String {
        switch recurrenceFrequency {
        case .daily:
            return recurrenceInterval == 1 ? "day" : "days"
        case .weekly, .biWeekly:
            return recurrenceInterval == 1 ? "week" : "weeks"
        case .monthly:
            return recurrenceInterval == 1 ? "month" : "months"
        case .custom:
            return ""
        }
    }

    // MARK: - Actions

    private func bookAppointment() {
        guard let client = selectedClient,
              let timeSlot = selectedTimeSlot else {
            return
        }

        if isRecurring {
            // Create recurring appointments
            let pattern = createRecurrencePattern()

            let firstAppointment = Appointment(
                clientId: client.id,
                startDateTime: timeSlot,
                durationMinutes: durationMinutes,
                serviceType: serviceType
            )

            let created = appointmentManager.createRecurringAppointments(
                clientId: client.id,
                firstAppointment: firstAppointment,
                pattern: pattern
            )

            if created.isEmpty {
                errorMessage = "Failed to create recurring appointments"
                showError = true
            } else {
                dismiss()
            }
        } else {
            // Create single appointment
            if let appointment = appointmentManager.bookAppointment(
                clientId: client.id,
                startDateTime: timeSlot,
                durationMinutes: durationMinutes,
                serviceType: serviceType
            ) {
                dismiss()
            } else {
                errorMessage = appointmentManager.errorMessage ?? "Failed to book appointment"
                showError = true
            }
        }
    }

    private func createRecurrencePattern() -> RecurrencePattern {
        var pattern = RecurrencePattern(frequency: recurrenceFrequency, interval: recurrenceInterval)
        pattern.endType = recurrenceEndType

        if recurrenceEndType == .onDate {
            pattern.endDate = recurrenceEndDate
        } else if recurrenceEndType == .afterOccurrences {
            pattern.occurrenceCount = recurrenceOccurrences
        }

        return pattern
    }
}

// MARK: - Time Slot Picker View

struct TimeSlotPickerView: View {
    let date: Date
    let duration: Int
    let appointmentManager: AppointmentManager

    @Binding var selectedSlot: Date?

    @Environment(\.dismiss) var dismiss

    private var availableSlots: [Date] {
        appointmentManager.availableTimeSlots(on: date, duration: duration)
    }

    var body: some View {
        List {
            if availableSlots.isEmpty {
                Text("No available time slots for this date")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(availableSlots, id: \.self) { slot in
                    Button {
                        selectedSlot = slot
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slot, style: .time)
                                    .font(.headline)

                                Text(timeRange(from: slot))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedSlot == slot {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select Time")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func timeRange(from startTime: Date) -> String {
        let calendar = Calendar.current
        guard let endTime = calendar.date(byAdding: .minute, value: duration, to: startTime) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

// MARK: - Preview

#Preview {
    BookAppointmentView(appointmentManager: AppointmentManager())
}

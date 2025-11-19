import SwiftUI

struct ScheduleView: View {
    @ObservedObject private var repository = AppointmentRepository.shared
    @State private var selectedDate = Date()
    @State private var showingAddAppointment = false
    @State private var viewMode: ViewMode = .day

    enum ViewMode {
        case day, week, month
    }

    var filteredAppointments: [Appointment] {
        repository.getAppointments(for: selectedDate)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ViewModePicker(selection: $viewMode)
                    .padding()

                DateSelector(selectedDate: $selectedDate)

                Divider()

                if filteredAppointments.isEmpty {
                    EmptyStateView(message: "No appointments scheduled")
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredAppointments.sorted(by: { $0.startTime < $1.startTime })) { appointment in
                                ScheduleAppointmentCard(appointment: appointment)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAppointment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView(selectedDate: selectedDate)
            }
        }
    }
}

struct ViewModePicker: View {
    @Binding var selection: ScheduleView.ViewMode

    var body: some View {
        HStack(spacing: 0) {
            ModeButton(title: "Day", mode: .day, currentMode: $selection)
            ModeButton(title: "Week", mode: .week, currentMode: $selection)
            ModeButton(title: "Month", mode: .month, currentMode: $selection)
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ModeButton: View {
    let title: String
    let mode: ScheduleView.ViewMode
    @Binding var currentMode: ScheduleView.ViewMode

    var body: some View {
        Button(action: { currentMode = mode }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(currentMode == mode ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(currentMode == mode ? Color.tranquilTeal : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct DateSelector: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack {
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.tranquilTeal)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(selectedDate, style: .date)
                    .font(.headline)

                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: nextDay) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.tranquilTeal)
            }
        }
        .padding()
    }

    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

struct ScheduleAppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(appointment.startTime, style: .time)
                    .font(.headline)

                Text(Int(appointment.duration / 60), format: .number)
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(" min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            Rectangle()
                .fill(serviceTypeColor(for: appointment.serviceType))
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.serviceType.rawValue)
                    .font(.headline)

                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("Client Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let notes = appointment.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            StatusBadge(status: appointment.status)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func serviceTypeColor(for serviceType: ServiceType) -> Color {
        switch serviceType {
        case .swedish: return .calmingBlue
        case .deepTissue: return .tranquilTeal
        case .sports: return .soothingGreen
        case .prenatal: return .softLavender
        case .hotStone: return .orange
        case .aromatherapy: return .purple
        case .therapeutic: return .blue
        case .medical: return .red
        }
    }
}

struct AddAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = AppointmentRepository.shared
    let selectedDate: Date

    @State private var serviceType: ServiceType = .swedish
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 3600
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Service Details") {
                    Picker("Service Type", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])

                    Picker("Duration", selection: $duration) {
                        Text("30 min").tag(TimeInterval(1800))
                        Text("60 min").tag(TimeInterval(3600))
                        Text("90 min").tag(TimeInterval(5400))
                        Text("120 min").tag(TimeInterval(7200))
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAppointment()
                    }
                }
            }
        }
    }

    private func saveAppointment() {
        let newAppointment = Appointment(
            clientId: UUID(),
            serviceType: serviceType,
            startTime: startTime,
            duration: duration,
            notes: notes.isEmpty ? nil : notes
        )
        repository.addAppointment(newAppointment)
        dismiss()
    }
}

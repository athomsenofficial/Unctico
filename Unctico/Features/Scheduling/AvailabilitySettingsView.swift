// AvailabilitySettingsView.swift
// Manage working hours, breaks, and time off

import SwiftUI

/// Settings view for therapist availability
struct AvailabilitySettingsView: View {

    @Environment(\.dismiss) var dismiss

    @State private var schedule: TherapistSchedule
    @State private var showingAddBreak = false
    @State private var showingAddTimeOff = false

    init(userId: UUID) {
        self._schedule = State(initialValue: TherapistSchedule(therapistId: userId))
    }

    var body: some View {
        NavigationStack {
            List {
                // Working hours section
                workingHoursSection

                // Buffer time section
                bufferTimeSection

                // Breaks section
                breaksSection

                // Time off section
                timeOffSection
            }
            .navigationTitle("Availability Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSchedule()
                    }
                }
            }
            .sheet(isPresented: $showingAddBreak) {
                AddBreakView { newBreak in
                    schedule.breaks.append(newBreak)
                }
            }
            .sheet(isPresented: $showingAddTimeOff) {
                AddTimeOffView { newTimeOff in
                    schedule.timeOff.append(newTimeOff)
                }
            }
        }
    }

    // MARK: - Sections

    private var workingHoursSection: some View {
        Section {
            ForEach(DayOfWeek.allCases, id: \.self) { day in
                NavigationLink {
                    DayWorkingHoursView(day: day, workingHours: binding(for: day))
                } label: {
                    HStack {
                        Text(day.name)
                            .frame(width: 100, alignment: .leading)

                        Spacer()

                        if let hours = schedule.weeklyHours[day] {
                            Text(hours.displayString)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Weekly Schedule")
        } footer: {
            Text("Set your regular working hours for each day of the week")
        }
    }

    private var bufferTimeSection: some View {
        Section {
            Stepper("Buffer time: \(schedule.bufferMinutes) minutes",
                   value: $schedule.bufferMinutes,
                   in: 0...60,
                   step: 5)
        } header: {
            Text("Buffer Time")
        } footer: {
            Text("Time between appointments for cleaning and preparation")
        }
    }

    private var breaksSection: some View {
        Section {
            if schedule.breaks.isEmpty {
                Button {
                    showingAddBreak = true
                } label: {
                    Label("Add Break", systemImage: "plus.circle")
                }
            } else {
                ForEach(schedule.breaks) { breakPeriod in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatBreakTime(breakPeriod))
                            .font(.body)

                        Text(breakPeriod.daysOfWeek.map { $0.shortName }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    schedule.breaks.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddBreak = true
                } label: {
                    Label("Add Break", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Breaks")
        } footer: {
            Text("Regular breaks during your working day")
        }
    }

    private var timeOffSection: some View {
        Section {
            if schedule.timeOff.isEmpty {
                Button {
                    showingAddTimeOff = true
                } label: {
                    Label("Add Time Off", systemImage: "plus.circle")
                }
            } else {
                ForEach(schedule.timeOff) { timeOff in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(timeOff.type.rawValue)
                                .font(.headline)
                            Spacer()
                            Text("\(timeOff.durationInDays) day\(timeOff.durationInDays == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(timeOff.startDate, style: .date) - \(timeOff.endDate, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let reason = timeOff.reason {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    schedule.timeOff.remove(atOffsets: indexSet)
                }

                Button {
                    showingAddTimeOff = true
                } label: {
                    Label("Add Time Off", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Time Off")
        } footer: {
            Text("Vacations, holidays, and other time away")
        }
    }

    // MARK: - Helper Methods

    private func binding(for day: DayOfWeek) -> Binding<WorkingHours> {
        Binding(
            get: {
                schedule.weeklyHours[day] ?? WorkingHours(isWorking: false)
            },
            set: { newValue in
                schedule.weeklyHours[day] = newValue
            }
        )
    }

    private func formatBreakTime(_ breakPeriod: BreakPeriod) -> String {
        let calendar = Calendar.current
        let date = Date()

        guard let startTime = calendar.date(bySettingHour: breakPeriod.startHour,
                                           minute: breakPeriod.startMinute,
                                           second: 0,
                                           of: date) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(formatter.string(from: startTime)) (\(breakPeriod.durationMinutes) min)"
    }

    private func saveSchedule() {
        schedule.updatedAt = Date()
        // TODO: Save to database
        dismiss()
    }
}

// MARK: - Day Working Hours View

struct DayWorkingHoursView: View {
    let day: DayOfWeek
    @Binding var workingHours: WorkingHours

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                Toggle("Working on \(day.name)", isOn: $workingHours.isWorking)
            }

            if workingHours.isWorking {
                Section("Working Hours") {
                    HStack {
                        Text("Start")
                        Spacer()
                        Picker("Start Hour", selection: $workingHours.startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(":")

                        Picker("Start Minute", selection: $workingHours.startMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("End")
                        Spacer()
                        Picker("End Hour", selection: $workingHours.endHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(":")

                        Picker("End Minute", selection: $workingHours.endMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("Total Hours")
                        Spacer()
                        Text("\(workingHours.totalMinutes / 60) hours \(workingHours.totalMinutes % 60) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Add Break View

struct AddBreakView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedDays: Set<DayOfWeek> = []
    @State private var startHour = 12
    @State private var startMinute = 0
    @State private var durationMinutes = 60
    @State private var description = ""

    let onSave: (BreakPeriod) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Days") {
                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                        Toggle(day.name, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                    }
                }

                Section("Time") {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        Picker("Hour", selection: $startHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(":")

                        Picker("Minute", selection: $startMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Duration", selection: $durationMinutes) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("60 minutes").tag(60)
                        Text("90 minutes").tag(90)
                    }
                }

                Section("Description (Optional)") {
                    TextField("e.g., Lunch break", text: $description)
                }
            }
            .navigationTitle("Add Break")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        var breakPeriod = BreakPeriod(
                            daysOfWeek: Array(selectedDays),
                            startHour: startHour,
                            startMinute: startMinute,
                            durationMinutes: durationMinutes
                        )
                        breakPeriod.description = description.isEmpty ? nil : description
                        onSave(breakPeriod)
                        dismiss()
                    }
                    .disabled(selectedDays.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Time Off View

struct AddTimeOffView: View {
    @Environment(\.dismiss) var dismiss

    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var type: TimeOffType = .vacation
    @State private var reason = ""

    let onSave: (TimeOffPeriod) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(TimeOffType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date])

                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(durationInDays) day\(durationInDays == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reason (Optional)") {
                    TextField("e.g., Family vacation", text: $reason, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Time Off")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        var timeOff = TimeOffPeriod(startDate: startDate, endDate: endDate, type: type)
                        timeOff.reason = reason.isEmpty ? nil : reason
                        onSave(timeOff)
                        dismiss()
                    }
                }
            }
        }
    }

    private var durationInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
}

// MARK: - Preview

#Preview {
    AvailabilitySettingsView(userId: UUID())
}

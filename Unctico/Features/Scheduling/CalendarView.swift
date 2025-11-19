// CalendarView.swift
// Enhanced calendar view with week and day layouts

import SwiftUI

/// Calendar view for viewing and managing appointments
struct CalendarView: View {

    // MARK: - State

    @StateObject private var appointmentManager = AppointmentManager()

    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .week
    @State private var showingNewAppointment = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // View mode selector
            viewModeSelector

            // Calendar view based on mode
            ScrollView {
                switch viewMode {
                case .day:
                    dayView
                case .week:
                    weekView
                case .month:
                    monthView
                }
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewAppointment = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button("Today") {
                    selectedDate = Date()
                }
            }
        }
        .sheet(isPresented: $showingNewAppointment) {
            BookAppointmentView(appointmentManager: appointmentManager, selectedDate: selectedDate)
        }
    }

    // MARK: - View Components

    /// View mode selector (Day/Week/Month)
    private var viewModeSelector: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    /// Day view - shows hourly schedule
    private var dayView: some View {
        VStack(spacing: 0) {
            // Date navigation
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(selectedDate, style: .date)
                    .font(.headline)

                Spacer()

                Button {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // Hourly schedule
            DayScheduleView(date: selectedDate, appointments: appointmentManager.appointments(on: selectedDate))
        }
    }

    /// Week view - shows 7 days
    private var weekView: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text("Week of \(weekStart, style: .date)")
                    .font(.headline)

                Spacer()

                Button {
                    selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // 7-day grid
            WeekScheduleView(startDate: weekStart, appointments: weekAppointments)
        }
    }

    /// Month view - calendar grid
    private var monthView: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(.headline)

                Spacer()

                Button {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // Month grid
            MonthGridView(month: selectedDate, appointments: monthAppointments) { date in
                selectedDate = date
                viewMode = .day
            }
        }
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch viewMode {
        case .day:
            return "Day"
        case .week:
            return "Week"
        case .month:
            return "Month"
        }
    }

    private var weekStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
    }

    private var weekEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var weekAppointments: [Appointment] {
        appointmentManager.appointments(from: weekStart, to: weekEnd)
    }

    private var monthStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
    }

    private var monthEnd: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
    }

    private var monthAppointments: [Appointment] {
        appointmentManager.appointments(from: monthStart, to: monthEnd)
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - Day Schedule View

struct DayScheduleView: View {
    let date: Date
    let appointments: [Appointment]

    /// Hours to display (8am to 8pm)
    private let hours = Array(8...20)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)

                    // Hour divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1)

                    // Appointments for this hour
                    ZStack(alignment: .topLeading) {
                        // Background
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 60)

                        // Appointments
                        ForEach(appointmentsForHour(hour)) { appointment in
                            AppointmentCardView(appointment: appointment)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .frame(height: 60)

                Divider()
            }
        }
        .padding(.horizontal)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func appointmentsForHour(_ hour: Int) -> [Appointment] {
        let calendar = Calendar.current
        return appointments.filter { appointment in
            let appointmentHour = calendar.component(.hour, from: appointment.startDateTime)
            return appointmentHour == hour
        }
    }
}

// MARK: - Week Schedule View

struct WeekScheduleView: View {
    let startDate: Date
    let appointments: [Appointment]

    private var weekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // Day headers
            ForEach(weekDays, id: \.self) { date in
                VStack(spacing: 4) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(date, format: .dateTime.day())
                        .font(.title3)
                        .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                }
            }

            // Appointment counts for each day
            ForEach(weekDays, id: \.self) { date in
                let dayAppointments = appointmentsForDate(date)

                VStack(spacing: 4) {
                    if dayAppointments.isEmpty {
                        Text("-")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(dayAppointments.count)")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        ForEach(dayAppointments.prefix(3)) { appointment in
                            Text(appointment.timeRangeDisplay)
                                .font(.caption2)
                                .lineLimit(1)
                        }

                        if dayAppointments.count > 3 {
                            Text("+\(dayAppointments.count - 3) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }

    private func appointmentsForDate(_ date: Date) -> [Appointment] {
        let calendar = Calendar.current
        return appointments.filter { appointment in
            calendar.isDate(appointment.startDateTime, inSameDayAs: date)
        }
    }
}

// MARK: - Month Grid View

struct MonthGridView: View {
    let month: Date
    let appointments: [Appointment]
    let onDateTap: (Date) -> Void

    private var monthDays: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        var dates: [Date] = []

        // Get the first day of the month
        var currentDate = monthInterval.start

        // Add days from the month
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dates
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // Weekday headers
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            // Days of the month
            ForEach(monthDays, id: \.self) { date in
                let dayAppointments = appointmentsForDate(date)

                Button {
                    onDateTap(date)
                } label: {
                    VStack(spacing: 2) {
                        Text(date, format: .dateTime.day())
                            .font(.subheadline)
                            .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)

                        if !dayAppointments.isEmpty {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding()
    }

    private func appointmentsForDate(_ date: Date) -> [Appointment] {
        let calendar = Calendar.current
        return appointments.filter { appointment in
            calendar.isDate(appointment.startDateTime, inSameDayAs: date)
        }
    }
}

// MARK: - Appointment Card View

struct AppointmentCardView: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Rectangle()
                .fill(statusColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.timeRangeDisplay)
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(appointment.serviceType.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // TODO: Show client name when we have client data
            }

            Spacer()

            Image(systemName: appointment.status.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        switch appointment.status {
        case .scheduled:
            return .blue
        case .confirmed:
            return .green
        case .checkedIn, .inProgress:
            return .orange
        case .completed:
            return .green
        case .cancelled, .noShow:
            return .red
        case .rescheduled:
            return .yellow
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
    }
}

// CalendarView.swift
// Calendar view for appointments
// QA Note: Shows appointments in calendar format

import SwiftUI

struct CalendarView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var selectedDate = Date()
    @State private var showingAddAppointment = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar picker
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Divider()

                // Appointments for selected date
                appointmentsList

            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAppointment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AddAppointmentView(selectedDate: selectedDate)
            }
        }
    }

    // MARK: - View Components

    /// List of appointments for selected date
    private var appointmentsList: some View {
        let appointments = dataManager.getAppointments(for: selectedDate)

        return Group {
            if appointments.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No appointments on this date")
                        .foregroundColor(.secondary)

                    Button(action: { showingAddAppointment = true }) {
                        Text("Add Appointment")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appointments) { appointment in
                    AppointmentRow(appointment: appointment)
                }
            }
        }
    }
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(DataManager())
    }
}

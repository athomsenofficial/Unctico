// DashboardView.swift
// Main dashboard/home screen
// QA Note: First screen after login - shows today's appointments and quick stats

import SwiftUI

struct DashboardView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthManager

    // MARK: - State

    @State private var currentDate = Date()

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Welcome header
                    welcomeHeader

                    // Today's stats
                    todayStats

                    // Today's appointments
                    todayAppointments

                    // Quick actions
                    quickActions

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authManager.logout() }) {
                        Image(systemName: "power")
                    }
                }
            }
        }
    }

    // MARK: - View Components

    /// Welcome header with user name
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(authManager.currentUser?.firstName ?? "Therapist")
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()

            // Profile icon
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(authManager.currentUser?.firstName.prefix(1).uppercased() ?? "T")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    /// Today's statistics
    private var todayStats: some View {
        let appointments = dataManager.getAppointments(for: currentDate)
        let completedCount = appointments.filter { $0.status == .completed }.count
        let totalRevenue = appointments.filter { $0.paid }.reduce(Decimal(0)) { $0 + $1.price }

        return VStack(spacing: 15) {
            Text("Today's Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 15) {
                // Total appointments
                StatCard(
                    title: "Appointments",
                    value: "\(appointments.count)",
                    icon: "calendar",
                    color: .blue
                )

                // Completed
                StatCard(
                    title: "Completed",
                    value: "\(completedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                // Revenue
                StatCard(
                    title: "Revenue",
                    value: "$\(totalRevenue)",
                    icon: "dollarsign.circle.fill",
                    color: .purple
                )
            }
        }
    }

    /// Today's appointments list
    private var todayAppointments: some View {
        let appointments = dataManager.getAppointments(for: currentDate)
            .sorted { $0.startTime < $1.startTime }

        return VStack(spacing: 10) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                Spacer()
                Text("\(currentDate, formatter: DateFormatter.mediumDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if appointments.isEmpty {
                // No appointments today
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No appointments today")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // List appointments
                ForEach(appointments) { appointment in
                    AppointmentRow(appointment: appointment)
                }
            }
        }
    }

    /// Quick action buttons
    private var quickActions: some View {
        VStack(spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                NavigationLink(destination: AddClientView()) {
                    QuickActionButton(title: "Add New Client", icon: "person.crop.circle.badge.plus", color: .blue)
                }

                NavigationLink(destination: AddAppointmentView()) {
                    QuickActionButton(title: "Schedule Appointment", icon: "calendar.badge.plus", color: .green)
                }

                NavigationLink(destination: CreateSOAPNoteView()) {
                    QuickActionButton(title: "Create SOAP Note", icon: "doc.text.fill", color: .orange)
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Appointment Row Component

struct AppointmentRow: View {
    let appointment: Appointment
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.startTime, formatter: DateFormatter.timeOnly)
                    .font(.headline)
                Text("\(appointment.duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .leading)

            // Client info
            VStack(alignment: .leading, spacing: 2) {
                if let client = dataManager.getClient(id: appointment.clientId) {
                    Text(client.fullName)
                        .font(.headline)
                } else {
                    Text("Unknown Client")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Text(appointment.serviceType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            Text(appointment.status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(appointment.status).opacity(0.2))
                .foregroundColor(statusColor(appointment.status))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }

    private func statusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .confirmed: return .green
        case .checkedIn, .inProgress: return .purple
        case .completed: return .gray
        case .cancelled, .noShow: return .red
        case .rescheduled: return .orange
        }
    }
}

// MARK: - Quick Action Button Component

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(DataManager())
            .environmentObject(AuthManager())
    }
}

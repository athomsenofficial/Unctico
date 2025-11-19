import SwiftUI

struct DashboardView: View {
    @ObservedObject private var appointmentRepo = AppointmentRepository.shared
    @ObservedObject private var transactionRepo = TransactionRepository.shared

    var todayAppointments: [Appointment] {
        appointmentRepo.getTodaysAppointments()
    }

    var weekRevenue: Double {
        transactionRepo.getTotalRevenue(in: transactionRepo.getThisWeekRange())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    WelcomeCard()
                    TodayOverviewSection(appointments: todayAppointments)
                    QuickMetricsGrid(weekRevenue: weekRevenue, pendingTasks: 0)
                    UpcomingAppointmentsList(appointments: todayAppointments)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color.massageBackground.opacity(0.3))
        }
    }
}

struct WelcomeCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(timeOfDay())")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Ready to provide healing touch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundColor(.tranquilTeal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private func timeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
}

struct TodayOverviewSection: View {
    let appointments: [Appointment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.headline)

            HStack(spacing: 16) {
                OverviewMetric(
                    value: "\(appointments.count)",
                    label: "Appointments",
                    icon: "calendar",
                    color: .calmingBlue
                )

                OverviewMetric(
                    value: "\(appointments.filter { $0.status == .completed }.count)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .soothingGreen
                )

                OverviewMetric(
                    value: "\(appointments.filter { $0.status == .scheduled }.count)",
                    label: "Upcoming",
                    icon: "clock.fill",
                    color: .tranquilTeal
                )
            }
        }
    }
}

struct OverviewMetric: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickMetricsGrid: View {
    let weekRevenue: Double
    let pendingTasks: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 16) {
                MetricCard(
                    title: "Revenue",
                    value: "$\(Int(weekRevenue))",
                    icon: "dollarsign.circle.fill",
                    color: .soothingGreen
                )

                MetricCard(
                    title: "Tasks",
                    value: "\(pendingTasks)",
                    icon: "list.bullet.circle.fill",
                    color: .softLavender
                )
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct UpcomingAppointmentsList: View {
    let appointments: [Appointment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Appointments")
                .font(.headline)

            if appointments.isEmpty {
                EmptyStateView(message: "No appointments scheduled")
            } else {
                ForEach(appointments.prefix(3)) { appointment in
                    AppointmentRow(appointment: appointment)
                }
            }
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.startTime, style: .time)
                    .font(.headline)

                Text(appointment.serviceType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(status: appointment.status)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct StatusBadge: View {
    let status: AppointmentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .scheduled: return .blue
        case .confirmed: return .green
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        case .noShow: return .gray
        }
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(12)
    }
}

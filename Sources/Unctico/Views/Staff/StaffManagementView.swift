import SwiftUI

/// Comprehensive staff and multi-therapist management system
struct StaffManagementView: View {
    @State private var selectedTab = 0
    @State private var showingNewStaff = false
    @State private var selectedStaff: StaffMember?
    @State private var showingStaffDetail = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("All Staff").tag(0)
                    Text("Schedule").tag(1)
                    Text("Performance").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedTab {
                case 0:
                    StaffListView(
                        selectedStaff: $selectedStaff,
                        showingDetail: $showingStaffDetail
                    )
                case 1:
                    StaffScheduleView()
                case 2:
                    StaffPerformanceView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Staff Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewStaff = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewStaff) {
                AddStaffView()
            }
            .sheet(isPresented: $showingStaffDetail) {
                if let staff = selectedStaff {
                    StaffDetailView(staff: staff)
                }
            }
        }
    }
}

// MARK: - Staff List View

struct StaffListView: View {
    @Binding var selectedStaff: StaffMember?
    @Binding var showingDetail: Bool
    @State private var staff: [StaffMember] = [] // TODO: Load from repository
    @State private var searchText = ""
    @State private var selectedRole: StaffRole? = nil
    @State private var showActiveOnly = true

    private var filteredStaff: [StaffMember] {
        var filtered = staff

        if showActiveOnly {
            filtered = filtered.filter { $0.status == .active }
        }

        if let role = selectedRole {
            filtered = filtered.filter { $0.role == role }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.fullName.lowercased().contains(searchText.lowercased()) ||
                $0.email.lowercased().contains(searchText.lowercased())
            }
        }

        return filtered.sorted { $0.lastName < $1.lastName }
    }

    private var staffByRole: [(StaffRole, [StaffMember])] {
        let grouped = Dictionary(grouping: filteredStaff) { $0.role }
        return grouped.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search staff...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // Filters
                HStack(spacing: 12) {
                    Toggle(isOn: $showActiveOnly) {
                        Label("Active Only", systemImage: "checkmark.circle")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showActiveOnly ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .foregroundColor(showActiveOnly ? .green : .primary)
                    .cornerRadius(8)

                    Menu {
                        Button("All Roles") { selectedRole = nil }
                        Divider()
                        ForEach(StaffRole.allCases, id: \.self) { role in
                            Button {
                                selectedRole = role
                            } label: {
                                Label(role.rawValue, systemImage: role.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedRole?.rawValue ?? "Role")
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedRole != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedRole != nil ? .blue : .primary)
                        .cornerRadius(8)
                    }

                    Spacer()
                }
            }
            .padding()

            Divider()

            // Staff list
            if filteredStaff.isEmpty {
                StaffEmptyStateView(
                    icon: "person.3",
                    title: staff.isEmpty ? "No Staff Members" : "No Results",
                    message: staff.isEmpty ? "Add your first staff member to get started" : "Try adjusting your search or filters"
                )
            } else {
                List {
                    ForEach(staffByRole, id: \.0) { role, members in
                        Section {
                            ForEach(members) { member in
                                Button {
                                    selectedStaff = member
                                    showingDetail = true
                                } label: {
                                    StaffRowView(staff: member)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Image(systemName: role.icon)
                                Text(role.rawValue)
                                Text("(\(members.count))")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct StaffRowView: View {
    let staff: StaffMember

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo placeholder
            ZStack {
                Circle()
                    .fill(colorForRole(staff.role.color).opacity(0.2))
                    .frame(width: 50, height: 50)

                if let photoData = staff.profilePhoto, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Text(staff.firstName.prefix(1) + staff.lastName.prefix(1))
                        .font(.headline)
                        .foregroundColor(colorForRole(staff.role.color))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(staff.fullName)
                    .font(.headline)

                if !staff.credentials.isEmpty {
                    Text(staff.credentialsString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Label(staff.role.rawValue, systemImage: staff.role.icon)
                        .font(.caption)
                        .foregroundColor(colorForRole(staff.role.color))

                    if staff.isLicenseExpiringSoon {
                        Label("License expiring", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if staff.isLicenseExpired {
                        Label("License expired", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadgeStaff(status: staff.status)

                if !staff.specialties.isEmpty {
                    Text("\(staff.specialties.count) specialties")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func colorForRole(_ colorName: String) -> Color {
        switch colorName {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "teal": return .teal
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

struct StatusBadgeStaff: View {
    let status: EmploymentStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.rawValue)
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(colorForStatus.opacity(0.1))
        .foregroundColor(colorForStatus)
        .cornerRadius(4)
    }

    private var colorForStatus: Color {
        switch status.color {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Staff Detail View

struct StaffDetailView: View {
    let staff: StaffMember
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(colorForRole(staff.role.color).opacity(0.2))
                                .frame(width: 80, height: 80)

                            if let photoData = staff.profilePhoto, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Text(staff.firstName.prefix(1) + staff.lastName.prefix(1))
                                    .font(.title.weight(.bold))
                                    .foregroundColor(colorForRole(staff.role.color))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(staff.fullName)
                                .font(.title2.weight(.bold))

                            if !staff.credentials.isEmpty {
                                Text(staff.credentialsString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Image(systemName: staff.role.icon)
                                Text(staff.role.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundColor(colorForRole(staff.role.color))

                            StatusBadgeStaff(status: staff.status)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Contact information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            ContactRow(icon: "envelope.fill", label: "Email", value: staff.email)
                            ContactRow(icon: "phone.fill", label: "Phone", value: staff.phone)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // License information
                    if let licenseNumber = staff.licenseNumber {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("License Information")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("License Number")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(licenseNumber)
                                        .font(.subheadline.weight(.medium))
                                }

                                if let expiration = staff.licenseExpiration {
                                    HStack {
                                        Text("Expiration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(expiration.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(staff.isLicenseExpired ? .red : (staff.isLicenseExpiringSoon ? .orange : .primary))
                                    }

                                    if staff.isLicenseExpired {
                                        Label("License has expired!", systemImage: "exclamationmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else if staff.isLicenseExpiringSoon {
                                        Label("License expiring within 30 days", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    // Specialties
                    if !staff.specialties.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Specialties")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(staff.specialties, id: \.self) { specialty in
                                    Text(specialty)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Compensation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Compensation")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Type")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(staff.compensation.compensationType.rawValue)
                                    .font(.subheadline.weight(.medium))
                            }

                            HStack {
                                Text("Pay Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(Int(staff.compensation.payRate))")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.green)
                            }

                            if let commissionRate = staff.compensation.commissionRate {
                                HStack {
                                    Text("Commission")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(commissionRate * 100))%")
                                        .font(.subheadline.weight(.medium))
                                }
                            }

                            HStack {
                                Text("Pay Schedule")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(staff.compensation.paySchedule.rawValue)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Employment dates
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Employment")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Start Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(staff.startDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.medium))
                            }

                            if let endDate = staff.endDate {
                                HStack {
                                    Text("End Date")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.weight(.medium))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Bio
                    if let bio = staff.bio {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Biography")
                                .font(.headline)

                            Text(bio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            // TODO: Edit staff
                        } label: {
                            Label("Edit Staff Member", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }

                        Button {
                            // TODO: Manage availability
                        } label: {
                            Label("Manage Availability", systemImage: "calendar")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Staff Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func colorForRole(_ colorName: String) -> Color {
        switch colorName {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "teal": return .teal
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
    }
}

// FlowLayout for specialty tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Staff Schedule View

struct StaffScheduleView: View {
    @State private var selectedDate = Date()
    @State private var staff: [StaffMember] = [] // TODO: Load from repository

    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()

            List {
                ForEach(staff.filter { $0.status == .active }) { member in
                    Section {
                        // TODO: Show availability blocks for this staff member on selected date
                        Text("Availability blocks for \(member.fullName)")
                            .foregroundColor(.secondary)
                    } header: {
                        HStack {
                            Text(member.fullName)
                            Spacer()
                            Text(member.role.rawValue)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Staff Performance View

struct StaffPerformanceView: View {
    @State private var staff: [StaffMember] = [] // TODO: Load from repository
    @State private var selectedPeriod: AnalyticsPeriod = .thisMonth

    var body: some View {
        VStack(spacing: 0) {
            // Period selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([AnalyticsPeriod.thisWeek, .thisMonth, .thisQuarter, .thisYear], id: \.self) { period in
                        Button {
                            selectedPeriod = period
                        } label: {
                            Text(period.rawValue)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedPeriod == period ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }

            Divider()

            List {
                ForEach(staff.filter { $0.status == .active && (staff.role == .therapist || $0.role == .leadTherapist) }) { member in
                    Section {
                        // TODO: Show performance metrics for this staff member
                        VStack(alignment: .leading, spacing: 12) {
                            PerformanceMetricRow(label: "Appointments", value: "--", icon: "calendar")
                            PerformanceMetricRow(label: "Revenue", value: "$--", icon: "dollarsign.circle")
                            PerformanceMetricRow(label: "Satisfaction", value: "-.-/5.0", icon: "star")
                            PerformanceMetricRow(label: "Hours Worked", value: "--", icon: "clock")
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Text(member.fullName)
                            Spacer()
                            Text(member.role.rawValue)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct PerformanceMetricRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

// MARK: - Add Staff View

struct AddStaffView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedRole: StaffRole = .therapist
    @State private var licenseNumber = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                } header: {
                    Text("Basic Information")
                }

                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Contact Information")
                }

                Section {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(StaffRole.allCases, id: \.self) { role in
                            Label(role.rawValue, systemImage: role.icon).tag(role)
                        }
                    }
                } header: {
                    Text("Role")
                }

                Section {
                    TextField("License Number", text: $licenseNumber)
                } header: {
                    Text("License Information (Optional)")
                }

                Section {
                    Button {
                        // TODO: Save staff member
                        dismiss()
                    } label: {
                        Text("Add Staff Member")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty)
                }
            }
            .navigationTitle("Add Staff Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Empty State

struct StaffEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    StaffManagementView()
}

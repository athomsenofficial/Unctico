import SwiftUI

/// Comprehensive package and membership management system
struct PackageManagementView: View {
    @State private var selectedTab = 0
    @State private var showingNewPackage = false
    @State private var selectedPackage: Package?
    @State private var showingPackageDetail = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Packages").tag(0)
                    Text("Client Purchases").tag(1)
                    Text("Create").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch selectedTab {
                case 0:
                    PackagesListView(
                        selectedPackage: $selectedPackage,
                        showingDetail: $showingPackageDetail
                    )
                case 1:
                    ClientPurchasesView()
                case 2:
                    CreatePackageView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Packages & Memberships")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPackageDetail) {
                if let package = selectedPackage {
                    PackageDetailView(package: package)
                }
            }
        }
    }
}

// MARK: - Packages List View

struct PackagesListView: View {
    @Binding var selectedPackage: Package?
    @Binding var showingDetail: Bool
    @State private var searchText = ""
    @State private var selectedType: PackageType? = nil
    @State private var showActiveOnly = true

    private var filteredPackages: [Package] {
        var packages = Package.packageTemplates

        if showActiveOnly {
            packages = packages.filter { $0.isActive }
        }

        if let type = selectedType {
            packages = packages.filter { $0.packageType == type }
        }

        if !searchText.isEmpty {
            packages = Package.search(searchText)
        }

        return packages
    }

    private var packagesByType: [(PackageType, [Package])] {
        let grouped = Dictionary(grouping: filteredPackages) { $0.packageType }
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
                    TextField("Search packages...", text: $searchText)
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
                        Button("All Types") { selectedType = nil }
                        Divider()
                        ForEach(PackageType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedType?.rawValue ?? "Type")
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedType != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(selectedType != nil ? .blue : .primary)
                        .cornerRadius(8)
                    }

                    Spacer()
                }
            }
            .padding()

            Divider()

            // Packages list
            if filteredPackages.isEmpty {
                PackageEmptyStateView(
                    icon: "square.stack.3d.up",
                    title: "No Packages Found",
                    message: "Try adjusting your search or filters"
                )
            } else {
                List {
                    ForEach(packagesByType, id: \.0) { type, packages in
                        Section {
                            ForEach(packages) { package in
                                Button {
                                    selectedPackage = package
                                    showingDetail = true
                                } label: {
                                    PackageRowView(package: package)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
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

struct PackageRowView: View {
    let package: Package

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: package.packageType.icon)
                    .foregroundColor(colorForType(package.packageType.color))
                    .frame(width: 24)

                Text(package.name)
                    .font(.headline)

                Spacer()

                if !package.isActive {
                    Text("INACTIVE")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(package.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 16) {
                Label(formatCurrency(package.pricing.totalPrice), systemImage: "dollarsign.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)

                if package.pricing.savings > 0 {
                    Text("Save \(package.pricing.savingsPercentage.formatted(.percent.precision(.fractionLength(0))))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()

                Text("\(package.services.reduce(0) { $0 + $1.quantity }) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "green": return .green
        case "indigo": return .indigo
        default: return .blue
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Package Detail View

struct PackageDetailView: View {
    let package: Package
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: package.packageType.icon)
                                .font(.title)
                                .foregroundColor(colorForType(package.packageType.color))

                            VStack(alignment: .leading) {
                                Text(package.packageType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(package.name)
                                    .font(.title2.weight(.bold))
                            }

                            Spacer()

                            if !package.isActive {
                                Text("INACTIVE")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.gray)
                                    .cornerRadius(4)
                            }
                        }

                        Text(package.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Pricing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pricing")
                            .font(.headline)

                        HStack(spacing: 16) {
                            PriceCard(
                                title: "Package Price",
                                amount: package.pricing.totalPrice,
                                color: .green
                            )

                            PriceCard(
                                title: "Retail Value",
                                amount: package.pricing.retailValue,
                                color: .blue
                            )
                        }

                        if package.pricing.savings > 0 {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.orange)
                                Text("Save \(formatCurrency(package.pricing.savings)) (\(package.pricing.savingsPercentage.formatted(.percent.precision(.fractionLength(0)))))")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }

                        HStack(spacing: 12) {
                            if package.pricing.taxable {
                                Label("Taxable", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if package.pricing.refundable {
                                Label("Refundable", systemImage: "arrow.uturn.left.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Services included
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Services Included")
                            .font(.headline)

                        ForEach(package.services) { service in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(service.serviceName)
                                        .font(.subheadline.weight(.medium))
                                    Text(service.formattedDuration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(service.quantity)x")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    Divider()

                    // Validity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Validity & Terms")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Valid For", value: package.validity.description)
                            InfoRow(label: "Expiration Policy", value: package.validity.expirationPolicy.rawValue)

                            if package.validity.transferable {
                                Label("Transferable", systemImage: "person.2.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }

                            if package.validity.shareable {
                                Label("Can be shared with family", systemImage: "person.3.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Restrictions
                    if let restrictions = package.restrictions {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Restrictions")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                if let minAdvance = restrictions.minimumAdvanceBooking {
                                    InfoRow(label: "Min. Advance Booking", value: "\(minAdvance) hours")
                                }

                                if let maxAdvance = restrictions.maximumAdvanceBooking {
                                    InfoRow(label: "Max. Advance Booking", value: "\(maxAdvance) days")
                                }

                                if let maxPerWeek = restrictions.maxSessionsPerWeek {
                                    InfoRow(label: "Max Per Week", value: "\(maxPerWeek) sessions")
                                }

                                if let maxPerMonth = restrictions.maxSessionsPerMonth {
                                    InfoRow(label: "Max Per Month", value: "\(maxPerMonth) sessions")
                                }

                                if restrictions.newClientsOnly {
                                    Label("New Clients Only", systemImage: "person.badge.plus")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                if restrictions.requiresMembership {
                                    Label("Requires Active Membership", systemImage: "star.circle")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            // TODO: Sell package
                        } label: {
                            Label("Sell Package to Client", systemImage: "cart.badge.plus")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }

                        Button {
                            // TODO: Edit package
                        } label: {
                            Label("Edit Package", systemImage: "pencil")
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
            .navigationTitle("Package Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            // TODO: Duplicate
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Button {
                            // TODO: Toggle active
                        } label: {
                            Label(package.isActive ? "Deactivate" : "Activate", systemImage: package.isActive ? "pause.circle" : "play.circle")
                        }

                        Button(role: .destructive) {
                            // TODO: Delete
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func colorForType(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "green": return .green
        case "indigo": return .indigo
        default: return .blue
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct PriceCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(formatCurrency(amount))
                .font(.title3.weight(.bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
        }
    }
}

// MARK: - Client Purchases View

struct ClientPurchasesView: View {
    @State private var purchases: [ClientPackagePurchase] = [] // TODO: Load from repository
    @State private var filterStatus: PurchaseStatus? = nil
    @State private var searchText = ""

    private var filteredPurchases: [ClientPackagePurchase] {
        var filtered = purchases

        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.packageName.lowercased().contains(searchText.lowercased())
            }
        }

        return filtered.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search purchases...", text: $searchText)
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

                // Status filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button {
                            filterStatus = nil
                        } label: {
                            StatusChip(title: "All", isSelected: filterStatus == nil)
                        }

                        ForEach([PurchaseStatus.active, .expired, .exhausted, .suspended, .cancelled], id: \.self) { status in
                            Button {
                                filterStatus = status
                            } label: {
                                StatusChip(
                                    title: status.rawValue,
                                    icon: status.icon,
                                    isSelected: filterStatus == status
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()

            Divider()

            // Purchases list
            if filteredPurchases.isEmpty {
                PackageEmptyStateView(
                    icon: "cart.badge.questionmark",
                    title: purchases.isEmpty ? "No Purchases Yet" : "No Results",
                    message: purchases.isEmpty ? "Client package purchases will appear here" : "Try adjusting your search or filters"
                )
            } else {
                List {
                    ForEach(filteredPurchases) { purchase in
                        PurchaseRowView(purchase: purchase)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct StatusChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

struct PurchaseRowView: View {
    let purchase: ClientPackagePurchase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(purchase.packageName)
                    .font(.headline)

                Spacer()

                StatusBadge(status: purchase.status)
            }

            HStack {
                Text("Purchased: \(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let expirationDate = purchase.expirationDate {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Expires: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(purchase.isExpired ? .red : .secondary)
                }
            }

            // Sessions remaining
            HStack(spacing: 16) {
                Label("\(purchase.totalSessionsRemaining) remaining", systemImage: "ticket")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(purchase.utilizationRate.formatted(.percent.precision(.fractionLength(0)))) used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if purchase.autoRenew {
                Label("Auto-renew enabled", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: PurchaseStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.rawValue)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForStatus.opacity(0.1))
        .foregroundColor(colorForStatus)
        .cornerRadius(4)
    }

    private var colorForStatus: Color {
        switch status.color {
        case "green": return .green
        case "orange": return .orange
        case "gray": return .gray
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
        default: return .blue
        }
    }
}

// MARK: - Create Package View

struct CreatePackageView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType: PackageType = .sessionPackage
    @State private var totalPrice: String = ""
    @State private var retailValue: String = ""

    var body: some View {
        Form {
            Section {
                TextField("Package Name", text: $name)

                TextEditor(text: $description)
                    .frame(minHeight: 80)

                Picker("Package Type", selection: $selectedType) {
                    ForEach(PackageType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
            } header: {
                Text("Basic Information")
            }

            Section {
                HStack {
                    Text("$")
                    TextField("Total Price", text: $totalPrice)
                        .keyboardType(.decimalPad)
                }

                HStack {
                    Text("$")
                    TextField("Retail Value", text: $retailValue)
                        .keyboardType(.decimalPad)
                }

                if let price = Double(totalPrice), let retail = Double(retailValue), retail > price {
                    let savings = retail - price
                    let percentage = (savings / retail) * 100
                    HStack {
                        Text("Savings")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(Int(savings)) (\(Int(percentage))%)")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
            } header: {
                Text("Pricing")
            }

            Section {
                Button {
                    // TODO: Save package
                } label: {
                    Text("Create Package")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .disabled(name.isEmpty || description.isEmpty || totalPrice.isEmpty)
            }
        }
    }
}

// MARK: - Empty State

struct PackageEmptyStateView: View {
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
    PackageManagementView()
}

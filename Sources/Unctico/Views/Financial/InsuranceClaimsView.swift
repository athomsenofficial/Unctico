import SwiftUI
import Combine

struct InsuranceClaimsView: View {
    @ObservedObject private var repository = InsuranceClaimRepository.shared
    @ObservedObject private var clientRepository = ClientRepository.shared
    @State private var selectedStatus: ClaimStatus? = nil
    @State private var showingAddClaim = false
    @State private var searchText = ""

    var filteredClaims: [InsuranceClaim] {
        var claims = repository.claims

        if let status = selectedStatus {
            claims = claims.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            claims = repository.searchClaims(query: searchText)
        }

        return claims.sorted { $0.dateOfService > $1.dateOfService }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ClaimsSummaryCard()
                    .padding()

                StatusFilterBar(selectedStatus: $selectedStatus)

                if filteredClaims.isEmpty {
                    EmptyClaimsView()
                } else {
                    List {
                        ForEach(filteredClaims) { claim in
                            NavigationLink(destination: ClaimDetailView(claim: claim)) {
                                ClaimRowView(claim: claim)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Insurance Claims")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClaim = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingAddClaim) {
                AddInsuranceClaimView()
            }
        }
    }
}

struct ClaimsSummaryCard: View {
    @ObservedObject private var repository = InsuranceClaimRepository.shared

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricBox(
                    title: "Total Billed",
                    value: repository.getTotalBilledAmount(),
                    color: .calmingBlue
                )

                MetricBox(
                    title: "Paid",
                    value: repository.getTotalPaidAmount(),
                    color: .soothingGreen
                )
            }

            HStack(spacing: 12) {
                MetricBox(
                    title: "Outstanding",
                    value: repository.getTotalOutstandingBalance(),
                    color: .orange
                )

                MetricBox(
                    title: "Total Claims",
                    value: Double(repository.claims.count),
                    color: .tranquilTeal,
                    format: .number
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct MetricBox: View {
    let title: String
    let value: Double
    let color: Color
    var format: FloatingPointFormatStyle<Double> = .currency(code: "USD")

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value, format: format)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatusFilterBar: View {
    @Binding var selectedStatus: ClaimStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }

                ForEach([ClaimStatus.submitted, .inReview, .approved, .paid, .denied], id: \.self) { status in
                    FilterChip(title: status.rawValue, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.tranquilTeal : Color(.systemGray6))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct ClaimRowView: View {
    let claim: InsuranceClaim
    @ObservedObject private var clientRepository = ClientRepository.shared
    @ObservedObject private var providerRepository = InsuranceClaimRepository.shared

    var clientName: String {
        clientRepository.getClient(id: claim.clientId)?.fullName ?? "Unknown Client"
    }

    var providerName: String {
        providerRepository.getProvider(id: claim.insuranceProviderId)?.name ?? "Unknown Provider"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(claim.claimNumber)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                StatusBadge(status: claim.status)
            }

            Text(clientName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(providerName, systemImage: "cross.case.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(claim.dateOfService, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Billed:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(claim.totalBilled, format: .currency(code: "USD"))
                    .font(.caption)
                    .fontWeight(.semibold)

                Spacer()

                if let paid = claim.paidAmount {
                    Text("Paid:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(paid, format: .currency(code: "USD"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.soothingGreen)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: ClaimStatus

    var statusColor: Color {
        switch status {
        case .draft, .ready:
            return .gray
        case .submitted, .inReview:
            return .calmingBlue
        case .approved, .paid, .partiallyPaid:
            return .soothingGreen
        case .denied:
            return .red
        case .appealed, .resubmitted:
            return .orange
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

struct EmptyClaimsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No insurance claims")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Create your first insurance claim to start tracking billing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClaimDetailView: View {
    @ObservedObject private var repository = InsuranceClaimRepository.shared
    @State private var claim: InsuranceClaim

    init(claim: InsuranceClaim) {
        _claim = State(initialValue: claim)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClaimHeaderCard(claim: claim)
                ClaimFinancialsCard(claim: claim)
                ClaimCodesCard(claim: claim)

                if claim.status == .denied, let reason = claim.denialReason {
                    DenialReasonCard(reason: reason)
                }

                ClaimActionsCard(claim: $claim)
            }
            .padding()
        }
        .navigationTitle("Claim Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClaimHeaderCard: View {
    let claim: InsuranceClaim
    @ObservedObject private var clientRepository = ClientRepository.shared

    var clientName: String {
        clientRepository.getClient(id: claim.clientId)?.fullName ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.claimNumber)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: claim.status)
            }

            Divider()

            HStack {
                InfoItem(label: "Service Date", value: claim.dateOfService.formatted(date: .abbreviated, time: .omitted))
                Spacer()
                if let submitted = claim.dateSubmitted {
                    InfoItem(label: "Submitted", value: submitted.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ClaimFinancialsCard: View {
    let claim: InsuranceClaim

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Summary")
                .font(.headline)

            VStack(spacing: 8) {
                FinancialRow(label: "Total Billed", amount: claim.totalBilled, color: .primary)

                if let allowed = claim.allowedAmount {
                    FinancialRow(label: "Allowed Amount", amount: allowed, color: .calmingBlue)
                }

                if let paid = claim.paidAmount {
                    FinancialRow(label: "Paid Amount", amount: paid, color: .soothingGreen)
                }

                if let patient = claim.patientResponsibility {
                    FinancialRow(label: "Patient Responsibility", amount: patient, color: .orange)
                }

                if claim.outstandingBalance > 0 {
                    Divider()
                    FinancialRow(label: "Outstanding Balance", amount: claim.outstandingBalance, color: .red, isBold: true)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct FinancialRow: View {
    let label: String
    let amount: Double
    let color: Color
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(amount, format: .currency(code: "USD"))
                .font(isBold ? .subheadline.weight(.bold) : .subheadline)
                .foregroundColor(color)
        }
    }
}

struct ClaimCodesCard: View {
    let claim: InsuranceClaim

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Codes")
                .font(.headline)

            if !claim.diagnosisCodes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diagnosis Codes (ICD-10)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(claim.diagnosisCodes, id: \.self) { code in
                        Text("• \(code): \(MassageICD10Codes.getDescription(for: code))")
                            .font(.caption)
                    }
                }
            }

            if !claim.procedureCodes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Procedure Codes (CPT)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(claim.procedureCodes) { procedure in
                        HStack {
                            Text("• \(procedure.code): \(procedure.description)")
                                .font(.caption)
                            Spacer()
                            Text(procedure.chargeAmount, format: .currency(code: "USD"))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct DenialReasonCard: View {
    let reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Denial Reason")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            Text(reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ClaimActionsCard: View {
    @Binding var claim: InsuranceClaim
    @ObservedObject private var repository = InsuranceClaimRepository.shared

    var body: some View {
        VStack(spacing: 12) {
            if claim.status == .draft || claim.status == .ready {
                Button(action: submitClaim) {
                    ActionButton(title: "Submit Claim", icon: "paperplane.fill", color: .calmingBlue)
                }
            }

            if claim.status == .denied {
                Button(action: appealClaim) {
                    ActionButton(title: "Appeal Claim", icon: "arrow.clockwise", color: .orange)
                }
            }
        }
    }

    private func submitClaim() {
        repository.submitClaim(claim)
        claim = repository.getClaim(id: claim.id) ?? claim
    }

    private func appealClaim() {
        repository.appealClaim(claim)
        claim = repository.getClaim(id: claim.id) ?? claim
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Add Insurance Claim View
struct AddInsuranceClaimView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = InsuranceClaimRepository.shared
    private let clientRepository = ClientRepository.shared

    @State private var selectedClient: Client?
    @State private var selectedProvider: InsuranceProvider?
    @State private var dateOfService = Date()
    @State private var diagnosisCode = "M79.1"
    @State private var procedureCode = "97124"
    @State private var units = 4
    @State private var chargePerUnit = 35.0

    var totalCharge: Double {
        Double(units) * chargePerUnit
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Client & Provider") {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select Client").tag(nil as Client?)
                        ForEach(clientRepository.clients) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }

                    Picker("Insurance Provider", selection: $selectedProvider) {
                        Text("Select Provider").tag(nil as InsuranceProvider?)
                        ForEach(repository.providers) { provider in
                            Text(provider.name).tag(provider as InsuranceProvider?)
                        }
                    }
                }

                Section("Service Details") {
                    DatePicker("Date of Service", selection: $dateOfService, displayedComponents: .date)

                    Picker("Diagnosis Code", selection: $diagnosisCode) {
                        ForEach(Array(MassageICD10Codes.codes.keys.sorted()), id: \.self) { code in
                            Text("\(code) - \(MassageICD10Codes.getDescription(for: code))").tag(code)
                        }
                    }

                    Picker("Procedure Code", selection: $procedureCode) {
                        ForEach(Array(MassageCPTCodes.codes.keys.sorted()), id: \.self) { code in
                            Text("\(code) - \(MassageCPTCodes.getDescription(for: code))").tag(code)
                        }
                    }

                    Stepper("Units: \(units)", value: $units, in: 1...20)

                    HStack {
                        Text("Charge per Unit")
                        Spacer()
                        Text("$")
                        TextField("35.00", value: $chargePerUnit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section {
                    HStack {
                        Text("Total Charge")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(totalCharge, format: .currency(code: "USD"))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .navigationTitle("New Insurance Claim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createClaim() }
                        .disabled(selectedClient == nil || selectedProvider == nil)
                }
            }
        }
    }

    private func createClaim() {
        guard let client = selectedClient,
              let provider = selectedProvider else { return }

        let procedure = ProcedureCode(
            code: procedureCode,
            description: MassageCPTCodes.getDescription(for: procedureCode),
            units: units,
            chargeAmount: totalCharge
        )

        let claim = InsuranceClaim(
            clientId: client.id,
            insuranceProviderId: provider.id,
            appointmentIds: [],
            dateOfService: dateOfService,
            totalBilled: totalCharge,
            diagnosisCodes: [diagnosisCode],
            procedureCodes: [procedure]
        )

        repository.addClaim(claim)
        dismiss()
    }
}

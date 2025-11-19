import SwiftUI

struct InvoiceGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var clientRepo = ClientRepository.shared
    @ObservedObject private var appointmentRepo = AppointmentRepository.shared

    @State private var selectedClient: Client?
    @State private var selectedAppointments: Set<UUID> = []
    @State private var taxRate: Double = 0.0
    @State private var discount: Double = 0.0
    @State private var notes: String = ""
    @State private var showingClientPicker = false
    @State private var generatedInvoice: Invoice?
    @State private var showingPreview = false

    var clientAppointments: [Appointment] {
        guard let client = selectedClient else { return [] }
        return appointmentRepo.getAppointments(for: client.id)
            .filter { $0.status == .completed }
    }

    var selectedAppointmentsList: [Appointment] {
        clientAppointments.filter { selectedAppointments.contains($0.id) }
    }

    var subtotal: Double {
        selectedAppointmentsList.reduce(0) { sum, appointment in
            sum + PaymentService.shared.getServicePrice(for: appointment.serviceType)
        }
    }

    var total: Double {
        let taxAmount = subtotal * taxRate
        return subtotal + taxAmount - discount
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Client") {
                    Button(action: { showingClientPicker = true }) {
                        HStack {
                            Text(selectedClient?.fullName ?? "Select Client")
                                .foregroundColor(selectedClient == nil ? .secondary : .primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let client = selectedClient {
                    Section("Services") {
                        if clientAppointments.isEmpty {
                            Text("No completed appointments found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(clientAppointments) { appointment in
                                AppointmentSelectionRow(
                                    appointment: appointment,
                                    isSelected: selectedAppointments.contains(appointment.id)
                                ) {
                                    toggleAppointmentSelection(appointment.id)
                                }
                            }
                        }
                    }

                    Section("Details") {
                        HStack {
                            Text("Tax Rate (%)")
                            Spacer()
                            TextField("0.0", value: $taxRate, format: .percent)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Discount ($)")
                            Spacer()
                            TextField("0.00", value: $discount, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes (Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextEditor(text: $notes)
                                .frame(height: 80)
                        }
                    }

                    Section("Summary") {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(subtotal, format: .currency(code: "USD"))
                        }

                        if taxRate > 0 {
                            HStack {
                                Text("Tax (\(Int(taxRate * 100))%)")
                                Spacer()
                                Text(subtotal * taxRate, format: .currency(code: "USD"))
                            }
                        }

                        if discount > 0 {
                            HStack {
                                Text("Discount")
                                Spacer()
                                Text(-discount, format: .currency(code: "USD"))
                                    .foregroundColor(.orange)
                            }
                        }

                        HStack {
                            Text("Total")
                                .fontWeight(.bold)
                            Spacer()
                            Text(total, format: .currency(code: "USD"))
                                .fontWeight(.bold)
                                .foregroundColor(.tranquilTeal)
                        }
                    }

                    Section {
                        Button(action: generateInvoice) {
                            HStack {
                                Spacer()
                                Image(systemName: "doc.text.fill")
                                Text("Generate Invoice")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(selectedAppointments.isEmpty)
                    }
                }
            }
            .navigationTitle("Create Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingClientPicker) {
                ClientPickerView(selectedClient: $selectedClient)
            }
            .sheet(isPresented: $showingPreview) {
                if let invoice = generatedInvoice, let client = selectedClient {
                    InvoicePreviewView(invoice: invoice, client: client)
                }
            }
        }
    }

    private func toggleAppointmentSelection(_ id: UUID) {
        if selectedAppointments.contains(id) {
            selectedAppointments.remove(id)
        } else {
            selectedAppointments.insert(id)
        }
    }

    private func generateInvoice() {
        guard let client = selectedClient else { return }

        generatedInvoice = PaymentService.shared.generateInvoice(
            for: client.id,
            appointments: selectedAppointmentsList,
            taxRate: taxRate,
            discount: discount
        )

        if !notes.isEmpty {
            generatedInvoice?.notes = notes
        }

        showingPreview = true
    }
}

struct AppointmentSelectionRow: View {
    let appointment: Appointment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .tranquilTeal : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.serviceType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(appointment.startTime, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(PaymentService.shared.getServicePrice(for: appointment.serviceType), format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ClientPickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var repository = ClientRepository.shared
    @Binding var selectedClient: Client?

    var body: some View {
        NavigationView {
            List {
                ForEach(repository.clients) { client in
                    Button(action: {
                        selectedClient = client
                        dismiss()
                    }) {
                        ClientRowView(client: client)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InvoicePreviewView: View {
    @Environment(\.dismiss) var dismiss
    let invoice: Invoice
    let client: Client

    @State private var showingShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Invoice Header
                    VStack(spacing: 8) {
                        Text("INVOICE")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.tranquilTeal)

                        Text(invoice.invoiceNumber)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Client Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bill To:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text(client.fullName)
                            .font(.headline)

                        if let email = client.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Line Items
                    VStack(spacing: 12) {
                        ForEach(invoice.lineItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.description)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(item.total, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }

                    Divider()

                    // Totals
                    VStack(spacing: 12) {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(invoice.subtotal, format: .currency(code: "USD"))
                        }

                        if invoice.taxAmount > 0 {
                            HStack {
                                Text("Tax (\(Int(invoice.taxRate * 100))%)")
                                Spacer()
                                Text(invoice.taxAmount, format: .currency(code: "USD"))
                            }
                        }

                        if invoice.discount > 0 {
                            HStack {
                                Text("Discount")
                                Spacer()
                                Text(-invoice.discount, format: .currency(code: "USD"))
                                    .foregroundColor(.orange)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Total")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Text(invoice.total, format: .currency(code: "USD"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.tranquilTeal)
                        }
                    }
                    .padding()
                    .background(Color.tranquilTeal.opacity(0.1))
                    .cornerRadius(12)

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: generateAndSharePDF) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share as PDF")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button(action: sendInvoiceByEmail) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Send by Email")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Invoice Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateAndSharePDF() {
        pdfURL = PDFGenerator.shared.generateInvoicePDF(invoice: invoice, client: client)
        if pdfURL != nil {
            showingShareSheet = true
        }
    }

    private func sendInvoiceByEmail() {
        if let url = PDFGenerator.shared.generateInvoicePDF(invoice: invoice, client: client) {
            CommunicationService.shared.sendInvoice(invoice: invoice, client: client, pdfURL: url)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color(.systemGray5) : Color.white)
            .foregroundColor(.tranquilTeal)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tranquilTeal, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

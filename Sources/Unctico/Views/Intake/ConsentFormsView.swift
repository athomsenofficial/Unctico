import SwiftUI

/// Consent and legal forms management system
struct ConsentFormsView: View {
    @State private var consentForms: [ConsentForm] = []
    @State private var showingNewForm = false
    @State private var selectedFormType: ConsentFormType?

    var body: some View {
        NavigationView {
            VStack {
                if consentForms.isEmpty {
                    ConsentFormsEmptyState()
                } else {
                    ConsentFormsList(forms: $consentForms)
                }
            }
            .navigationTitle("Consent Forms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(ConsentFormType.allCases, id: \.self) { formType in
                            Button(action: {
                                selectedFormType = formType
                                showingNewForm = true
                            }) {
                                Label(formType.rawValue, systemImage: formType.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingNewForm) {
                if let formType = selectedFormType {
                    ConsentFormBuilderView(formType: formType)
                }
            }
        }
    }
}

// MARK: - Empty State
struct ConsentFormsEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Consent Forms")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create essential legal forms for client protection and compliance")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Forms List
struct ConsentFormsList: View {
    @Binding var forms: [ConsentForm]

    var body: some View {
        List {
            ForEach(forms.sorted(by: { $0.createdDate > $1.createdDate })) { form in
                NavigationLink(destination: ConsentFormDetailView(form: form)) {
                    ConsentFormRow(form: form)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Form Row
struct ConsentFormRow: View {
    let form: ConsentForm

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: form.formType.icon)
                    .foregroundColor(form.formType.color)

                Text(form.formType.rawValue)
                    .font(.headline)

                Spacer()

                if form.isSigned {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }

            Text(form.clientName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                if let signatureDate = form.signatureDate {
                    Label(signatureDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.green)
                }

                if form.needsRenewal {
                    Label("Renewal Needed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if form.isExpired {
                    Label("Expired", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Consent Form Builder
struct ConsentFormBuilderView: View {
    @Environment(\.dismiss) var dismiss
    let formType: ConsentFormType

    @State private var content: String = ""
    @State private var signatureData: Data? = nil
    @State private var witnessName: String = ""
    @State private var witnessSignature: Data? = nil
    @State private var showingSignaturePad = false
    @State private var showingWitnessSignaturePad = false

    let practiceName = "Your Practice Name" // TODO: Get from settings
    let therapistName = "Therapist Name" // TODO: Get from current user

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Form Type Info
                    FormTypeHeader(formType: formType)

                    // Form Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Form Content")
                            .font(.headline)

                        ScrollView {
                            Text(content)
                                .font(.system(.body, design: .serif))
                                .padding()
                        }
                        .frame(height: 300)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Client Signature
                    SignatureSection(
                        title: "Client Signature",
                        signatureData: $signatureData,
                        showingPad: $showingSignaturePad,
                        isRequired: true
                    )

                    // Witness Signature (if required)
                    if formType.requiresWitness {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Witness Information")
                                .font(.headline)

                            TextField("Witness Name", text: $witnessName)
                                .textFieldStyle(.roundedBorder)

                            SignatureSection(
                                title: "Witness Signature",
                                signatureData: $witnessSignature,
                                showingPad: $showingWitnessSignaturePad,
                                isRequired: true
                            )
                        }
                    }

                    // Save Button
                    Button(action: saveForm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Signed Form")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave() ? Color.tranquilTeal : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSave())
                }
                .padding()
            }
            .navigationTitle(formType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFormContent()
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signatureData: $signatureData)
            }
            .sheet(isPresented: $showingWitnessSignaturePad) {
                SignaturePadView(signatureData: $witnessSignature)
            }
        }
    }

    private func loadFormContent() {
        content = formType.getDefaultTemplate(
            practiceName: practiceName,
            therapistName: therapistName
        )
    }

    private func canSave() -> Bool {
        let hasClientSignature = signatureData != nil
        let hasWitnessSignature = !formType.requiresWitness || (witnessSignature != nil && !witnessName.isEmpty)
        return hasClientSignature && hasWitnessSignature
    }

    private func saveForm() {
        // TODO: Save to repository with encryption
        AuditLogger.shared.log(
            event: .documentSigned,
            details: "Consent form signed: \(formType.rawValue)"
        )
        dismiss()
    }
}

// MARK: - Form Type Header
struct FormTypeHeader: View {
    let formType: ConsentFormType

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: formType.icon)
                .font(.system(size: 40))
                .foregroundColor(formType.color)
                .frame(width: 60, height: 60)
                .background(formType.color.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(formType.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)

                if formType.requiresWitness {
                    Label("Witness Required", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if let expiration = formType.expirationPeriod {
                    let years = expiration.year ?? 0
                    let months = expiration.month ?? 0
                    let expirationText = years > 0 ? "\(years) year\(years > 1 ? "s" : "")" : "\(months) month\(months > 1 ? "s" : "")"
                    Label("Expires in \(expirationText)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(formType.color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Signature Section
struct SignatureSection: View {
    let title: String
    @Binding var signatureData: Data?
    @Binding var showingPad: Bool
    let isRequired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)

                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            if let data = signatureData, let uiImage = UIImage(data: data) {
                VStack(spacing: 12) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .background(Color.white)
                        .border(Color.gray, width: 1)
                        .cornerRadius(8)

                    HStack(spacing: 12) {
                        Button(action: { showingPad = true }) {
                            HStack {
                                Image(systemName: "pencil.tip.crop.circle")
                                Text("Re-sign")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.tranquilTeal.opacity(0.1))
                            .foregroundColor(.tranquilTeal)
                            .cornerRadius(8)
                        }

                        Button(action: { signatureData = nil }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                Button(action: { showingPad = true }) {
                    HStack {
                        Image(systemName: "pencil.tip.crop.circle")
                        Text("Tap to Sign")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            }
        }
    }
}

// MARK: - Form Detail View
struct ConsentFormDetailView: View {
    let form: ConsentForm

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Header
                HStack {
                    if form.isSigned {
                        Label("Signed", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Label("Pending Signature", systemImage: "exclamationmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if form.needsRenewal {
                        Label("Renewal Needed", systemImage: "arrow.clockwise.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(form.isSigned ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(10)

                // Form Content
                Text("Form Content")
                    .font(.headline)

                Text(form.content)
                    .font(.system(.body, design: .serif))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                // Signature
                if let signatureData = form.signatureData,
                   let signatureDate = form.signatureDate,
                   let uiImage = UIImage(data: signatureData) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Signature")
                            .font(.headline)

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .background(Color.white)
                            .border(Color.gray, width: 1)
                            .cornerRadius(8)

                        Text("Signed on \(signatureDate, style: .date) at \(signatureDate, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Form Information")
                        .font(.headline)

                    MetadataRow(label: "Version", value: form.version)
                    MetadataRow(label: "Created", value: form.createdDate, style: .date)

                    if let expiration = form.expirationDate {
                        MetadataRow(label: "Expires", value: expiration, style: .date)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle(form.formType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    init(label: String, value: Date, style: Date.FormatStyle.DateStyle) {
        self.label = label
        self.value = value.formatted(date: style, time: .omitted)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
        }
    }
}

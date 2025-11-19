// ClientsView.swift
// View for managing massage therapy clients

import SwiftUI

/// Clients list and management view
struct ClientsView: View {

    // MARK: - State

    @State private var searchText = ""
    @State private var showingAddClient = false

    // Mock data for now (will be replaced with database)
    @State private var clients: [Client] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if clients.isEmpty {
                    emptyState
                } else {
                    clientList
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $searchText, prompt: "Search clients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView { newClient in
                    clients.append(newClient)
                }
            }
        }
    }

    // MARK: - View Components

    /// Empty state when no clients
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Clients Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first client to get started")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddClient = true
            } label: {
                Text("Add Client")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }

    /// List of clients
    private var clientList: some View {
        List {
            ForEach(filteredClients) { client in
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    ClientRowView(client: client)
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Filter clients based on search text
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.fullName.localizedCaseInsensitiveContains(searchText) ||
                client.email?.localizedCaseInsensitiveContains(searchText) == true ||
                client.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
}

// MARK: - Client Row Component

struct ClientRowView: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(client.fullName)
                .font(.headline)

            if let phone = client.phoneNumber {
                Text(phone)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let email = client.email {
                Text(email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Client View

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""

    let onSave: (Client) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func saveClient() {
        var newClient = Client(firstName: firstName, lastName: lastName)
        newClient.email = email.isEmpty ? nil : email
        newClient.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber

        onSave(newClient)
        dismiss()
    }
}

// MARK: - Client Detail View

struct ClientDetailView: View {
    let client: Client

    @State private var showingIntakeForm = false
    @State private var showingMedicalHistory = false

    var body: some View {
        List {
            Section("Personal Information") {
                LabeledRow(label: "Name", value: client.fullName)

                if let email = client.email {
                    LabeledRow(label: "Email", value: email)
                }

                if let phone = client.phoneNumber {
                    LabeledRow(label: "Phone", value: phone)
                }

                if let age = client.age {
                    LabeledRow(label: "Age", value: "\(age) years")
                }
            }

            Section("Clinical Documentation") {
                NavigationLink {
                    IntakeFormView(client: client)
                } label: {
                    Label("Intake Form", systemImage: "doc.text.fill")
                }

                NavigationLink {
                    MedicalHistoryView(client: client)
                } label: {
                    Label("Medical History", systemImage: "heart.text.square.fill")
                }

                NavigationLink {
                    Text("SOAP Notes List - Coming Soon")
                } label: {
                    Label("SOAP Notes", systemImage: "doc.on.clipboard.fill")
                }
            }

            Section("Appointments") {
                Text("No appointments yet")
                    .foregroundStyle(.secondary)
            }

            Section("Billing") {
                NavigationLink {
                    Text("Client Invoices - Coming Soon")
                } label: {
                    Label("Invoices", systemImage: "dollarsign.circle.fill")
                }
            }
        }
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Labeled Row Component

struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ClientsView()
}

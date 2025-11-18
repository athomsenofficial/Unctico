// AddClientView.swift
// Form to add a new client
// QA Note: This is where you create a new client record

import SwiftUI

struct AddClientView: View {

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dateOfBirth = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                // Contact Information
                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                // Date of Birth
                Section("Date of Birth") {
                    DatePicker(
                        "Birth Date",
                        selection: $dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // Save Button
                Section {
                    Button(action: saveClient) {
                        HStack {
                            Spacer()
                            Text("Save Client")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Computed Properties

    /// Check if form is valid
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty
    }

    // MARK: - Methods

    /// Save new client
    private func saveClient() {
        // Validate email
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }

        // Create new client
        let client = Client(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            phone: phone.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth
        )

        // Save to data manager
        dataManager.addClient(client)

        // Dismiss view
        dismiss()
    }
}

// MARK: - Preview

struct AddClientView_Previews: PreviewProvider {
    static var previews: some View {
        AddClientView()
            .environmentObject(DataManager())
    }
}

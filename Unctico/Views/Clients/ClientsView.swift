import SwiftUI

struct ClientsView: View {
    @ObservedObject private var repository = ClientRepository.shared
    @State private var searchText = ""
    @State private var showingAddClient = false

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return repository.clients
        }
        return repository.searchClients(query: searchText)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding()

                if filteredClients.isEmpty {
                    EmptyStateView(message: searchText.isEmpty ? "No clients yet" : "No matching clients")
                } else {
                    List {
                        ForEach(filteredClients) { client in
                            NavigationLink(destination: ClientDetailView(client: client)) {
                                ClientRowView(client: client)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tranquilTeal)
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search clients...", text: $text)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ClientRowView: View {
    let client: Client

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [.calmingBlue, .tranquilTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(client.firstName.prefix(1) + client.lastName.prefix(1))
                        .font(.headline)
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.headline)

                if let email = client.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    private let repository = ClientRepository.shared

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func saveClient() {
        let newClient = Client(
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )
        repository.addClient(newClient)
        dismiss()
    }
}

struct ClientDetailView: View {
    let client: Client

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClientHeaderView(client: client)
                ContactInfoSection(client: client)
                PreferencesSection(preferences: client.preferences)
                MedicalHistorySection(medicalHistory: client.medicalHistory)
                QuickActionsSection(client: client)
            }
            .padding()
        }
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClientHeaderView: View {
    let client: Client

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [.calmingBlue, .tranquilTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay {
                    Text(client.firstName.prefix(1) + client.lastName.prefix(1))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }

            Text(client.fullName)
                .font(.title2)
                .fontWeight(.bold)

            if let dateOfBirth = client.dateOfBirth {
                Text("Age: \(calculateAge(from: dateOfBirth))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private func calculateAge(from dateOfBirth: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
}

struct ContactInfoSection: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)

            if let email = client.email {
                InfoRow(icon: "envelope.fill", text: email, color: .calmingBlue)
            }

            if let phone = client.phone {
                InfoRow(icon: "phone.fill", text: phone, color: .soothingGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
    }
}

struct PreferencesSection: View {
    let preferences: ClientPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)

            InfoRow(icon: "hand.raised.fill", text: "Pressure: \(preferences.pressureLevel.rawValue)", color: .tranquilTeal)
            InfoRow(icon: "thermometer", text: "Temperature: \(preferences.temperaturePreference.rawValue)", color: .softLavender)

            if let music = preferences.musicPreference {
                InfoRow(icon: "music.note", text: "Music: \(music)", color: .calmingBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct MedicalHistorySection: View {
    let medicalHistory: MedicalHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medical History")
                .font(.headline)

            if !medicalHistory.conditions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conditions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(medicalHistory.conditions, id: \.self) { condition in
                        Text("• \(condition)")
                            .font(.subheadline)
                    }
                }
            }

            if !medicalHistory.allergies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allergies")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    ForEach(medicalHistory.allergies, id: \.self) { allergy in
                        Text("⚠️ \(allergy)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct QuickActionsSection: View {
    let client: Client

    var body: some View {
        VStack(spacing: 12) {
            QuickActionButton(title: "Book Appointment", icon: "calendar.badge.plus", color: .calmingBlue) {
                // Book appointment
            }

            QuickActionButton(title: "View SOAP Notes", icon: "doc.text.fill", color: .soothingGreen) {
                // View SOAP notes
            }

            QuickActionButton(title: "Send Message", icon: "message.fill", color: .tranquilTeal) {
                // Send message
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

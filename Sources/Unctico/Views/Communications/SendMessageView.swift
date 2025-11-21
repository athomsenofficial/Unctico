import SwiftUI

/// Individual message composition and sending interface
struct SendMessageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var communicationService = CommunicationService.shared

    @State private var selectedClient: Client?
    @State private var showingClientPicker = false

    @State private var channel: CommunicationChannel = .email
    @State private var messageType: MessageType = .custom
    @State private var selectedTemplate: MessageTemplate?

    @State private var recipientContact = ""
    @State private var subject = ""
    @State private var body = ""

    @State private var scheduledDate: Date?
    @State private var enableScheduling = false

    @State private var isSending = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                // Recipient Section
                Section("Recipient") {
                    Button(action: { showingClientPicker = true }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.tranquilTeal)

                            if let client = selectedClient {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(client.name)
                                        .foregroundColor(.primary)
                                    Text(channel == .email ? (client.email ?? "No email") : (client.phone ?? "No phone"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Client")
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    // Or manual entry
                    TextField(channel == .email ? "Email Address" : "Phone Number", text: $recipientContact)
                        .textContentType(channel == .email ? .emailAddress : .telephoneNumber)
                        .keyboardType(channel == .email ? .emailAddress : .phonePad)
                        .autocapitalization(.none)
                        .disabled(selectedClient != nil)
                }

                // Channel Section
                Section("Channel") {
                    Picker("Channel", selection: $channel) {
                        ForEach([CommunicationChannel.email, .sms], id: \.self) { ch in
                            Label(ch.rawValue, systemImage: ch.icon)
                                .tag(ch)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: channel) { _, newChannel in
                        updateRecipientContact(for: newChannel)
                    }
                }

                // Message Type Section
                Section("Message Type") {
                    Picker("Type", selection: $messageType) {
                        ForEach(MessageType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Template Section
                Section("Template") {
                    if communicationService.templates.isEmpty {
                        Text("No templates available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Use Template", selection: $selectedTemplate) {
                            Text("None").tag(nil as MessageTemplate?)
                            ForEach(communicationService.templates.filter { $0.channel == channel }) { template in
                                Text(template.name).tag(template as MessageTemplate?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedTemplate) { _, template in
                            if let template = template {
                                applyTemplate(template)
                            }
                        }
                    }
                }

                // Message Content
                if channel == .email {
                    Section("Subject") {
                        TextField("Email Subject", text: $subject)
                    }
                }

                Section(channel == .email ? "Message Body" : "Message") {
                    TextEditor(text: $body)
                        .frame(minHeight: 150)

                    if channel == .sms {
                        HStack {
                            Spacer()
                            Text("\(body.count)/160 characters")
                                .font(.caption)
                                .foregroundColor(body.count > 160 ? .red : .secondary)
                        }
                    }
                }

                // Quick Variables
                if selectedClient != nil {
                    Section("Insert Variable") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                VariableChip(title: "{{clientName}}", action: { body += "{{clientName}}" })
                                VariableChip(title: "{{therapistName}}", action: { body += "{{therapistName}}" })
                                VariableChip(title: "{{practiceName}}", action: { body += "{{practiceName}}" })
                                VariableChip(title: "{{date}}", action: { body += "{{date}}" })
                            }
                        }
                    }
                }

                // Scheduling
                Section {
                    Toggle("Schedule for Later", isOn: $enableScheduling)

                    if enableScheduling {
                        DatePicker("Send Date", selection: Binding(
                            get: { scheduledDate ?? Date().addingTimeInterval(3600) },
                            set: { scheduledDate = $0 }
                        ), in: Date()...)
                    }
                } header: {
                    Text("Scheduling")
                } footer: {
                    if enableScheduling {
                        Text("Message will be sent automatically at the scheduled time")
                            .font(.caption)
                    }
                }

                // Send Button
                Section {
                    Button(action: sendMessage) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: enableScheduling ? "calendar.badge.plus" : "paperplane.fill")
                            }

                            Text(enableScheduling ? "Schedule Message" : "Send Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSend() ? Color.tranquilTeal : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSend() || isSending)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("New Message")
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
            .alert("Message Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(enableScheduling ? "Your message has been scheduled" : "Your message has been sent successfully")
            }
        }
    }

    // MARK: - Helper Methods

    private func updateRecipientContact(for channel: CommunicationChannel) {
        guard let client = selectedClient else { return }

        switch channel {
        case .email:
            recipientContact = client.email ?? ""
        case .sms:
            recipientContact = client.phone ?? ""
        default:
            recipientContact = ""
        }
    }

    private func applyTemplate(_ template: MessageTemplate) {
        subject = template.subject ?? ""
        body = template.content

        // Replace variables if client is selected
        if let client = selectedClient {
            let variables: [String: String] = [
                "clientName": client.name,
                "therapistName": "Dr. Smith", // TODO: Get from current user
                "practiceName": "Your Practice", // TODO: Get from settings
                "date": Date().formatted(date: .long, time: .omitted)
            ]

            body = communicationService.renderTemplate(template, variables: variables)
            if let subj = template.subject {
                var renderedSubject = subj
                for (key, value) in variables {
                    renderedSubject = renderedSubject.replacingOccurrences(of: "{{\(key)}}", with: value)
                }
                subject = renderedSubject
            }
        }
    }

    private func canSend() -> Bool {
        let hasRecipient = !recipientContact.isEmpty
        let hasBody = !body.isEmpty
        let hasSubject = channel != .email || !subject.isEmpty

        return hasRecipient && hasBody && hasSubject
    }

    private func sendMessage() {
        guard canSend() else { return }

        isSending = true
        errorMessage = nil

        Task {
            do {
                let message = CommunicationMessage(
                    clientId: selectedClient?.id ?? UUID(),
                    recipientName: selectedClient?.name,
                    recipientContact: recipientContact,
                    messageType: messageType,
                    channel: channel,
                    subject: channel == .email ? subject : nil,
                    body: body,
                    scheduledDate: enableScheduling ? (scheduledDate ?? Date()) : Date(),
                    status: enableScheduling ? .scheduled : .pending
                )

                let sent = try await communicationService.sendMessage(message)

                await MainActor.run {
                    isSending = false
                    showingSuccess = true

                    AuditLogger.shared.log(
                        event: .notificationSent,
                        details: "Message sent via \(channel.rawValue) to \(recipientContact)"
                    )
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Variable Chip

struct VariableChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.tranquilTeal.opacity(0.1))
                .foregroundColor(.tranquilTeal)
                .cornerRadius(8)
        }
    }
}

// MARK: - Client Picker

struct ClientPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedClient: Client?

    @State private var searchText = ""
    @State private var clients: [Client] = [] // TODO: Load from repository

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search clients...")

                if filteredClients.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Clients Found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredClients) { client in
                            Button(action: {
                                selectedClient = client
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.tranquilTeal)
                                        .font(.title2)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(client.name)
                                            .font(.headline)

                                        if let email = client.email {
                                            Label(email, systemImage: "envelope")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        if let phone = client.phone {
                                            Label(phone, systemImage: "phone")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedClient?.id == client.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.tranquilTeal)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadClients()
        }
    }

    private func loadClients() {
        // TODO: Load from ClientRepository
        // For now, create sample data
        clients = [
            Client(id: UUID(), name: "John Doe", email: "john@example.com", phone: "+1234567890"),
            Client(id: UUID(), name: "Jane Smith", email: "jane@example.com", phone: "+0987654321"),
            Client(id: UUID(), name: "Bob Johnson", email: "bob@example.com", phone: "+1122334455")
        ]
    }
}

// MARK: - Client Model (Temporary)

struct Client: Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
}

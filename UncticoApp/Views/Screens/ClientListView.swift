// ClientListView.swift
// List of all clients
// QA Note: Shows all clients with search functionality

import SwiftUI

struct ClientListView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var searchText = ""
    @State private var showingAddClient = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Search results or all clients
                ForEach(filteredClients) { client in
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        ClientRowView(client: client)
                    }
                }
                .onDelete(perform: deleteClients)
            }
            .searchable(text: $searchText, prompt: "Search clients...")
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView()
            }
            .overlay {
                // Empty state
                if dataManager.clients.isEmpty {
                    emptyState
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Filter clients based on search text
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return dataManager.clients.sorted { $0.lastName < $1.lastName }
        } else {
            return dataManager.searchClients(query: searchText)
        }
    }

    // MARK: - View Components

    /// Empty state when no clients
    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Clients Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to add your first client")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: { showingAddClient = true }) {
                Text("Add Client")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }

    // MARK: - Methods

    /// Delete clients
    private func deleteClients(at offsets: IndexSet) {
        for index in offsets {
            let client = filteredClients[index]
            dataManager.deleteClient(client)
        }
    }
}

// MARK: - Client Row View

struct ClientRowView: View {
    let client: Client

    var body: some View {
        HStack(spacing: 15) {
            // Initial circle
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(client.firstName.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

            // Client info
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.headline)

                Text(client.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let lastVisit = client.lastVisitDate {
                    Text("Last visit: \(lastVisit, formatter: DateFormatter.mediumDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Active status
            if client.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ClientListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientListView()
            .environmentObject(DataManager())
    }
}

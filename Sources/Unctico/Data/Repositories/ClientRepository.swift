import Foundation
import Combine

class ClientRepository: ObservableObject {
    static let shared = ClientRepository()

    @Published private(set) var clients: [Client] = []

    private let storage = LocalStorageManager.shared
    private let fileName = "clients"

    private init() {
        loadClients()
    }

    // MARK: - CRUD Operations

    func loadClients() {
        clients = storage.load(from: fileName)

        // If no clients exist, generate mock data for testing
        if clients.isEmpty {
            print("📦 No clients found, generating mock data...")
            clients = MockDataGenerator.shared.generateClients(count: 20)
            saveClients()
        }
    }

    func saveClients() {
        storage.save(clients, to: fileName)
    }

    func addClient(_ client: Client) {
        clients.append(client)
        saveClients()
    }

    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            saveClients()
        }
    }

    func deleteClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        saveClients()
    }

    func getClient(by id: UUID) -> Client? {
        return clients.first { $0.id == id }
    }

    func searchClients(query: String) -> [Client] {
        guard !query.isEmpty else { return clients }

        let lowercaseQuery = query.lowercased()
        return clients.filter { client in
            client.fullName.lowercased().contains(lowercaseQuery) ||
            (client.email?.lowercased().contains(lowercaseQuery) ?? false) ||
            (client.phone?.contains(query) ?? false)
        }
    }

    // MARK: - Test Helpers

    func resetWithMockData(count: Int = 20) {
        clients = MockDataGenerator.shared.generateClients(count: count)
        saveClients()
    }

    func clearAll() {
        clients = []
        storage.delete(fileName: fileName)
    }
}

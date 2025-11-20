import Foundation

/// Simple JSON-based local storage manager
class LocalStorageManager {
    static let shared = LocalStorageManager()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Generic Save/Load

    func save<T: Codable>(_ items: [T], to fileName: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")

        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Saved \(items.count) items to \(fileName)")
        } catch {
            print("❌ Error saving to \(fileName): \(error)")
        }
    }

    func load<T: Codable>(from fileName: String) -> [T] {
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("ℹ️ No file found at \(fileName), returning empty array")
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([T].self, from: data)
            print("✅ Loaded \(items.count) items from \(fileName)")
            return items
        } catch {
            print("❌ Error loading from \(fileName): \(error)")
            return []
        }
    }

    func delete(fileName: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")

        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ Deleted \(fileName)")
        } catch {
            print("❌ Error deleting \(fileName): \(error)")
        }
    }

    func clearAll() {
        let fileNames = ["clients", "appointments", "soapNotes", "transactions"]
        fileNames.forEach { delete(fileName: $0) }
    }
}

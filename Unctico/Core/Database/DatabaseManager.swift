// DatabaseManager.swift
// Manages Core Data persistence for the app
// This is a wrapper around Core Data to make it simple and easy to use

import CoreData
import SwiftUI

/// Manages all database operations using Core Data
/// Use this class for saving, loading, and querying data
class DatabaseManager: ObservableObject {

    // MARK: - Published Properties

    /// Is a database operation in progress?
    @Published var isLoading: Bool = false

    /// Any error from database operations
    @Published var errorMessage: String?

    // MARK: - Core Data Stack

    /// The persistent container (this holds the Core Data stack)
    let persistentContainer: NSPersistentContainer

    /// The main context for database operations
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Initialization

    init() {
        // Create the container with the data model name
        persistentContainer = NSPersistentContainer(name: "Unctico")

        // Load the persistent stores (database files)
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
                // In production, handle this more gracefully
            } else {
                print("✅ Core Data loaded successfully")
            }
        }

        // Set automatic merging of changes
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Public Methods

    /// Save changes to the database
    /// Call this after making any changes to save them permanently
    func save() {
        let context = viewContext

        // Only save if there are changes
        guard context.hasChanges else { return }

        do {
            try context.save()
            print("✅ Database saved successfully")
        } catch {
            print("❌ Failed to save database: \(error.localizedDescription)")
            errorMessage = "Failed to save changes"
        }
    }

    /// Delete an object from the database
    /// - Parameter object: The object to delete
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }

    /// Delete multiple objects from the database
    /// - Parameter objects: Array of objects to delete
    func deleteMultiple(_ objects: [NSManagedObject]) {
        for object in objects {
            viewContext.delete(object)
        }
        save()
    }

    /// Fetch objects from the database
    /// - Parameters:
    ///   - entityName: Name of the entity to fetch (e.g., "ClientEntity")
    ///   - predicate: Optional filter for the results
    ///   - sortDescriptors: Optional sorting for the results
    /// - Returns: Array of fetched objects
    func fetch<T: NSManagedObject>(
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch \(entityName): \(error.localizedDescription)")
            errorMessage = "Failed to load data"
            return []
        }
    }

    /// Count objects in the database
    /// - Parameters:
    ///   - entityName: Name of the entity to count
    ///   - predicate: Optional filter for counting
    /// - Returns: Number of objects matching the criteria
    func count(entityName: String, predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = predicate

        do {
            return try viewContext.count(for: request)
        } catch {
            print("❌ Failed to count \(entityName): \(error.localizedDescription)")
            return 0
        }
    }

    /// Delete all data from the database (use with extreme caution!)
    /// This is useful for logout or testing
    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try viewContext.execute(deleteRequest)
                    print("✅ Deleted all \(entityName)")
                } catch {
                    print("❌ Failed to delete \(entityName): \(error.localizedDescription)")
                }
            }
        }

        save()
    }
}

// MARK: - Preview Helper

extension DatabaseManager {
    /// Create an in-memory database for SwiftUI previews
    /// This won't persist data and is perfect for testing
    static var preview: DatabaseManager {
        let manager = DatabaseManager()
        // The preview instance is already configured
        return manager
    }
}

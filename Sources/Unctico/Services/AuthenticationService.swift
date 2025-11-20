import Combine
import Foundation
import CryptoKit

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published var currentUser: User?
    private let storage = LocalStorageManager.shared

    private init() {}

    // MARK: - Authentication

    func signIn(email: String, password: String) -> Bool {
        let users: [User] = storage.load(from: "users")
        let passwordHash = hashPassword(password)

        if let user = users.first(where: { $0.email.lowercased() == email.lowercased() && $0.passwordHash == passwordHash }) {
            var updatedUser = user
            updatedUser.lastLoginAt = Date()
            updateUser(updatedUser)
            currentUser = updatedUser
            return true
        }

        return false
    }

    func signOut() {
        currentUser = nil
    }

    func createAccount(email: String, password: String, firstName: String = "", lastName: String = "", practiceName: String = "") -> Bool {
        var users: [User] = storage.load(from: "users")

        // Check if email already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            print("❌ Account with email \(email) already exists")
            return false
        }

        let passwordHash = hashPassword(password)
        let newUser = User(
            email: email,
            passwordHash: passwordHash,
            firstName: firstName,
            lastName: lastName,
            practiceName: practiceName
        )

        users.append(newUser)
        storage.save(users, to: "users")

        print("✅ Created account for \(email)")
        return true
    }

    func updateUser(_ user: User) {
        var users: [User] = storage.load(from: "users")

        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            storage.save(users, to: "users")
        }
    }

    func deleteAccount(userId: UUID) {
        var users: [User] = storage.load(from: "users")
        users.removeAll { $0.id == userId }
        storage.save(users, to: "users")
    }

    func getAllUsers() -> [User] {
        return storage.load(from: "users")
    }

    // MARK: - Password Hashing

    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

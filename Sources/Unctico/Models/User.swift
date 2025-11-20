import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let passwordHash: String
    let firstName: String
    let lastName: String
    let practiceName: String
    let createdAt: Date
    var lastLoginAt: Date?

    init(
        id: UUID = UUID(),
        email: String,
        passwordHash: String,
        firstName: String = "",
        lastName: String = "",
        practiceName: String = "",
        createdAt: Date = Date(),
        lastLoginAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.firstName = firstName
        self.lastName = lastName
        self.practiceName = practiceName
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

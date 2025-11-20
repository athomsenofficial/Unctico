import Foundation

/// Initial setup to create default user account
class InitialSetup {
    static func createDefaultAccount() {
        let authService = AuthenticationService.shared

        // Create account for andrew.t247@gmail.com with password "1"
        let success = authService.createAccount(
            email: "andrew.t247@gmail.com",
            password: "1",
            firstName: "Andrew",
            lastName: "T",
            practiceName: "Unctico Practice"
        )

        if success {
            print("✅ Default account created successfully")
            print("📧 Email: andrew.t247@gmail.com")
            print("🔑 Password: 1")
        } else {
            print("ℹ️ Default account already exists")
        }
    }
}

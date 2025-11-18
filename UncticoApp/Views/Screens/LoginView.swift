// LoginView.swift
// Login screen with Face ID/Touch ID support
// QA Note: This is the first screen users see

import SwiftUI
import LocalAuthentication

struct LoginView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var authManager: AuthManager

    // MARK: - State

    @State private var passcode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // App logo and title
                VStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)

                    Text("Unctico")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Massage Therapy Management")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Authentication section
                VStack(spacing: 20) {
                    // Biometric authentication button
                    if canUseBiometrics() {
                        Button(action: authenticateWithBiometrics) {
                            HStack {
                                Image(systemName: biometricIcon())
                                    .font(.title2)
                                Text("Sign In with \(biometricType())")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLocked || isAuthenticating)

                        Text("or")
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Passcode entry
                    VStack(spacing: 15) {
                        SecureField("Enter Passcode", text: $passcode)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .disabled(authManager.isLocked || isAuthenticating)

                        Button(action: authenticateWithPasscode) {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .disabled(passcode.isEmpty || authManager.isLocked || isAuthenticating)
                    }

                    // Lockout message
                    if authManager.isLocked, let lockoutEnd = authManager.lockoutEndTime {
                        let remaining = Int(lockoutEnd.timeIntervalSinceNow)
                        Text("Account locked. Try again in \(remaining) seconds.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                    }

                    // Failed attempts warning
                    if authManager.failedAttempts > 0 && !authManager.isLocked {
                        let attemptsLeft = AppConfig.maxLoginAttempts - authManager.failedAttempts
                        Text("\(attemptsLeft) attempts remaining")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Try biometric authentication automatically on appear
            if canUseBiometrics() && !authManager.hasPasscode() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
    }

    // MARK: - Methods

    /// Authenticate using biometrics
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        authManager.authenticateWithBiometrics { success, error in
            isAuthenticating = false
            if !success, let error = error {
                errorMessage = error
                showError = true
            }
        }
    }

    /// Authenticate using passcode
    private func authenticateWithPasscode() {
        isAuthenticating = true
        authManager.authenticateWithPasscode(passcode) { success, error in
            isAuthenticating = false
            if !success, let error = error {
                errorMessage = error
                showError = true
                passcode = ""
            }
        }
    }

    /// Check if biometrics can be used
    private func canUseBiometrics() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Get biometric type (Face ID or Touch ID)
    private func biometricType() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometrics"
        }
    }

    /// Get icon for biometric type
    private func biometricIcon() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}

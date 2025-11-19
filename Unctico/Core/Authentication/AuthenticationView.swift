// AuthenticationView.swift
// Login and registration screen

import SwiftUI

/// The authentication screen (login/register)
struct AuthenticationView: View {

    // MARK: - Environment

    @EnvironmentObject var authManager: AuthenticationManager

    // MARK: - State

    /// Is the user on the login tab or register tab?
    @State private var isLoginMode = true

    /// Email input field
    @State private var email = ""

    /// Password input field
    @State private var password = ""

    /// Full name input field (for registration)
    @State private var fullName = ""

    /// Show/hide password
    @State private var showPassword = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with logo
                headerSection

                // Tab selector (Login / Register)
                tabSelector

                // Input fields
                inputFields

                // Error message
                if let error = authManager.errorMessage {
                    errorView(error)
                }

                // Action button
                actionButton

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - View Components

    /// Header section with app logo and tagline
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo placeholder
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .padding(.top, 60)

            Text("Unctico")
                .font(.system(size: 40, weight: .bold))

            Text("Massage Therapy Practice Management")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }

    /// Tab selector for Login/Register
    private var tabSelector: some View {
        HStack(spacing: 0) {
            // Login tab
            Button {
                isLoginMode = true
            } label: {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isLoginMode ? Color.blue : Color.clear)
                    .foregroundStyle(isLoginMode ? .white : .primary)
            }

            // Register tab
            Button {
                isLoginMode = false
            } label: {
                Text("Register")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(!isLoginMode ? Color.blue : Color.clear)
                    .foregroundStyle(!isLoginMode ? .white : .primary)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    /// Input fields section
    private var inputFields: some View {
        VStack(spacing: 16) {
            // Full name field (only for registration)
            if !isLoginMode {
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }

            // Email field
            TextField("Email", text: $email)
                .textFieldStyle(RoundedTextFieldStyle())
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)

            // Password field
            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        .textContentType(isLoginMode ? .password : .newPassword)
                } else {
                    SecureField("Password", text: $password)
                        .textContentType(isLoginMode ? .password : .newPassword)
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
        }
    }

    /// Action button (Login or Register)
    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            if authManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                Text(isLoginMode ? "Login" : "Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .background(Color.blue)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .disabled(authManager.isLoading)
    }

    /// Error message view
    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    // MARK: - Actions

    /// Handle login or registration
    private func handleAction() {
        Task {
            if isLoginMode {
                await authManager.login(email: email, password: password)
            } else {
                await authManager.register(email: email, password: password, fullName: fullName)
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}

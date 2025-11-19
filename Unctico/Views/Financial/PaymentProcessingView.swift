import SwiftUI

struct PaymentProcessingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var paymentService = PaymentService.shared

    let client: Client
    let amount: Double
    let appointmentId: UUID?

    @State private var selectedMethod: PaymentMethod = .cash
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Display
                    VStack(spacing: 8) {
                        Text("Payment Amount")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(amount, format: .currency(code: "USD"))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.tranquilTeal)

                        Text("for \(client.fullName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.tranquilTeal.opacity(0.1))
                    .cornerRadius(16)

                    // Payment Method Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    PaymentMethodButton(
                                        method: method,
                                        isSelected: selectedMethod == method
                                    ) {
                                        selectedMethod = method
                                    }
                                }
                            }
                        }
                    }

                    // Card Details (if card payment selected)
                    if selectedMethod == .creditCard || selectedMethod == .debitCard {
                        VStack(spacing: 16) {
                            TextField("Card Number", text: $cardNumber)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedTextFieldStyle())

                            HStack(spacing: 12) {
                                TextField("MM", text: $expiryMonth)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .frame(width: 60)

                                TextField("YYYY", text: $expiryYear)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .frame(width: 80)

                                Spacer()

                                TextField("CVV", text: $cvv)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }

                    // Process Payment Button
                    Button(action: processPayment) {
                        if paymentService.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Process Payment")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(paymentService.isProcessing)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Process Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Payment Successful!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Payment of \(amount, format: .currency(code: "USD")) has been processed successfully.")
            }
            .alert("Payment Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func processPayment() {
        if selectedMethod == .creditCard || selectedMethod == .debitCard {
            guard let month = Int(expiryMonth), let year = Int(expiryYear) else {
                errorMessage = "Invalid expiry date"
                showError = true
                return
            }

            paymentService.processCardPayment(
                cardNumber: cardNumber,
                expiryMonth: month,
                expiryYear: year,
                cvv: cvv,
                amount: amount,
                clientId: client.id
            ) { result in
                handlePaymentResult(result)
            }
        } else {
            paymentService.processPayment(
                amount: amount,
                method: selectedMethod,
                clientId: client.id,
                appointmentId: appointmentId
            ) { result in
                handlePaymentResult(result)
            }
        }
    }

    private func handlePaymentResult(_ result: Result<Payment, PaymentError>) {
        switch result {
        case .success:
            showSuccess = true
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct PaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: methodIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .tranquilTeal)

                Text(method.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding()
            .frame(width: 100)
            .background(isSelected ? Color.tranquilTeal : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tranquilTeal, lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.03), radius: 5)
        }
        .buttonStyle(.plain)
    }

    private var methodIcon: String {
        switch method {
        case .cash: return "dollarsign.circle.fill"
        case .creditCard, .debitCard: return "creditcard.fill"
        case .check: return "doc.text.fill"
        case .venmo: return "v.circle.fill"
        case .zelle: return "z.circle.fill"
        case .applePay: return "applelogo"
        case .insurance: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

import Foundation

class PaymentService: ObservableObject {
    static let shared = PaymentService()

    @Published var isProcessing: Bool = false
    @Published var lastError: PaymentError?

    private init() {}

    // MARK: - Payment Processing

    func processPayment(
        amount: Double,
        method: PaymentMethod,
        clientId: UUID,
        appointmentId: UUID?,
        completion: @escaping (Result<Payment, PaymentError>) -> Void
    ) {
        isProcessing = true

        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }

            // Simulate 95% success rate
            let isSuccess = Double.random(in: 0...1) < 0.95

            if isSuccess {
                let payment = Payment(
                    clientId: clientId,
                    appointmentId: appointmentId,
                    amount: amount,
                    method: method,
                    status: .completed
                )

                // Record transaction
                let transaction = Transaction(
                    description: "Payment - \(method.rawValue)",
                    amount: amount,
                    type: .income,
                    category: "Service Revenue"
                )
                TransactionRepository.shared.addTransaction(transaction)

                self.isProcessing = false
                completion(.success(payment))
            } else {
                self.lastError = .processingFailed
                self.isProcessing = false
                completion(.failure(.processingFailed))
            }
        }
    }

    // MARK: - Refunds

    func processRefund(
        payment: Payment,
        amount: Double,
        reason: String,
        completion: @escaping (Result<Payment, PaymentError>) -> Void
    ) {
        guard amount <= payment.netAmount else {
            completion(.failure(.invalidAmount))
            return
        }

        isProcessing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            var updatedPayment = payment
            let previousRefund = updatedPayment.refundedAmount ?? 0
            updatedPayment.refundedAmount = previousRefund + amount

            if updatedPayment.netAmount == 0 {
                updatedPayment.status = .refunded
            } else {
                updatedPayment.status = .partiallyRefunded
            }

            // Record refund transaction
            let transaction = Transaction(
                description: "Refund - \(reason)",
                amount: amount,
                type: .expense,
                category: "Refunds"
            )
            TransactionRepository.shared.addTransaction(transaction)

            self.isProcessing = false
            completion(.success(updatedPayment))
        }
    }

    // MARK: - Card Processing (Placeholder for Stripe/Square)

    func processCardPayment(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvv: String,
        amount: Double,
        clientId: UUID,
        completion: @escaping (Result<Payment, PaymentError>) -> Void
    ) {
        // Validate card details
        guard validateCardNumber(cardNumber) else {
            completion(.failure(.invalidCardNumber))
            return
        }

        guard validateExpiry(month: expiryMonth, year: expiryYear) else {
            completion(.failure(.cardExpired))
            return
        }

        guard validateCVV(cvv) else {
            completion(.failure(.invalidCVV))
            return
        }

        // Process payment
        processPayment(
            amount: amount,
            method: .creditCard,
            clientId: clientId,
            appointmentId: nil,
            completion: completion
        )
    }

    // MARK: - Validation

    private func validateCardNumber(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count >= 13 && cleaned.count <= 19 else { return false }

        // Luhn algorithm
        var sum = 0
        var isSecond = false

        for char in cleaned.reversed() {
            guard let digit = Int(String(char)) else { return false }

            var digitToAdd = digit
            if isSecond {
                digitToAdd *= 2
                if digitToAdd > 9 {
                    digitToAdd -= 9
                }
            }

            sum += digitToAdd
            isSecond.toggle()
        }

        return sum % 10 == 0
    }

    private func validateExpiry(month: Int, year: Int) -> Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())

        if year < currentYear {
            return false
        } else if year == currentYear && month < currentMonth {
            return false
        }

        return month >= 1 && month <= 12
    }

    private func validateCVV(_ cvv: String) -> Bool {
        return cvv.count >= 3 && cvv.count <= 4 && cvv.allSatisfy { $0.isNumber }
    }

    // MARK: - Invoice Generation

    func generateInvoice(
        for clientId: UUID,
        appointments: [Appointment],
        taxRate: Double = 0.0,
        discount: Double = 0.0
    ) -> Invoice {
        var lineItems: [InvoiceLineItem] = []
        var subtotal: Double = 0

        // Create line items from appointments
        for appointment in appointments {
            let price = getServicePrice(for: appointment.serviceType)
            let item = InvoiceLineItem(
                description: appointment.serviceType.rawValue,
                quantity: 1,
                unitPrice: price
            )
            lineItems.append(item)
            subtotal += price
        }

        return Invoice(
            clientId: clientId,
            appointmentIds: appointments.map { $0.id },
            subtotal: subtotal,
            taxRate: taxRate,
            discount: discount,
            lineItems: lineItems
        )
    }

    func getServicePrice(for serviceType: ServiceType) -> Double {
        switch serviceType {
        case .swedish: return 80.00
        case .deepTissue: return 100.00
        case .sports: return 95.00
        case .prenatal: return 90.00
        case .hotStone: return 120.00
        case .aromatherapy: return 110.00
        case .therapeutic: return 95.00
        case .medical: return 75.00
        }
    }
}

// MARK: - Payment Errors

enum PaymentError: Error {
    case invalidAmount
    case invalidCardNumber
    case cardExpired
    case invalidCVV
    case processingFailed
    case networkError
    case insufficientFunds
    case cancelled

    var localizedDescription: String {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidCardNumber:
            return "Invalid card number"
        case .cardExpired:
            return "Card has expired"
        case .invalidCVV:
            return "Invalid CVV/CVC code"
        case .processingFailed:
            return "Payment processing failed"
        case .networkError:
            return "Network connection error"
        case .insufficientFunds:
            return "Insufficient funds"
        case .cancelled:
            return "Payment cancelled"
        }
    }
}

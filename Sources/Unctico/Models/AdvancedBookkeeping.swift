import Foundation

/// Advanced bookkeeping models for bank integration and automated accounting
/// TODO: Integrate with Plaid for bank feeds
/// TODO: Integrate OCR service for receipt scanning (AWS Textract, Google Vision, or Veryfi)

// MARK: - Bank Account

struct BankAccount: Identifiable, Codable {
    let id: UUID
    var accountName: String
    var bankName: String
    var accountType: BankAccountType
    var accountNumber: String // Last 4 digits only
    var routingNumber: String?
    var currentBalance: Double
    var availableBalance: Double
    var currency: String
    var isActive: Bool
    var plaidAccountId: String? // Plaid account identifier
    var plaidAccessToken: String? // Encrypted access token
    var lastSyncDate: Date?
    var createdDate: Date

    init(
        id: UUID = UUID(),
        accountName: String,
        bankName: String,
        accountType: BankAccountType,
        accountNumber: String,
        routingNumber: String? = nil,
        currentBalance: Double = 0,
        availableBalance: Double = 0,
        currency: String = "USD",
        isActive: Bool = true,
        plaidAccountId: String? = nil,
        plaidAccessToken: String? = nil,
        lastSyncDate: Date? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.accountName = accountName
        self.bankName = bankName
        self.accountType = accountType
        self.accountNumber = accountNumber
        self.routingNumber = routingNumber
        self.currentBalance = currentBalance
        self.availableBalance = availableBalance
        self.currency = currency
        self.isActive = isActive
        self.plaidAccountId = plaidAccountId
        self.plaidAccessToken = plaidAccessToken
        self.lastSyncDate = lastSyncDate
        self.createdDate = createdDate
    }

    var needsSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return lastSync < oneDayAgo
    }
}

enum BankAccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case lineOfCredit = "Line of Credit"

    var icon: String {
        switch self {
        case .checking: return "dollarsign.circle.fill"
        case .savings: return "banknote.fill"
        case .creditCard: return "creditcard.fill"
        case .lineOfCredit: return "rectangle.and.pencil.and.ellipsis"
        }
    }
}

// MARK: - Bank Transaction

struct BankTransaction: Identifiable, Codable {
    let id: UUID
    let bankAccountId: UUID
    var date: Date
    var description: String
    var amount: Double // Negative for debits, positive for credits
    var category: TransactionCategory?
    var merchant: String?
    var transactionType: BankTransactionType
    var status: TransactionStatus
    var plaidTransactionId: String? // Plaid transaction identifier
    var isReconciled: Bool
    var reconciledDate: Date?
    var linkedExpenseId: UUID? // Link to existing Expense record
    var linkedIncomeId: UUID? // Link to revenue transaction
    var notes: String

    init(
        id: UUID = UUID(),
        bankAccountId: UUID,
        date: Date,
        description: String,
        amount: Double,
        category: TransactionCategory? = nil,
        merchant: String? = nil,
        transactionType: BankTransactionType,
        status: TransactionStatus = .pending,
        plaidTransactionId: String? = nil,
        isReconciled: Bool = false,
        reconciledDate: Date? = nil,
        linkedExpenseId: UUID? = nil,
        linkedIncomeId: UUID? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.bankAccountId = bankAccountId
        self.date = date
        self.description = description
        self.amount = amount
        self.category = category
        self.merchant = merchant
        self.transactionType = transactionType
        self.status = status
        self.plaidTransactionId = plaidTransactionId
        self.isReconciled = isReconciled
        self.reconciledDate = reconciledDate
        self.linkedExpenseId = linkedExpenseId
        self.linkedIncomeId = linkedIncomeId
        self.notes = notes
    }

    var isDebit: Bool {
        amount < 0
    }

    var isCredit: Bool {
        amount > 0
    }

    var needsCategorization: Bool {
        category == nil && status == .posted
    }
}

enum BankTransactionType: String, Codable {
    case debit = "Debit"
    case credit = "Credit"
    case transfer = "Transfer"
    case fee = "Fee"
    case interest = "Interest"
    case dividend = "Dividend"
    case atmWithdrawal = "ATM Withdrawal"
    case check = "Check"
    case deposit = "Deposit"
    case payment = "Payment"
    case refund = "Refund"
}

enum TransactionStatus: String, Codable {
    case pending = "Pending"
    case posted = "Posted"
    case cleared = "Cleared"
    case voided = "Voided"
}

// MARK: - Transaction Category

enum TransactionCategory: String, Codable, CaseIterable {
    // Income
    case serviceRevenue = "Service Revenue"
    case productSales = "Product Sales"
    case giftCardSales = "Gift Card Sales"
    case otherIncome = "Other Income"

    // Operating Expenses
    case rent = "Rent"
    case utilities = "Utilities"
    case insurance = "Insurance"
    case supplies = "Supplies & Inventory"
    case equipmentPurchase = "Equipment Purchase"
    case equipmentMaintenance = "Equipment Maintenance"
    case laundryLinens = "Laundry & Linens"

    // Marketing & Advertising
    case marketing = "Marketing & Advertising"
    case websiteHosting = "Website & Hosting"
    case softwareSubscriptions = "Software Subscriptions"

    // Professional Services
    case accountingFees = "Accounting Fees"
    case legalFees = "Legal Fees"
    case consultingFees = "Consulting Fees"

    // Staff & Payroll
    case salaries = "Salaries & Wages"
    case payrollTaxes = "Payroll Taxes"
    case employeeBenefits = "Employee Benefits"
    case contractorPayments = "Contractor Payments"

    // Education & Training
    case continuingEducation = "Continuing Education"
    case certifications = "Certifications & Licenses"
    case conferences = "Conferences & Events"

    // Other
    case bankFees = "Bank Fees"
    case creditCardFees = "Credit Card Fees"
    case taxes = "Taxes"
    case meals = "Meals & Entertainment"
    case travel = "Travel"
    case office = "Office Expenses"
    case other = "Other"

    var isIncome: Bool {
        switch self {
        case .serviceRevenue, .productSales, .giftCardSales, .otherIncome:
            return true
        default:
            return false
        }
    }

    var isExpense: Bool {
        !isIncome
    }

    var taxDeductible: Bool {
        switch self {
        case .serviceRevenue, .productSales, .giftCardSales, .otherIncome:
            return false
        default:
            return true // Most business expenses are deductible
        }
    }
}

// MARK: - Receipt

struct Receipt: Identifiable, Codable {
    let id: UUID
    var receiptNumber: String?
    var vendor: String
    var date: Date
    var totalAmount: Double
    var taxAmount: Double?
    var category: TransactionCategory?
    var paymentMethod: String?
    var imageUrl: String? // Local file path or cloud storage URL
    var ocrText: String? // Extracted text from OCR
    var ocrConfidence: Double? // OCR accuracy (0-100)
    var status: ReceiptStatus
    var linkedTransactionId: UUID? // Link to bank transaction
    var linkedExpenseId: UUID? // Link to expense record
    var notes: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        receiptNumber: String? = nil,
        vendor: String,
        date: Date,
        totalAmount: Double,
        taxAmount: Double? = nil,
        category: TransactionCategory? = nil,
        paymentMethod: String? = nil,
        imageUrl: String? = nil,
        ocrText: String? = nil,
        ocrConfidence: Double? = nil,
        status: ReceiptStatus = .unprocessed,
        linkedTransactionId: UUID? = nil,
        linkedExpenseId: UUID? = nil,
        notes: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.receiptNumber = receiptNumber
        self.vendor = vendor
        self.date = date
        self.totalAmount = totalAmount
        self.taxAmount = taxAmount
        self.category = category
        self.paymentMethod = paymentMethod
        self.imageUrl = imageUrl
        self.ocrText = ocrText
        self.ocrConfidence = ocrConfidence
        self.status = status
        self.linkedTransactionId = linkedTransactionId
        self.linkedExpenseId = linkedExpenseId
        self.notes = notes
        self.createdDate = createdDate
    }

    var needsReview: Bool {
        status == .needsReview || ocrConfidence ?? 0 < 80
    }

    var isProcessed: Bool {
        status == .processed && linkedExpenseId != nil
    }
}

enum ReceiptStatus: String, Codable {
    case unprocessed = "Unprocessed"
    case processing = "Processing OCR"
    case needsReview = "Needs Review"
    case processed = "Processed"
    case rejected = "Rejected"
}

// MARK: - Bank Reconciliation

struct BankReconciliation: Identifiable, Codable {
    let id: UUID
    let bankAccountId: UUID
    var periodStart: Date
    var periodEnd: Date
    var statementBalance: Double
    var bookBalance: Double
    var difference: Double
    var reconciledTransactions: [UUID] // Transaction IDs
    var unreconciledTransactions: [UUID]
    var adjustments: [ReconciliationAdjustment]
    var status: ReconciliationStatus
    var completedDate: Date?
    var completedBy: UUID? // Staff member
    var notes: String

    init(
        id: UUID = UUID(),
        bankAccountId: UUID,
        periodStart: Date,
        periodEnd: Date,
        statementBalance: Double,
        bookBalance: Double = 0,
        reconciledTransactions: [UUID] = [],
        unreconciledTransactions: [UUID] = [],
        adjustments: [ReconciliationAdjustment] = [],
        status: ReconciliationStatus = .inProgress,
        completedDate: Date? = nil,
        completedBy: UUID? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.bankAccountId = bankAccountId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.statementBalance = statementBalance
        self.bookBalance = bookBalance
        self.difference = statementBalance - bookBalance
        self.reconciledTransactions = reconciledTransactions
        self.unreconciledTransactions = unreconciledTransactions
        self.adjustments = adjustments
        self.status = status
        self.completedDate = completedDate
        self.completedBy = completedBy
        self.notes = notes
    }

    var isBalanced: Bool {
        abs(difference) < 0.01 // Within 1 cent
    }
}

enum ReconciliationStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case balanced = "Balanced"
    case unbalanced = "Unbalanced"
    case completed = "Completed"
}

struct ReconciliationAdjustment: Identifiable, Codable {
    let id: UUID
    var description: String
    var amount: Double
    var adjustmentType: AdjustmentType
    var notes: String

    init(
        id: UUID = UUID(),
        description: String,
        amount: Double,
        adjustmentType: AdjustmentType,
        notes: String = ""
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.adjustmentType = adjustmentType
        self.notes = notes
    }
}

enum AdjustmentType: String, Codable {
    case bankError = "Bank Error"
    case bookkeepingError = "Bookkeeping Error"
    case missingTransaction = "Missing Transaction"
    case duplicateTransaction = "Duplicate Transaction"
    case fee = "Bank Fee"
    case interest = "Interest"
    case other = "Other"
}

// MARK: - Chart of Accounts

struct AccountingAccount: Identifiable, Codable {
    let id: UUID
    var accountNumber: String
    var accountName: String
    var accountType: AccountingAccountType
    var parentAccountId: UUID?
    var balance: Double
    var isActive: Bool
    var description: String

    init(
        id: UUID = UUID(),
        accountNumber: String,
        accountName: String,
        accountType: AccountingAccountType,
        parentAccountId: UUID? = nil,
        balance: Double = 0,
        isActive: Bool = true,
        description: String = ""
    ) {
        self.id = id
        self.accountNumber = accountNumber
        self.accountName = accountName
        self.accountType = accountType
        self.parentAccountId = parentAccountId
        self.balance = balance
        self.isActive = isActive
        self.description = description
    }
}

enum AccountingAccountType: String, Codable, CaseIterable {
    case asset = "Asset"
    case liability = "Liability"
    case equity = "Equity"
    case revenue = "Revenue"
    case expense = "Expense"

    var normalBalance: BalanceType {
        switch self {
        case .asset, .expense:
            return .debit
        case .liability, .equity, .revenue:
            return .credit
        }
    }
}

enum BalanceType {
    case debit
    case credit
}

// MARK: - Journal Entry

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var entryNumber: String
    var date: Date
    var description: String
    var lineItems: [JournalLineItem]
    var isBalanced: Bool
    var createdBy: UUID?
    var createdDate: Date
    var notes: String

    init(
        id: UUID = UUID(),
        entryNumber: String,
        date: Date,
        description: String,
        lineItems: [JournalLineItem] = [],
        createdBy: UUID? = nil,
        createdDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.entryNumber = entryNumber
        self.date = date
        self.description = description
        self.lineItems = lineItems
        self.isBalanced = Self.checkBalance(lineItems)
        self.createdBy = createdBy
        self.createdDate = createdDate
        self.notes = notes
    }

    private static func checkBalance(_ items: [JournalLineItem]) -> Bool {
        let totalDebits = items.filter { $0.entryType == .debit }.reduce(0) { $0 + $1.amount }
        let totalCredits = items.filter { $0.entryType == .credit }.reduce(0) { $0 + $1.amount }
        return abs(totalDebits - totalCredits) < 0.01
    }
}

struct JournalLineItem: Identifiable, Codable {
    let id: UUID
    let accountId: UUID
    var accountName: String
    var entryType: JournalEntryType
    var amount: Double
    var description: String

    init(
        id: UUID = UUID(),
        accountId: UUID,
        accountName: String,
        entryType: JournalEntryType,
        amount: Double,
        description: String = ""
    ) {
        self.id = id
        self.accountId = accountId
        self.accountName = accountName
        self.entryType = entryType
        self.amount = amount
        self.description = description
    }
}

enum JournalEntryType: String, Codable {
    case debit = "Debit"
    case credit = "Credit"
}

// MARK: - Financial Statement

struct FinancialStatement {
    let statementType: StatementType
    let periodStart: Date
    let periodEnd: Date
    let generatedDate: Date
    let accounts: [AccountingAccount]
    let transactions: [BankTransaction]
}

enum StatementType: String, CaseIterable {
    case balanceSheet = "Balance Sheet"
    case incomeStatement = "Income Statement"
    case cashFlow = "Cash Flow Statement"
    case trialBalance = "Trial Balance"
}

// MARK: - Bank Feed Sync Status

struct BankFeedSync: Identifiable, Codable {
    let id: UUID
    let bankAccountId: UUID
    var lastSyncDate: Date
    var syncStatus: SyncStatus
    var transactionsImported: Int
    var errors: [String]

    init(
        id: UUID = UUID(),
        bankAccountId: UUID,
        lastSyncDate: Date = Date(),
        syncStatus: SyncStatus,
        transactionsImported: Int = 0,
        errors: [String] = []
    ) {
        self.id = id
        self.bankAccountId = bankAccountId
        self.lastSyncDate = lastSyncDate
        self.syncStatus = syncStatus
        self.transactionsImported = transactionsImported
        self.errors = errors
    }
}

enum SyncStatus: String, Codable {
    case success = "Success"
    case failed = "Failed"
    case inProgress = "In Progress"
    case needsReauth = "Needs Reauthorization"
}

// MARK: - Statistics

struct BookkeepingStatistics {
    let totalBankAccounts: Int
    let totalBalance: Double
    let uncategorizedTransactions: Int
    let unreconciledTransactions: Int
    let unprocessedReceipts: Int
    let lastSyncDate: Date?
    let monthlyRevenue: Double
    let monthlyExpenses: Double
    let profitMargin: Double

    init(
        totalBankAccounts: Int = 0,
        totalBalance: Double = 0,
        uncategorizedTransactions: Int = 0,
        unreconciledTransactions: Int = 0,
        unprocessedReceipts: Int = 0,
        lastSyncDate: Date? = nil,
        monthlyRevenue: Double = 0,
        monthlyExpenses: Double = 0,
        profitMargin: Double = 0
    ) {
        self.totalBankAccounts = totalBankAccounts
        self.totalBalance = totalBalance
        self.uncategorizedTransactions = uncategorizedTransactions
        self.unreconciledTransactions = unreconciledTransactions
        self.unprocessedReceipts = unprocessedReceipts
        self.lastSyncDate = lastSyncDate
        self.monthlyRevenue = monthlyRevenue
        self.monthlyExpenses = monthlyExpenses
        self.profitMargin = profitMargin
    }
}

/*
 INTEGRATION REQUIREMENTS:

 1. Plaid Bank Feed Integration:
    - Sign up for Plaid API (https://plaid.com)
    - Implement Plaid Link for bank connection
    - Use Plaid Transactions API to fetch transactions
    - Store encrypted access tokens securely
    - Handle token refresh and reauthorization
    - Endpoints needed:
      - /link/token/create (Initialize Link)
      - /item/public_token/exchange (Get access token)
      - /transactions/sync (Fetch transactions)
      - /accounts/balance/get (Get balances)

 2. OCR Receipt Scanning Options:
    a) AWS Textract
       - AWS SDK for iOS
       - DetectDocumentText API
       - AnalyzeExpense API (structured data extraction)

    b) Google Cloud Vision
       - Document Text Detection
       - Structured data with ML model

    c) Veryfi (specialized for receipts)
       - Pre-trained receipt models
       - Higher accuracy for financial documents
       - REST API integration

 3. Security Considerations:
    - Encrypt Plaid access tokens
    - Use Keychain for sensitive data
    - Implement secure image storage
    - PCI compliance for payment data
    - Regular security audits

 4. Data Sync Strategy:
    - Daily automatic sync
    - Manual sync on demand
    - Handle duplicate transaction detection
    - Categorization rules engine
    - Transaction matching algorithms

 5. Accounting Standards:
    - Follow GAAP (Generally Accepted Accounting Principles)
    - Accrual vs Cash basis options
    - Proper double-entry bookkeeping
    - Chart of accounts customization
 */

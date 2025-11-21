import Foundation

/// Service for advanced bookkeeping operations
/// TODO: Integrate with Plaid for automated bank feeds
/// TODO: Integrate OCR service for receipt scanning
@MainActor
class BookkeepingService: ObservableObject {
    static let shared = BookkeepingService()

    init() {
        // TODO: Initialize Plaid SDK
        // TODO: Initialize OCR SDK (AWS Textract, Google Vision, or Veryfi)
    }

    // MARK: - Bank Account Operations

    /// Connect bank account via Plaid
    /// TODO: Implement Plaid Link flow
    func connectBankAccount() async throws -> BankAccount {
        // TODO: Initialize Plaid Link
        // TODO: Present Link UI for bank selection
        // TODO: Exchange public token for access token
        // TODO: Fetch account details
        // TODO: Store encrypted access token in Keychain

        // Placeholder implementation
        throw NSError(domain: "BookkeepingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Plaid integration not yet implemented"])
    }

    /// Sync transactions from bank
    /// TODO: Implement Plaid transactions sync
    func syncBankTransactions(account: BankAccount) async throws -> [BankTransaction] {
        // TODO: Call Plaid /transactions/sync endpoint
        // TODO: Fetch transactions since last sync
        // TODO: Handle pagination for large transaction sets
        // TODO: Detect and skip duplicate transactions
        // TODO: Auto-categorize transactions using rules

        guard let accessToken = account.plaidAccessToken else {
            throw NSError(domain: "BookkeepingService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No Plaid access token found"])
        }

        // Placeholder: Would make API call here
        // let transactions = try await plaidClient.syncTransactions(accessToken: accessToken, cursor: lastCursor)

        return []
    }

    /// Update account balance
    /// TODO: Implement Plaid balance fetch
    func updateAccountBalance(account: BankAccount) async throws -> BankAccount {
        // TODO: Call Plaid /accounts/balance/get endpoint
        // TODO: Update current and available balance

        var updatedAccount = account
        updatedAccount.lastSyncDate = Date()

        // Placeholder: Would fetch from Plaid
        // let balances = try await plaidClient.getBalance(accessToken: account.plaidAccessToken)
        // updatedAccount.currentBalance = balances.current
        // updatedAccount.availableBalance = balances.available

        return updatedAccount
    }

    // MARK: - Transaction Categorization

    /// Auto-categorize transaction based on description and amount
    func categorizeTransaction(_ transaction: BankTransaction) -> TransactionCategory? {
        let description = transaction.description.lowercased()

        // Utilities
        if description.contains("electric") || description.contains("power") || description.contains("utility") {
            return .utilities
        }

        // Rent
        if description.contains("rent") || description.contains("lease") {
            return .rent
        }

        // Supplies
        if description.contains("amazon") || description.contains("supply") || description.contains("massage warehouse") {
            return .supplies
        }

        // Marketing
        if description.contains("google ads") || description.contains("facebook") || description.contains("instagram") {
            return .marketing
        }

        // Software
        if description.contains("software") || description.contains("subscription") || description.contains("saas") {
            return .softwareSubscriptions
        }

        // Bank fees
        if description.contains("fee") && transaction.isDebit {
            return .bankFees
        }

        // Payroll
        if description.contains("payroll") || description.contains("wage") {
            return .salaries
        }

        // Insurance
        if description.contains("insurance") {
            return .insurance
        }

        // Income - credit card payments, checks, transfers
        if transaction.isCredit && (description.contains("payment") || description.contains("deposit")) {
            return .serviceRevenue
        }

        return nil // Cannot auto-categorize
    }

    /// Apply categorization rule
    func applyCategorization(
        transaction: BankTransaction,
        category: TransactionCategory
    ) -> BankTransaction {
        var updated = transaction
        updated.category = category
        return updated
    }

    // MARK: - Receipt Scanning

    /// Scan receipt image using OCR
    /// TODO: Implement OCR integration (AWS Textract, Google Vision, or Veryfi)
    func scanReceipt(imageData: Data) async throws -> Receipt {
        // TODO: Upload image to OCR service
        // TODO: Extract text using OCR
        // TODO: Parse structured data (vendor, date, amount, line items)
        // TODO: Calculate confidence score
        // TODO: Save image to secure storage
        // TODO: Return Receipt object with extracted data

        /*
        Example with AWS Textract:
        let textractClient = Textract.TextractClient(region: "us-east-1")
        let request = AnalyzeExpenseRequest(document: Document(bytes: imageData))
        let response = try await textractClient.analyzeExpense(input: request)

        // Parse response to extract:
        // - Vendor name
        // - Transaction date
        // - Total amount
        // - Tax amount
        // - Line items
        */

        /*
        Example with Veryfi:
        let veryfiClient = VeryfiClient(clientId: clientId, clientSecret: clientSecret)
        let response = try await veryfiClient.processDocument(imageData)

        // Veryfi returns structured JSON with:
        // - vendor.name
        // - date
        // - total
        // - tax
        // - line_items[]
        */

        // Placeholder implementation
        let receipt = Receipt(
            vendor: "Unknown Vendor",
            date: Date(),
            totalAmount: 0,
            status: .needsReview,
            notes: "OCR integration not yet implemented"
        )

        return receipt
    }

    /// Parse OCR text to extract receipt data
    func parseReceiptText(_ ocrText: String) -> (vendor: String?, date: Date?, amount: Double?, tax: Double?) {
        // TODO: Implement intelligent parsing
        // - Look for patterns like "Total: $XX.XX"
        // - Look for date patterns
        // - Extract vendor name (usually first line)
        // - Look for tax amount

        var vendor: String?
        var date: Date?
        var amount: Double?
        var tax: Double?

        let lines = ocrText.components(separatedBy: .newlines)

        // Simple heuristics (would be more sophisticated in production)
        for line in lines {
            let lowercased = line.lowercased()

            // Look for total amount
            if lowercased.contains("total") {
                if let match = line.range(of: "\\$?\\d+\\.\\d{2}", options: .regularExpression) {
                    let amountString = String(line[match]).replacingOccurrences(of: "$", with: "")
                    amount = Double(amountString)
                }
            }

            // Look for tax
            if lowercased.contains("tax") {
                if let match = line.range(of: "\\$?\\d+\\.\\d{2}", options: .regularExpression) {
                    let taxString = String(line[match]).replacingOccurrences(of: "$", with: "")
                    tax = Double(taxString)
                }
            }

            // Look for date patterns
            if lowercased.contains("/") || lowercased.contains("-") {
                // Would use more sophisticated date parsing
                // let dateFormatter = DateFormatter()
                // dateFormatter.dateFormat = "MM/dd/yyyy"
                // date = dateFormatter.date(from: line)
            }
        }

        // Vendor is typically first non-empty line
        if let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            vendor = firstLine.trimmingCharacters(in: .whitespaces)
        }

        return (vendor, date, amount, tax)
    }

    // MARK: - Reconciliation

    /// Start bank reconciliation for period
    func startReconciliation(
        account: BankAccount,
        periodStart: Date,
        periodEnd: Date,
        statementBalance: Double
    ) -> BankReconciliation {
        // Calculate book balance from transactions
        // Would fetch from repository in real implementation
        let bookBalance = account.currentBalance

        return BankReconciliation(
            bankAccountId: account.id,
            periodStart: periodStart,
            periodEnd: periodEnd,
            statementBalance: statementBalance,
            bookBalance: bookBalance
        )
    }

    /// Mark transaction as reconciled
    func reconcileTransaction(
        reconciliation: BankReconciliation,
        transactionId: UUID
    ) -> BankReconciliation {
        var updated = reconciliation

        // Move from unreconciled to reconciled
        if let index = updated.unreconciledTransactions.firstIndex(of: transactionId) {
            updated.unreconciledTransactions.remove(at: index)
            updated.reconciledTransactions.append(transactionId)
        }

        // Recalculate difference
        // Would need transaction amounts in real implementation

        return updated
    }

    /// Complete reconciliation
    func completeReconciliation(
        reconciliation: BankReconciliation,
        completedBy: UUID
    ) -> BankReconciliation {
        var updated = reconciliation
        updated.status = reconciliation.isBalanced ? .balanced : .unbalanced
        updated.completedDate = Date()
        updated.completedBy = completedBy

        return updated
    }

    // MARK: - Financial Statements

    /// Generate income statement for period
    func generateIncomeStatement(
        transactions: [BankTransaction],
        periodStart: Date,
        periodEnd: Date
    ) -> FinancialStatement {
        let periodTransactions = transactions.filter { transaction in
            transaction.date >= periodStart && transaction.date <= periodEnd
        }

        // Would calculate revenue and expenses by category
        // Group by income vs expense categories
        // Calculate net income

        return FinancialStatement(
            statementType: .incomeStatement,
            periodStart: periodStart,
            periodEnd: periodEnd,
            generatedDate: Date(),
            accounts: [],
            transactions: periodTransactions
        )
    }

    /// Generate balance sheet as of date
    func generateBalanceSheet(
        accounts: [BankAccount],
        asOfDate: Date
    ) -> FinancialStatement {
        // Would calculate assets, liabilities, equity
        // Assets = Liabilities + Equity

        return FinancialStatement(
            statementType: .balanceSheet,
            periodStart: asOfDate,
            periodEnd: asOfDate,
            generatedDate: Date(),
            accounts: [],
            transactions: []
        )
    }

    /// Generate cash flow statement for period
    func generateCashFlowStatement(
        transactions: [BankTransaction],
        periodStart: Date,
        periodEnd: Date
    ) -> FinancialStatement {
        let periodTransactions = transactions.filter { transaction in
            transaction.date >= periodStart && transaction.date <= periodEnd
        }

        // Would calculate:
        // - Operating activities
        // - Investing activities
        // - Financing activities
        // Net change in cash

        return FinancialStatement(
            statementType: .cashFlow,
            periodStart: periodStart,
            periodEnd: periodEnd,
            generatedDate: Date(),
            accounts: [],
            transactions: periodTransactions
        )
    }

    // MARK: - Statistics

    /// Calculate bookkeeping statistics
    func calculateStatistics(
        accounts: [BankAccount],
        transactions: [BankTransaction],
        receipts: [Receipt]
    ) -> BookkeepingStatistics {
        let totalBalance = accounts.filter { $0.isActive }.reduce(0) { $0 + $1.currentBalance }
        let uncategorized = transactions.filter { $0.needsCategorization }.count
        let unreconciled = transactions.filter { !$0.isReconciled }.count
        let unprocessedReceipts = receipts.filter { !$0.isProcessed }.count
        let lastSync = accounts.compactMap { $0.lastSyncDate }.max()

        // Calculate monthly revenue and expenses
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentTransactions = transactions.filter { $0.date >= thirtyDaysAgo }

        let revenue = recentTransactions.filter { $0.isCredit && $0.category?.isIncome == true }.reduce(0) { $0 + abs($1.amount) }
        let expenses = recentTransactions.filter { $0.isDebit && $0.category?.isExpense == true }.reduce(0) { $0 + abs($1.amount) }

        let profitMargin = revenue > 0 ? ((revenue - expenses) / revenue) * 100 : 0

        return BookkeepingStatistics(
            totalBankAccounts: accounts.count,
            totalBalance: totalBalance,
            uncategorizedTransactions: uncategorized,
            unreconciledTransactions: unreconciled,
            unprocessedReceipts: unprocessedReceipts,
            lastSyncDate: lastSync,
            monthlyRevenue: revenue,
            monthlyExpenses: expenses,
            profitMargin: profitMargin
        )
    }

    // MARK: - Transaction Matching

    /// Match bank transaction to expense record
    func matchTransactionToExpense(
        transaction: BankTransaction,
        expenses: [Expense]
    ) -> Expense? {
        // Look for expenses with matching amount and similar date
        let matchingExpenses = expenses.filter { expense in
            // Amount matches (within $0.01)
            let amountMatches = abs(abs(transaction.amount) - expense.amount) < 0.01

            // Date within 3 days
            let dateRange: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
            let dateMatches = abs(transaction.date.timeIntervalSince(expense.date)) < dateRange

            return amountMatches && dateMatches
        }

        return matchingExpenses.first
    }

    /// Create expense from bank transaction
    func createExpenseFromTransaction(
        transaction: BankTransaction
    ) -> Expense {
        return Expense(
            description: transaction.description,
            amount: abs(transaction.amount),
            date: transaction.date,
            category: transaction.category?.rawValue ?? "Other",
            paymentMethod: "Bank Account",
            notes: "Auto-created from bank transaction"
        )
    }

    // MARK: - Export

    /// Export transactions to CSV
    func exportTransactionsToCSV(
        transactions: [BankTransaction]
    ) -> String {
        var csv = "Date,Description,Amount,Category,Merchant,Status,Reconciled\n"

        for transaction in transactions {
            let row = [
                transaction.date.formatted(date: .numeric, time: .omitted),
                "\"" + transaction.description + "\"",
                String(format: "%.2f", transaction.amount),
                transaction.category?.rawValue ?? "",
                transaction.merchant ?? "",
                transaction.status.rawValue,
                transaction.isReconciled ? "Yes" : "No"
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export to QuickBooks format
    /// TODO: Implement QuickBooks IIF or QBO format
    func exportToQuickBooks(
        transactions: [BankTransaction]
    ) -> String {
        // TODO: Generate QuickBooks IIF (Intuit Interchange Format) file
        // or QBO (QuickBooks Online) format

        return ""
    }
}

/*
 PLAID INTEGRATION GUIDE:

 1. Setup:
    - Create account at https://dashboard.plaid.com
    - Get API credentials (client_id and secret)
    - Install Plaid SDK: Add to Package.swift
      .package(url: "https://github.com/plaid/plaid-swift", from: "1.0.0")

 2. Link Flow:
    a) Create Link Token:
       POST https://sandbox.plaid.com/link/token/create
       {
         "client_id": "YOUR_CLIENT_ID",
         "secret": "YOUR_SECRET",
         "user": { "client_user_id": "user-id" },
         "products": ["transactions"],
         "country_codes": ["US"],
         "language": "en"
       }

    b) Present Plaid Link UI with token

    c) Exchange public token for access token:
       POST https://sandbox.plaid.com/item/public_token/exchange
       {
         "client_id": "YOUR_CLIENT_ID",
         "secret": "YOUR_SECRET",
         "public_token": "public-sandbox-xxx"
       }
       Response: { "access_token": "access-sandbox-xxx" }

    d) Store access_token securely (Keychain)

 3. Sync Transactions:
    POST https://sandbox.plaid.com/transactions/sync
    {
      "client_id": "YOUR_CLIENT_ID",
      "secret": "YOUR_SECRET",
      "access_token": "access-sandbox-xxx",
      "cursor": "last_cursor_value" // or null for first sync
    }

    Response includes:
    - added: new transactions
    - modified: updated transactions
    - removed: deleted transactions
    - next_cursor: for next sync

 4. Get Balance:
    POST https://sandbox.plaid.com/accounts/balance/get
    {
      "client_id": "YOUR_CLIENT_ID",
      "secret": "YOUR_SECRET",
      "access_token": "access-sandbox-xxx"
    }

 5. Error Handling:
    - ITEM_LOGIN_REQUIRED: User needs to reauthorize
    - RATE_LIMIT_EXCEEDED: Too many requests
    - PRODUCT_NOT_READY: Data not yet available

 OCR INTEGRATION OPTIONS:

 Option 1: AWS Textract
 - Most comprehensive, but more complex setup
 - AnalyzeExpense API specifically for receipts
 - Returns structured data (vendor, date, total, tax, line items)

 Option 2: Google Cloud Vision
 - Good OCR quality
 - Document Text Detection API
 - Requires custom parsing of extracted text

 Option 3: Veryfi (Recommended for receipts)
 - Specialized for financial documents
 - Pre-trained receipt models
 - Highest accuracy for receipts
 - Simple REST API
 - Example:
   POST https://api.veryfi.com/api/v8/partner/documents/
   Headers:
     CLIENT-ID: your_client_id
     AUTHORIZATION: apikey your_username:your_api_key
   Body: multipart/form-data with image file

   Response:
   {
     "vendor": { "name": "Massage Supply Co" },
     "date": "2024-01-15",
     "total": 156.78,
     "tax": 12.54,
     "line_items": [...]
   }
 */

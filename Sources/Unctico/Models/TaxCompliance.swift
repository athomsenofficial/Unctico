import Foundation
import CoreLocation

/// Tax compliance models for 1099 forms, mileage tracking, and expense management

// MARK: - 1099 Form Models

/// 1099 form for independent contractors and therapists
struct Form1099: Identifiable, Codable {
    let id: UUID
    let taxYear: Int
    let recipientId: UUID // Contractor/therapist
    let recipientName: String
    let recipientTin: String // Tax Identification Number (SSN or EIN)
    let recipientAddress: TaxAddress
    let payerTin: String // Business EIN
    let payerName: String
    let payerAddress: TaxAddress
    let formType: Form1099Type
    let nonemployeeCompensation: Double // Box 1 for 1099-NEC
    let federalIncomeTaxWithheld: Double // Box 4
    let stateIncomeTaxWithheld: Double // Box 5
    let state: String // State abbreviation
    let payerStateNumber: String
    let stateIncome: Double // Box 6
    let createdDate: Date
    let filedDate: Date?
    let status: FormStatus
    let notes: String

    init(
        id: UUID = UUID(),
        taxYear: Int,
        recipientId: UUID,
        recipientName: String,
        recipientTin: String,
        recipientAddress: TaxAddress,
        payerTin: String,
        payerName: String,
        payerAddress: TaxAddress,
        formType: Form1099Type = .nec,
        nonemployeeCompensation: Double,
        federalIncomeTaxWithheld: Double = 0,
        stateIncomeTaxWithheld: Double = 0,
        state: String,
        payerStateNumber: String = "",
        stateIncome: Double = 0,
        createdDate: Date = Date(),
        filedDate: Date? = nil,
        status: FormStatus = .draft,
        notes: String = ""
    ) {
        self.id = id
        self.taxYear = taxYear
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.recipientTin = recipientTin
        self.recipientAddress = recipientAddress
        self.payerTin = payerTin
        self.payerName = payerName
        self.payerAddress = payerAddress
        self.formType = formType
        self.nonemployeeCompensation = nonemployeeCompensation
        self.federalIncomeTaxWithheld = federalIncomeTaxWithheld
        self.stateIncomeTaxWithheld = stateIncomeTaxWithheld
        self.state = state
        self.payerStateNumber = payerStateNumber
        self.stateIncome = stateIncome
        self.createdDate = createdDate
        self.filedDate = filedDate
        self.status = status
        self.notes = notes
    }

    var requiresFiling: Bool {
        // 1099-NEC required if compensation >= $600
        nonemployeeCompensation >= 600
    }

    var formattedTin: String {
        if recipientTin.count == 9 {
            // Format as XXX-XX-XXXX for SSN
            let prefix = recipientTin.prefix(3)
            let middle = recipientTin.dropFirst(3).prefix(2)
            let suffix = recipientTin.dropFirst(5)
            return "\(prefix)-\(middle)-\(suffix)"
        }
        return recipientTin
    }
}

enum Form1099Type: String, Codable, CaseIterable {
    case nec = "1099-NEC" // Nonemployee Compensation
    case misc = "1099-MISC" // Miscellaneous Income
    case k = "1099-K" // Payment Card and Third Party Network Transactions
    case int = "1099-INT" // Interest Income
    case div = "1099-DIV" // Dividends

    var description: String {
        switch self {
        case .nec:
            return "Nonemployee Compensation - For independent contractors"
        case .misc:
            return "Miscellaneous Income - For rents, prizes, awards"
        case .k:
            return "Payment Card Transactions - For payment processors"
        case .int:
            return "Interest Income"
        case .div:
            return "Dividends and Distributions"
        }
    }
}

enum FormStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case reviewed = "Reviewed"
    case filed = "Filed"
    case corrected = "Corrected"
    case voided = "Voided"

    var color: String {
        switch self {
        case .draft: return "orange"
        case .reviewed: return "blue"
        case .filed: return "green"
        case .corrected: return "purple"
        case .voided: return "red"
        }
    }
}

struct TaxAddress: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String

    init(street: String, city: String, state: String, zipCode: String, country: String = "USA") {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }

    var formatted: String {
        """
        \(street)
        \(city), \(state) \(zipCode)
        \(country)
        """
    }
}

/// Contractor information for 1099 tracking
struct TaxContractor: Identifiable, Codable {
    let id: UUID
    let name: String
    let tin: String // SSN or EIN
    let tinType: TINType
    let address: TaxAddress
    let email: String
    let phone: String
    let isActive: Bool
    let w9ReceivedDate: Date?
    let notes: String

    init(
        id: UUID = UUID(),
        name: String,
        tin: String,
        tinType: TINType = .ssn,
        address: TaxAddress,
        email: String = "",
        phone: String = "",
        isActive: Bool = true,
        w9ReceivedDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.tin = tin
        self.tinType = tinType
        self.address = address
        self.email = email
        self.phone = phone
        self.isActive = isActive
        self.w9ReceivedDate = w9ReceivedDate
        self.notes = notes
    }

    var hasValidW9: Bool {
        w9ReceivedDate != nil && !tin.isEmpty
    }
}

enum TINType: String, Codable {
    case ssn = "SSN"
    case ein = "EIN"
}

// MARK: - Mileage Tracking Models

/// Business mileage trip for tax deductions
struct MileageTrip: Identifiable, Codable {
    let id: UUID
    let date: Date
    let startLocation: String
    let endLocation: String
    let startOdometer: Double?
    let endOdometer: Double?
    let distance: Double // Miles
    let purpose: TripPurpose
    let description: String
    let clientId: UUID?
    let clientName: String?
    let vehicleId: UUID?
    let startCoordinates: Coordinates?
    let endCoordinates: Coordinates?
    let isRoundTrip: Bool
    let notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startLocation: String,
        endLocation: String,
        startOdometer: Double? = nil,
        endOdometer: Double? = nil,
        distance: Double,
        purpose: TripPurpose,
        description: String,
        clientId: UUID? = nil,
        clientName: String? = nil,
        vehicleId: UUID? = nil,
        startCoordinates: Coordinates? = nil,
        endCoordinates: Coordinates? = nil,
        isRoundTrip: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.startOdometer = startOdometer
        self.endOdometer = endOdometer
        self.distance = distance
        self.purpose = purpose
        self.description = description
        self.clientId = clientId
        self.clientName = clientName
        self.vehicleId = vehicleId
        self.startCoordinates = startCoordinates
        self.endCoordinates = endCoordinates
        self.isRoundTrip = isRoundTrip
        self.notes = notes
    }

    /// Calculate deduction using IRS standard mileage rate
    func calculateDeduction(rate: Double) -> Double {
        distance * rate
    }

    var totalDistance: Double {
        isRoundTrip ? distance * 2 : distance
    }
}

enum TripPurpose: String, Codable, CaseIterable {
    case clientVisit = "Client Visit (Mobile Massage)"
    case businessMeeting = "Business Meeting"
    case supplyPurchase = "Supply Purchase"
    case bankDeposit = "Bank Deposit"
    case continuingEducation = "Continuing Education"
    case marketing = "Marketing/Networking"
    case postOffice = "Post Office/Shipping"
    case businessTravel = "Business Travel"
    case other = "Other Business Purpose"

    var isDeductible: Bool {
        // All business purposes are typically deductible
        true
    }

    var icon: String {
        switch self {
        case .clientVisit: return "figure.walk"
        case .businessMeeting: return "person.2.fill"
        case .supplyPurchase: return "cart.fill"
        case .bankDeposit: return "dollarsign.circle.fill"
        case .continuingEducation: return "book.fill"
        case .marketing: return "megaphone.fill"
        case .postOffice: return "envelope.fill"
        case .businessTravel: return "airplane"
        case .other: return "briefcase.fill"
        }
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from location: CLLocationCoordinate2D) {
        self.latitude = location.latitude
        self.longitude = location.longitude
    }

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Vehicle information for mileage tracking
struct Vehicle: Identifiable, Codable {
    let id: UUID
    let make: String
    let model: String
    let year: Int
    let licensePlate: String
    let vin: String
    let currentOdometer: Double
    let isActive: Bool
    let notes: String

    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        year: Int,
        licensePlate: String = "",
        vin: String = "",
        currentOdometer: Double = 0,
        isActive: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.licensePlate = licensePlate
        self.vin = vin
        self.currentOdometer = currentOdometer
        self.isActive = isActive
        self.notes = notes
    }

    var displayName: String {
        "\(year) \(make) \(model)"
    }
}

// MARK: - Business Expense Models

/// Business expense for tax deductions
struct BusinessExpense: Identifiable, Codable {
    let id: UUID
    let date: Date
    let category: ExpenseCategory
    let amount: Double
    let merchant: String
    let description: String
    let paymentMethod: String
    let receiptImagePath: String?
    let isRecurring: Bool
    let isTaxDeductible: Bool
    let notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        category: ExpenseCategory,
        amount: Double,
        merchant: String,
        description: String,
        paymentMethod: String = "",
        receiptImagePath: String? = nil,
        isRecurring: Bool = false,
        isTaxDeductible: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.amount = amount
        self.merchant = merchant
        self.description = description
        self.paymentMethod = paymentMethod
        self.receiptImagePath = receiptImagePath
        self.isRecurring = isRecurring
        self.isTaxDeductible = isTaxDeductible
        self.notes = notes
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case supplies = "Supplies & Materials"
    case equipment = "Equipment"
    case rent = "Rent/Lease"
    case utilities = "Utilities"
    case insurance = "Insurance"
    case advertising = "Advertising & Marketing"
    case education = "Continuing Education"
    case professional = "Professional Services"
    case software = "Software & Subscriptions"
    case travel = "Travel"
    case meals = "Meals & Entertainment"
    case phone = "Phone & Internet"
    case laundry = "Laundry & Linens"
    case repairs = "Repairs & Maintenance"
    case licenses = "Licenses & Permits"
    case bankFees = "Bank & Payment Processing Fees"
    case office = "Office Supplies"
    case other = "Other"

    var icon: String {
        switch self {
        case .supplies: return "basket.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .rent: return "building.2.fill"
        case .utilities: return "bolt.fill"
        case .insurance: return "shield.fill"
        case .advertising: return "megaphone.fill"
        case .education: return "book.fill"
        case .professional: return "briefcase.fill"
        case .software: return "desktopcomputer"
        case .travel: return "airplane"
        case .meals: return "fork.knife"
        case .phone: return "phone.fill"
        case .laundry: return "washer.fill"
        case .repairs: return "hammer.fill"
        case .licenses: return "doc.text.fill"
        case .bankFees: return "creditcard.fill"
        case .office: return "paperclip"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var deductionPercentage: Double {
        switch self {
        case .meals:
            return 0.5 // Meals typically 50% deductible
        default:
            return 1.0 // Most expenses 100% deductible
        }
    }
}

// MARK: - Tax Settings

/// IRS mileage rates by year
struct MileageRate: Codable {
    let year: Int
    let businessRate: Double // Per mile
    let medicalRate: Double
    let charitableRate: Double

    static let rates: [MileageRate] = [
        MileageRate(year: 2024, businessRate: 0.67, medicalRate: 0.21, charitableRate: 0.14),
        MileageRate(year: 2023, businessRate: 0.655, medicalRate: 0.22, charitableRate: 0.14),
        MileageRate(year: 2022, businessRate: 0.625, medicalRate: 0.22, charitableRate: 0.14),
        MileageRate(year: 2021, businessRate: 0.56, medicalRate: 0.16, charitableRate: 0.14),
    ]

    static func rate(for year: Int) -> MileageRate {
        rates.first { $0.year == year } ?? rates[0]
    }
}

/// Tax year summary
struct TaxYearSummary: Codable {
    let year: Int
    let totalIncome: Double
    let totalExpenses: Double
    let totalMileageDeduction: Double
    let total1099Income: Double
    let totalDeductions: Double
    let netIncome: Double
    let quarterlyPayments: [QuarterlyTaxPayment]

    var estimatedTaxLiability: Double {
        // Simplified calculation: 30% of net income (self-employment + income tax estimate)
        netIncome * 0.30
    }

    var taxesPaid: Double {
        quarterlyPayments.reduce(0) { $0 + $1.amount }
    }

    var estimatedTaxDue: Double {
        max(0, estimatedTaxLiability - taxesPaid)
    }
}

struct QuarterlyTaxPayment: Identifiable, Codable {
    let id: UUID
    let year: Int
    let quarter: Int // 1-4
    let dueDate: Date
    let amount: Double
    let paymentDate: Date?
    let confirmationNumber: String
    let notes: String

    init(
        id: UUID = UUID(),
        year: Int,
        quarter: Int,
        dueDate: Date,
        amount: Double,
        paymentDate: Date? = nil,
        confirmationNumber: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.year = year
        self.quarter = quarter
        self.dueDate = dueDate
        self.amount = amount
        self.paymentDate = paymentDate
        self.confirmationNumber = confirmationNumber
        self.notes = notes
    }

    var isPaid: Bool {
        paymentDate != nil
    }

    var isOverdue: Bool {
        !isPaid && Date() > dueDate
    }

    static func dueDates(for year: Int) -> [Date] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year

        // Q1: April 15
        components.month = 4
        components.day = 15
        let q1 = calendar.date(from: components)!

        // Q2: June 15
        components.month = 6
        components.day = 15
        let q2 = calendar.date(from: components)!

        // Q3: September 15
        components.month = 9
        components.day = 15
        let q3 = calendar.date(from: components)!

        // Q4: January 15 (next year)
        components.year = year + 1
        components.month = 1
        components.day = 15
        let q4 = calendar.date(from: components)!

        return [q1, q2, q3, q4]
    }
}

// MARK: - Tax Document

struct TaxDocument: Identifiable, Codable {
    let id: UUID
    let year: Int
    let documentType: TaxDocumentType
    let fileName: String
    let filePath: String
    let uploadDate: Date
    let notes: String

    init(
        id: UUID = UUID(),
        year: Int,
        documentType: TaxDocumentType,
        fileName: String,
        filePath: String,
        uploadDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.year = year
        self.documentType = documentType
        self.fileName = fileName
        self.filePath = filePath
        self.uploadDate = uploadDate
        self.notes = notes
    }
}

enum TaxDocumentType: String, Codable, CaseIterable {
    case form1099 = "1099 Form"
    case w9 = "W-9 Form"
    case receipt = "Receipt"
    case invoice = "Invoice"
    case bankStatement = "Bank Statement"
    case taxReturn = "Tax Return"
    case quarterlyPayment = "Quarterly Payment Confirmation"
    case other = "Other"

    var icon: String {
        switch self {
        case .form1099: return "doc.text.fill"
        case .w9: return "doc.fill"
        case .receipt: return "receipt"
        case .invoice: return "doc.richtext"
        case .bankStatement: return "building.columns.fill"
        case .taxReturn: return "folder.fill"
        case .quarterlyPayment: return "dollarsign.circle.fill"
        case .other: return "doc"
        }
    }
}

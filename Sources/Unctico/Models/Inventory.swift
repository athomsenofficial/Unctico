import Foundation

/// Inventory management models for supplies and equipment tracking

// MARK: - Inventory Item

struct InventoryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: InventoryCategory
    var sku: String
    var barcode: String?
    var description: String
    var currentStock: Double
    var unit: MeasurementUnit
    var minimumStock: Double
    var maximumStock: Double
    var reorderPoint: Double
    var reorderQuantity: Double
    var costPerUnit: Double
    var supplier: Supplier?
    var location: StorageLocation
    var expirationDate: Date?
    var lastRestockDate: Date?
    var lastCountDate: Date?
    var isActive: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        category: InventoryCategory,
        sku: String,
        barcode: String? = nil,
        description: String = "",
        currentStock: Double,
        unit: MeasurementUnit,
        minimumStock: Double,
        maximumStock: Double,
        reorderPoint: Double,
        reorderQuantity: Double,
        costPerUnit: Double,
        supplier: Supplier? = nil,
        location: StorageLocation = .mainStorage,
        expirationDate: Date? = nil,
        lastRestockDate: Date? = nil,
        lastCountDate: Date? = nil,
        isActive: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.sku = sku
        self.barcode = barcode
        self.description = description
        self.currentStock = currentStock
        self.unit = unit
        self.minimumStock = minimumStock
        self.maximumStock = maximumStock
        self.reorderPoint = reorderPoint
        self.reorderQuantity = reorderQuantity
        self.costPerUnit = costPerUnit
        self.supplier = supplier
        self.location = location
        self.expirationDate = expirationDate
        self.lastRestockDate = lastRestockDate
        self.lastCountDate = lastCountDate
        self.isActive = isActive
        self.notes = notes
    }

    var stockStatus: StockStatus {
        if currentStock <= 0 {
            return .outOfStock
        } else if currentStock <= minimumStock {
            return .critical
        } else if currentStock <= reorderPoint {
            return .low
        } else if currentStock >= maximumStock {
            return .overstock
        } else {
            return .adequate
        }
    }

    var totalValue: Double {
        currentStock * costPerUnit
    }

    var needsReorder: Bool {
        currentStock <= reorderPoint
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }

    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiration else { return false }
        return days <= 30 && days > 0
    }

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

enum InventoryCategory: String, Codable, CaseIterable {
    case massageOils = "Massage Oils & Lotions"
    case essentialOils = "Essential Oils"
    case linens = "Linens & Towels"
    case disposables = "Disposable Supplies"
    case equipment = "Equipment & Tools"
    case hotColdTherapy = "Hot/Cold Therapy"
    case cleaning = "Cleaning Supplies"
    case retail = "Retail Products"
    case office = "Office Supplies"
    case marketing = "Marketing Materials"
    case other = "Other"

    var icon: String {
        switch self {
        case .massageOils: return "drop.fill"
        case .essentialOils: return "leaf.fill"
        case .linens: return "bed.double.fill"
        case .disposables: return "doc.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .hotColdTherapy: return "thermometer"
        case .cleaning: return "sparkles"
        case .retail: return "cart.fill"
        case .office: return "paperclip"
        case .marketing: return "megaphone.fill"
        case .other: return "box.fill"
        }
    }
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case bottle = "Bottle"
    case ounce = "Ounce"
    case milliliter = "Milliliter"
    case liter = "Liter"
    case gallon = "Gallon"
    case piece = "Piece"
    case set = "Set"
    case package = "Package"
    case box = "Box"
    case roll = "Roll"
    case pair = "Pair"
    case each = "Each"

    var abbreviation: String {
        switch self {
        case .bottle: return "btl"
        case .ounce: return "oz"
        case .milliliter: return "ml"
        case .liter: return "L"
        case .gallon: return "gal"
        case .piece: return "pc"
        case .set: return "set"
        case .package: return "pkg"
        case .box: return "box"
        case .roll: return "roll"
        case .pair: return "pair"
        case .each: return "ea"
        }
    }
}

enum StockStatus: String, Codable {
    case outOfStock = "Out of Stock"
    case critical = "Critical"
    case low = "Low Stock"
    case adequate = "Adequate"
    case overstock = "Overstock"

    var color: String {
        switch self {
        case .outOfStock: return "red"
        case .critical: return "red"
        case .low: return "orange"
        case .adequate: return "green"
        case .overstock: return "blue"
        }
    }

    var icon: String {
        switch self {
        case .outOfStock: return "xmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .low: return "exclamationmark.circle.fill"
        case .adequate: return "checkmark.circle.fill"
        case .overstock: return "arrow.up.circle.fill"
        }
    }
}

enum StorageLocation: String, Codable, CaseIterable {
    case mainStorage = "Main Storage"
    case treatmentRoom1 = "Treatment Room 1"
    case treatmentRoom2 = "Treatment Room 2"
    case treatmentRoom3 = "Treatment Room 3"
    case reception = "Reception Area"
    case office = "Office"
    case laundry = "Laundry Room"
    case refrigerator = "Refrigerator"
    case cabinet = "Cabinet"
    case closet = "Closet"
    case other = "Other"
}

// MARK: - Supplier

struct Supplier: Identifiable, Codable {
    let id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var website: String
    var address: String
    var accountNumber: String
    var paymentTerms: String
    var leadTimeDays: Int
    var minimumOrder: Double
    var notes: String
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        contactPerson: String = "",
        email: String = "",
        phone: String = "",
        website: String = "",
        address: String = "",
        accountNumber: String = "",
        paymentTerms: String = "Net 30",
        leadTimeDays: Int = 7,
        minimumOrder: Double = 0,
        notes: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.website = website
        self.address = address
        self.accountNumber = accountNumber
        self.paymentTerms = paymentTerms
        self.leadTimeDays = leadTimeDays
        self.minimumOrder = minimumOrder
        self.notes = notes
        self.isActive = isActive
    }
}

// MARK: - Stock Transaction

struct StockTransaction: Identifiable, Codable {
    let id: UUID
    let itemId: UUID
    let itemName: String
    let transactionType: TransactionType
    let quantity: Double
    let unit: MeasurementUnit
    let costPerUnit: Double?
    let totalCost: Double?
    let date: Date
    let reference: String
    let notes: String
    let performedBy: String

    init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        transactionType: TransactionType,
        quantity: Double,
        unit: MeasurementUnit,
        costPerUnit: Double? = nil,
        totalCost: Double? = nil,
        date: Date = Date(),
        reference: String = "",
        notes: String = "",
        performedBy: String = "User"
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.transactionType = transactionType
        self.quantity = quantity
        self.unit = unit
        self.costPerUnit = costPerUnit
        self.totalCost = totalCost
        self.date = date
        self.reference = reference
        self.notes = notes
        self.performedBy = performedBy
    }

    var quantityChange: Double {
        switch transactionType {
        case .stockIn, .adjustment, .return:
            return quantity
        case .stockOut, .waste, .usage:
            return -quantity
        }
    }
}

enum TransactionType: String, Codable {
    case stockIn = "Stock In"
    case stockOut = "Stock Out"
    case adjustment = "Adjustment"
    case usage = "Usage"
    case waste = "Waste/Spoilage"
    case `return` = "Return"

    var icon: String {
        switch self {
        case .stockIn: return "arrow.down.circle.fill"
        case .stockOut: return "arrow.up.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .usage: return "hand.raised.fill"
        case .waste: return "trash.fill"
        case .return: return "arrow.uturn.backward.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .stockIn: return "green"
        case .stockOut: return "blue"
        case .adjustment: return "orange"
        case .usage: return "purple"
        case .waste: return "red"
        case .return: return "yellow"
        }
    }
}

// MARK: - Purchase Order

struct PurchaseOrder: Identifiable, Codable {
    let id: UUID
    var poNumber: String
    var supplier: Supplier
    var orderDate: Date
    var expectedDeliveryDate: Date?
    var actualDeliveryDate: Date?
    var status: POStatus
    var items: [PurchaseOrderItem]
    var subtotal: Double
    var tax: Double
    var shipping: Double
    var total: Double
    var notes: String

    init(
        id: UUID = UUID(),
        poNumber: String,
        supplier: Supplier,
        orderDate: Date = Date(),
        expectedDeliveryDate: Date? = nil,
        actualDeliveryDate: Date? = nil,
        status: POStatus = .draft,
        items: [PurchaseOrderItem] = [],
        subtotal: Double = 0,
        tax: Double = 0,
        shipping: Double = 0,
        total: Double = 0,
        notes: String = ""
    ) {
        self.id = id
        self.poNumber = poNumber
        self.supplier = supplier
        self.orderDate = orderDate
        self.expectedDeliveryDate = expectedDeliveryDate
        self.actualDeliveryDate = actualDeliveryDate
        self.status = status
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.shipping = shipping
        self.total = total
        self.notes = notes
    }

    var isOverdue: Bool {
        guard let expectedDate = expectedDeliveryDate else { return false }
        return status != .received && status != .cancelled && Date() > expectedDate
    }
}

struct PurchaseOrderItem: Identifiable, Codable {
    let id: UUID
    let itemId: UUID
    let itemName: String
    let quantity: Double
    let unit: MeasurementUnit
    let costPerUnit: Double
    let total: Double
    var receivedQuantity: Double

    init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        quantity: Double,
        unit: MeasurementUnit,
        costPerUnit: Double,
        receivedQuantity: Double = 0
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.quantity = quantity
        self.unit = unit
        self.costPerUnit = costPerUnit
        self.total = quantity * costPerUnit
        self.receivedQuantity = receivedQuantity
    }

    var isFullyReceived: Bool {
        receivedQuantity >= quantity
    }

    var remainingQuantity: Double {
        max(0, quantity - receivedQuantity)
    }
}

enum POStatus: String, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case confirmed = "Confirmed"
    case partiallyReceived = "Partially Received"
    case received = "Received"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .draft: return "gray"
        case .sent: return "blue"
        case .confirmed: return "green"
        case .partiallyReceived: return "orange"
        case .received: return "green"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Inventory Count

struct InventoryCount: Identifiable, Codable {
    let id: UUID
    let countDate: Date
    let countedBy: String
    let items: [InventoryCountItem]
    let status: CountStatus
    let notes: String

    init(
        id: UUID = UUID(),
        countDate: Date = Date(),
        countedBy: String,
        items: [InventoryCountItem] = [],
        status: CountStatus = .inProgress,
        notes: String = ""
    ) {
        self.id = id
        self.countDate = countDate
        self.countedBy = countedBy
        self.items = items
        self.status = status
        self.notes = notes
    }

    var totalVariance: Double {
        items.reduce(0) { $0 + abs($1.variance) }
    }

    var totalVarianceValue: Double {
        items.reduce(0) { $0 + abs($1.varianceValue) }
    }
}

struct InventoryCountItem: Identifiable, Codable {
    let id: UUID
    let itemId: UUID
    let itemName: String
    let systemQuantity: Double
    var physicalQuantity: Double
    let unit: MeasurementUnit
    let costPerUnit: Double
    var notes: String

    init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        systemQuantity: Double,
        physicalQuantity: Double,
        unit: MeasurementUnit,
        costPerUnit: Double,
        notes: String = ""
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.systemQuantity = systemQuantity
        self.physicalQuantity = physicalQuantity
        self.unit = unit
        self.costPerUnit = costPerUnit
        self.notes = notes
    }

    var variance: Double {
        physicalQuantity - systemQuantity
    }

    var varianceValue: Double {
        variance * costPerUnit
    }

    var variancePercentage: Double {
        guard systemQuantity > 0 else { return 0 }
        return (variance / systemQuantity) * 100
    }
}

enum CountStatus: String, Codable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case reconciled = "Reconciled"

    var color: String {
        switch self {
        case .inProgress: return "orange"
        case .completed: return "blue"
        case .reconciled: return "green"
        }
    }
}

// MARK: - Usage Tracking

struct UsageRecord: Identifiable, Codable {
    let id: UUID
    let itemId: UUID
    let itemName: String
    let quantity: Double
    let unit: MeasurementUnit
    let date: Date
    let clientId: UUID?
    let clientName: String?
    let serviceId: UUID?
    let serviceName: String?
    let notes: String

    init(
        id: UUID = UUID(),
        itemId: UUID,
        itemName: String,
        quantity: Double,
        unit: MeasurementUnit,
        date: Date = Date(),
        clientId: UUID? = nil,
        clientName: String? = nil,
        serviceId: UUID? = nil,
        serviceName: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.quantity = quantity
        self.unit = unit
        self.date = date
        self.clientId = clientId
        self.clientName = clientName
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.notes = notes
    }
}

// MARK: - Inventory Statistics

struct InventoryStatistics {
    let totalItems: Int
    let totalValue: Double
    let lowStockItems: Int
    let outOfStockItems: Int
    let expiringItems: Int
    let expiredItems: Int
    let itemsByCategory: [InventoryCategory: Int]
    let valueByCategory: [InventoryCategory: Double]
    let averageDaysOfSupply: Double
    let turnoverRate: Double
}

// MARK: - Reorder Alert

struct ReorderAlert: Identifiable {
    let id: UUID
    let item: InventoryItem
    let severity: AlertSeverity
    let message: String
    let recommendedQuantity: Double

    enum AlertSeverity {
        case critical
        case warning
        case info
    }
}

import Foundation

/// Service for inventory management and stock tracking
@MainActor
class InventoryService: ObservableObject {
    static let shared = InventoryService()

    @Published var reorderAlerts: [ReorderAlert] = []

    init() {
        // Initialize service
    }

    // MARK: - Stock Management

    /// Adjust stock level for an item
    func adjustStock(
        item: InventoryItem,
        quantity: Double,
        transactionType: TransactionType,
        reference: String = "",
        notes: String = ""
    ) -> (updatedItem: InventoryItem, transaction: StockTransaction) {
        var updatedItem = item

        // Calculate new stock level
        let quantityChange = transactionType == .stockIn || transactionType == .adjustment || transactionType == .return
            ? quantity
            : -quantity

        updatedItem.currentStock = max(0, item.currentStock + quantityChange)

        // Update last restock date for stock-in transactions
        if transactionType == .stockIn {
            updatedItem.lastRestockDate = Date()
        }

        // Create transaction record
        let transaction = StockTransaction(
            itemId: item.id,
            itemName: item.name,
            transactionType: transactionType,
            quantity: quantity,
            unit: item.unit,
            costPerUnit: transactionType == .stockIn ? item.costPerUnit : nil,
            totalCost: transactionType == .stockIn ? quantity * item.costPerUnit : nil,
            reference: reference,
            notes: notes
        )

        return (updatedItem, transaction)
    }

    /// Record usage of inventory item
    func recordUsage(
        item: InventoryItem,
        quantity: Double,
        clientId: UUID? = nil,
        clientName: String? = nil,
        serviceId: UUID? = nil,
        serviceName: String? = nil
    ) -> (updatedItem: InventoryItem, transaction: StockTransaction, usageRecord: UsageRecord) {
        // Adjust stock
        let (updatedItem, transaction) = adjustStock(
            item: item,
            quantity: quantity,
            transactionType: .usage,
            notes: "Used for \(serviceName ?? "service")"
        )

        // Create usage record
        let usageRecord = UsageRecord(
            itemId: item.id,
            itemName: item.name,
            quantity: quantity,
            unit: item.unit,
            clientId: clientId,
            clientName: clientName,
            serviceId: serviceId,
            serviceName: serviceName
        )

        return (updatedItem, transaction, usageRecord)
    }

    // MARK: - Reorder Management

    /// Generate reorder alerts for items below reorder point
    func generateReorderAlerts(items: [InventoryItem]) -> [ReorderAlert] {
        var alerts: [ReorderAlert] = []

        for item in items where item.isActive {
            if item.currentStock <= 0 {
                alerts.append(ReorderAlert(
                    id: item.id,
                    item: item,
                    severity: .critical,
                    message: "\(item.name) is out of stock",
                    recommendedQuantity: item.reorderQuantity
                ))
            } else if item.currentStock <= item.minimumStock {
                alerts.append(ReorderAlert(
                    id: item.id,
                    item: item,
                    severity: .critical,
                    message: "\(item.name) is at critical stock level (\(String(format: "%.1f", item.currentStock)) \(item.unit.abbreviation))",
                    recommendedQuantity: item.reorderQuantity
                ))
            } else if item.currentStock <= item.reorderPoint {
                alerts.append(ReorderAlert(
                    id: item.id,
                    item: item,
                    severity: .warning,
                    message: "\(item.name) is below reorder point (\(String(format: "%.1f", item.currentStock)) \(item.unit.abbreviation))",
                    recommendedQuantity: item.reorderQuantity
                ))
            }

            // Check expiration
            if item.isExpired {
                alerts.append(ReorderAlert(
                    id: UUID(),
                    item: item,
                    severity: .critical,
                    message: "\(item.name) has expired",
                    recommendedQuantity: 0
                ))
            } else if item.isExpiringSoon, let days = item.daysUntilExpiration {
                alerts.append(ReorderAlert(
                    id: UUID(),
                    item: item,
                    severity: .warning,
                    message: "\(item.name) expires in \(days) days",
                    recommendedQuantity: 0
                ))
            }
        }

        reorderAlerts = alerts
        return alerts
    }

    /// Calculate optimal reorder quantity based on usage patterns
    func calculateOptimalReorderQuantity(
        item: InventoryItem,
        usageRecords: [UsageRecord],
        leadTimeDays: Int = 7
    ) -> Double {
        // Calculate average daily usage over last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentUsage = usageRecords.filter {
            $0.itemId == item.id && $0.date >= thirtyDaysAgo
        }

        guard !recentUsage.isEmpty else {
            return item.reorderQuantity
        }

        let totalUsage = recentUsage.reduce(0) { $0 + $1.quantity }
        let averageDailyUsage = totalUsage / 30

        // Calculate safety stock (for lead time + buffer)
        let safetyStock = averageDailyUsage * Double(leadTimeDays + 3)

        // Recommended order brings stock to maximum level
        let recommendedOrder = item.maximumStock - item.currentStock + safetyStock

        return max(item.reorderQuantity, recommendedOrder)
    }

    // MARK: - Purchase Orders

    /// Create purchase order for items needing restock
    func createPurchaseOrder(
        supplier: Supplier,
        items: [(item: InventoryItem, quantity: Double)],
        expectedDeliveryDays: Int = 7
    ) -> PurchaseOrder {
        let poNumber = generatePONumber()
        let expectedDelivery = Calendar.current.date(byAdding: .day, value: expectedDeliveryDays, to: Date())

        let poItems = items.map { item, quantity in
            PurchaseOrderItem(
                itemId: item.item.id,
                itemName: item.item.name,
                quantity: quantity,
                unit: item.item.unit,
                costPerUnit: item.item.costPerUnit
            )
        }

        let subtotal = poItems.reduce(0) { $0 + $1.total }
        let tax = subtotal * 0.08 // 8% tax rate
        let shipping = subtotal > 100 ? 0 : 15 // Free shipping over $100
        let total = subtotal + tax + shipping

        return PurchaseOrder(
            poNumber: poNumber,
            supplier: supplier,
            expectedDeliveryDate: expectedDelivery,
            items: poItems,
            subtotal: subtotal,
            tax: tax,
            shipping: shipping,
            total: total
        )
    }

    /// Receive items from purchase order
    func receivePurchaseOrder(
        purchaseOrder: PurchaseOrder,
        receivedItems: [(itemId: UUID, quantity: Double)]
    ) -> (updatedPO: PurchaseOrder, transactions: [StockTransaction]) {
        var updatedPO = purchaseOrder
        var transactions: [StockTransaction] = []

        // Update PO items with received quantities
        for received in receivedItems {
            if let index = updatedPO.items.firstIndex(where: { $0.itemId == received.itemId }) {
                var item = updatedPO.items[index]
                item.receivedQuantity += received.quantity
                updatedPO.items[index] = item
            }
        }

        // Update PO status
        let allReceived = updatedPO.items.allSatisfy { $0.isFullyReceived }
        let someReceived = updatedPO.items.contains { $0.receivedQuantity > 0 }

        if allReceived {
            updatedPO.status = .received
            updatedPO.actualDeliveryDate = Date()
        } else if someReceived {
            updatedPO.status = .partiallyReceived
        }

        return (updatedPO, transactions)
    }

    private func generatePONumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let random = Int.random(in: 1000...9999)
        return "PO-\(dateString)-\(random)"
    }

    // MARK: - Inventory Count

    /// Create inventory count sheet
    func createInventoryCount(items: [InventoryItem], countedBy: String) -> InventoryCount {
        let countItems = items.map { item in
            InventoryCountItem(
                itemId: item.id,
                itemName: item.name,
                systemQuantity: item.currentStock,
                physicalQuantity: item.currentStock, // Start with system quantity
                unit: item.unit,
                costPerUnit: item.costPerUnit
            )
        }

        return InventoryCount(
            countedBy: countedBy,
            items: countItems
        )
    }

    /// Reconcile inventory count and create adjustment transactions
    func reconcileInventoryCount(
        count: InventoryCount,
        items: [InventoryItem]
    ) -> (updatedItems: [InventoryItem], transactions: [StockTransaction]) {
        var updatedItems: [InventoryItem] = []
        var transactions: [StockTransaction] = []

        for countItem in count.items where countItem.variance != 0 {
            guard let item = items.first(where: { $0.id == countItem.itemId }) else { continue }

            var updatedItem = item
            updatedItem.currentStock = countItem.physicalQuantity
            updatedItem.lastCountDate = count.countDate
            updatedItems.append(updatedItem)

            // Create adjustment transaction
            let transaction = StockTransaction(
                itemId: item.id,
                itemName: item.name,
                transactionType: .adjustment,
                quantity: abs(countItem.variance),
                unit: item.unit,
                reference: "Inventory Count",
                notes: "Physical count adjustment. Variance: \(String(format: "%.2f", countItem.variance)) \(item.unit.abbreviation)"
            )
            transactions.append(transaction)
        }

        return (updatedItems, transactions)
    }

    // MARK: - Analytics

    /// Calculate inventory statistics
    func calculateStatistics(items: [InventoryItem], usageRecords: [UsageRecord]) -> InventoryStatistics {
        let totalItems = items.filter { $0.isActive }.count
        let totalValue = items.filter { $0.isActive }.reduce(0) { $0 + $1.totalValue }

        let lowStockItems = items.filter { $0.isActive && $0.stockStatus == .low }.count
        let outOfStockItems = items.filter { $0.isActive && $0.stockStatus == .outOfStock }.count
        let expiringItems = items.filter { $0.isActive && $0.isExpiringSoon }.count
        let expiredItems = items.filter { $0.isActive && $0.isExpired }.count

        let itemsByCategory = Dictionary(grouping: items.filter { $0.isActive }, by: { $0.category })
            .mapValues { $0.count }

        let valueByCategory = Dictionary(grouping: items.filter { $0.isActive }, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.totalValue } }

        // Calculate average days of supply
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let totalDailyUsage = usageRecords.filter { $0.date >= thirtyDaysAgo }
            .reduce(0) { total, record in
                guard let item = items.first(where: { $0.id == record.itemId }) else { return total }
                return total + (record.quantity * item.costPerUnit)
            } / 30

        let averageDaysOfSupply = totalDailyUsage > 0 ? totalValue / totalDailyUsage : 0

        // Calculate turnover rate (simplified)
        let turnoverRate = totalDailyUsage > 0 ? (totalDailyUsage * 365) / totalValue : 0

        return InventoryStatistics(
            totalItems: totalItems,
            totalValue: totalValue,
            lowStockItems: lowStockItems,
            outOfStockItems: outOfStockItems,
            expiringItems: expiringItems,
            expiredItems: expiredItems,
            itemsByCategory: itemsByCategory,
            valueByCategory: valueByCategory,
            averageDaysOfSupply: averageDaysOfSupply,
            turnoverRate: turnoverRate
        )
    }

    /// Calculate cost per service
    func calculateCostPerService(
        serviceId: UUID,
        usageRecords: [UsageRecord],
        items: [InventoryItem]
    ) -> Double {
        let serviceUsage = usageRecords.filter { $0.serviceId == serviceId }

        let totalCost = serviceUsage.reduce(0.0) { total, usage in
            guard let item = items.first(where: { $0.id == usage.itemId }) else { return total }
            return total + (usage.quantity * item.costPerUnit)
        }

        return totalCost
    }

    /// Get items needing attention (low stock, expiring, etc.)
    func getItemsNeedingAttention(items: [InventoryItem]) -> [InventoryItem] {
        items.filter { item in
            item.isActive && (
                item.needsReorder ||
                item.isExpiringSoon ||
                item.isExpired ||
                item.stockStatus == .outOfStock ||
                item.stockStatus == .critical
            )
        }.sorted { item1, item2 in
            // Sort by urgency
            if item1.isExpired != item2.isExpired {
                return item1.isExpired
            }
            if item1.stockStatus == .outOfStock && item2.stockStatus != .outOfStock {
                return true
            }
            if item1.stockStatus == .critical && item2.stockStatus != .critical && item2.stockStatus != .outOfStock {
                return true
            }
            return item1.name < item2.name
        }
    }

    // MARK: - Export

    /// Export inventory report to CSV
    func exportInventoryReport(items: [InventoryItem]) -> String {
        var csv = "SKU,Name,Category,Current Stock,Unit,Status,Value,Supplier,Location,Expiration\n"

        for item in items.sorted(by: { $0.name < $1.name }) {
            let sku = item.sku.replacingOccurrences(of: ",", with: ";")
            let name = item.name.replacingOccurrences(of: ",", with: ";")
            let category = item.category.rawValue
            let stock = String(format: "%.2f", item.currentStock)
            let unit = item.unit.rawValue
            let status = item.stockStatus.rawValue
            let value = String(format: "%.2f", item.totalValue)
            let supplier = item.supplier?.name ?? "N/A"
            let location = item.location.rawValue
            let expiration = item.expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A"

            csv += "\(sku),\(name),\(category),\(stock),\(unit),\(status),\(value),\(supplier),\(location),\(expiration)\n"
        }

        return csv
    }
}

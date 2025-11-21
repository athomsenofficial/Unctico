import Foundation

/// Repository for managing inventory data
@MainActor
class InventoryRepository: ObservableObject {
    static let shared = InventoryRepository()

    @Published var items: [InventoryItem] = []
    @Published var suppliers: [Supplier] = []
    @Published var transactions: [StockTransaction] = []
    @Published var purchaseOrders: [PurchaseOrder] = []
    @Published var inventoryCounts: [InventoryCount] = []
    @Published var usageRecords: [UsageRecord] = []

    private let itemsKey = "unctico_inventory_items"
    private let suppliersKey = "unctico_suppliers"
    private let transactionsKey = "unctico_stock_transactions"
    private let purchaseOrdersKey = "unctico_purchase_orders"
    private let countsKey = "unctico_inventory_counts"
    private let usageKey = "unctico_usage_records"

    init() {
        loadData()
        initializeSampleData()
    }

    // MARK: - Inventory Items

    func addItem(_ item: InventoryItem) {
        items.append(item)
        saveItems()
    }

    func updateItem(_ item: InventoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }

    func deleteItem(_ itemId: UUID) {
        items.removeAll { $0.id == itemId }
        saveItems()
    }

    func getItem(id: UUID) -> InventoryItem? {
        items.first { $0.id == id }
    }

    func getActiveItems() -> [InventoryItem] {
        items.filter { $0.isActive }
    }

    func getItemsByCategory(_ category: InventoryCategory) -> [InventoryItem] {
        items.filter { $0.category == category && $0.isActive }
    }

    func getLowStockItems() -> [InventoryItem] {
        items.filter { $0.isActive && $0.needsReorder }
    }

    func getExpiringItems(withinDays days: Int = 30) -> [InventoryItem] {
        items.filter { item in
            guard item.isActive, let daysUntil = item.daysUntilExpiration else { return false }
            return daysUntil <= days && daysUntil > 0
        }
    }

    func searchItems(query: String) -> [InventoryItem] {
        guard !query.isEmpty else { return getActiveItems() }

        return items.filter { item in
            item.isActive && (
                item.name.localizedCaseInsensitiveContains(query) ||
                item.sku.localizedCaseInsensitiveContains(query) ||
                item.description.localizedCaseInsensitiveContains(query)
            )
        }
    }

    // MARK: - Suppliers

    func addSupplier(_ supplier: Supplier) {
        suppliers.append(supplier)
        saveSuppliers()
    }

    func updateSupplier(_ supplier: Supplier) {
        if let index = suppliers.firstIndex(where: { $0.id == supplier.id }) {
            suppliers[index] = supplier
            saveSuppliers()
        }
    }

    func deleteSupplier(_ supplierId: UUID) {
        suppliers.removeAll { $0.id == supplierId }
        saveSuppliers()
    }

    func getActiveSuppliers() -> [Supplier] {
        suppliers.filter { $0.isActive }
    }

    // MARK: - Stock Transactions

    func addTransaction(_ transaction: StockTransaction) {
        transactions.append(transaction)
        saveTransactions()
    }

    func getTransactions(for itemId: UUID) -> [StockTransaction] {
        transactions.filter { $0.itemId == itemId }
            .sorted { $0.date > $1.date }
    }

    func getTransactions(from startDate: Date, to endDate: Date) -> [StockTransaction] {
        transactions.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }

    func getRecentTransactions(limit: Int = 20) -> [StockTransaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(limit))
    }

    // MARK: - Purchase Orders

    func addPurchaseOrder(_ purchaseOrder: PurchaseOrder) {
        purchaseOrders.append(purchaseOrder)
        savePurchaseOrders()
    }

    func updatePurchaseOrder(_ purchaseOrder: PurchaseOrder) {
        if let index = purchaseOrders.firstIndex(where: { $0.id == purchaseOrder.id }) {
            purchaseOrders[index] = purchaseOrder
            savePurchaseOrders()
        }
    }

    func deletePurchaseOrder(_ purchaseOrderId: UUID) {
        purchaseOrders.removeAll { $0.id == purchaseOrderId }
        savePurchaseOrders()
    }

    func getActivePurchaseOrders() -> [PurchaseOrder] {
        purchaseOrders.filter { $0.status != .received && $0.status != .cancelled }
            .sorted { $0.orderDate > $1.orderDate }
    }

    func getOverduePurchaseOrders() -> [PurchaseOrder] {
        purchaseOrders.filter { $0.isOverdue }
            .sorted { $0.expectedDeliveryDate ?? Date.distantFuture < $1.expectedDeliveryDate ?? Date.distantFuture }
    }

    func getPurchaseOrders(for supplierId: UUID) -> [PurchaseOrder] {
        purchaseOrders.filter { $0.supplier.id == supplierId }
            .sorted { $0.orderDate > $1.orderDate }
    }

    // MARK: - Inventory Counts

    func addInventoryCount(_ count: InventoryCount) {
        inventoryCounts.append(count)
        saveCounts()
    }

    func updateInventoryCount(_ count: InventoryCount) {
        if let index = inventoryCounts.firstIndex(where: { $0.id == count.id }) {
            inventoryCounts[index] = count
            saveCounts()
        }
    }

    func getRecentCounts(limit: Int = 10) -> [InventoryCount] {
        Array(inventoryCounts.sorted { $0.countDate > $1.countDate }.prefix(limit))
    }

    // MARK: - Usage Records

    func addUsageRecord(_ usage: UsageRecord) {
        usageRecords.append(usage)
        saveUsage()
    }

    func getUsageRecords(for itemId: UUID) -> [UsageRecord] {
        usageRecords.filter { $0.itemId == itemId }
            .sorted { $0.date > $1.date }
    }

    func getUsageRecords(from startDate: Date, to endDate: Date) -> [UsageRecord] {
        usageRecords.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }

    func getUsageRecords(for serviceId: UUID) -> [UsageRecord] {
        usageRecords.filter { $0.serviceId == serviceId }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Combined Operations

    /// Record stock in and create transaction
    func recordStockIn(item: InventoryItem, quantity: Double, reference: String = "", notes: String = "") {
        let (updatedItem, transaction) = InventoryService.shared.adjustStock(
            item: item,
            quantity: quantity,
            transactionType: .stockIn,
            reference: reference,
            notes: notes
        )

        updateItem(updatedItem)
        addTransaction(transaction)
    }

    /// Record stock out and create transaction
    func recordStockOut(item: InventoryItem, quantity: Double, reference: String = "", notes: String = "") {
        let (updatedItem, transaction) = InventoryService.shared.adjustStock(
            item: item,
            quantity: quantity,
            transactionType: .stockOut,
            reference: reference,
            notes: notes
        )

        updateItem(updatedItem)
        addTransaction(transaction)
    }

    /// Record usage and create both transaction and usage record
    func recordUsage(
        item: InventoryItem,
        quantity: Double,
        clientId: UUID? = nil,
        clientName: String? = nil,
        serviceId: UUID? = nil,
        serviceName: String? = nil
    ) {
        let (updatedItem, transaction, usageRecord) = InventoryService.shared.recordUsage(
            item: item,
            quantity: quantity,
            clientId: clientId,
            clientName: clientName,
            serviceId: serviceId,
            serviceName: serviceName
        )

        updateItem(updatedItem)
        addTransaction(transaction)
        addUsageRecord(usageRecord)
    }

    /// Receive purchase order and update stock
    func receivePurchaseOrder(
        purchaseOrder: PurchaseOrder,
        receivedItems: [(itemId: UUID, quantity: Double)]
    ) {
        let (updatedPO, transactions) = InventoryService.shared.receivePurchaseOrder(
            purchaseOrder: purchaseOrder,
            receivedItems: receivedItems
        )

        updatePurchaseOrder(updatedPO)

        // Update inventory items
        for received in receivedItems {
            if let item = getItem(id: received.itemId) {
                recordStockIn(
                    item: item,
                    quantity: received.quantity,
                    reference: "PO-\(purchaseOrder.poNumber)",
                    notes: "Received from \(purchaseOrder.supplier.name)"
                )
            }
        }
    }

    /// Reconcile inventory count
    func reconcileInventoryCount(count: InventoryCount) {
        let (updatedItems, transactions) = InventoryService.shared.reconcileInventoryCount(
            count: count,
            items: items
        )

        // Update items
        for item in updatedItems {
            updateItem(item)
        }

        // Add transactions
        for transaction in transactions {
            addTransaction(transaction)
        }

        // Mark count as reconciled
        var reconciledCount = count
        reconciledCount = InventoryCount(
            id: count.id,
            countDate: count.countDate,
            countedBy: count.countedBy,
            items: count.items,
            status: .reconciled,
            notes: count.notes
        )
        updateInventoryCount(reconciledCount)
    }

    // MARK: - Statistics

    func getStatistics() -> InventoryStatistics {
        InventoryService.shared.calculateStatistics(items: items, usageRecords: usageRecords)
    }

    // MARK: - Data Export

    func exportInventoryReport() -> String {
        InventoryService.shared.exportInventoryReport(items: items)
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            items = decoded
        }

        if let data = UserDefaults.standard.data(forKey: suppliersKey),
           let decoded = try? JSONDecoder().decode([Supplier].self, from: data) {
            suppliers = decoded
        }

        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([StockTransaction].self, from: data) {
            transactions = decoded
        }

        if let data = UserDefaults.standard.data(forKey: purchaseOrdersKey),
           let decoded = try? JSONDecoder().decode([PurchaseOrder].self, from: data) {
            purchaseOrders = decoded
        }

        if let data = UserDefaults.standard.data(forKey: countsKey),
           let decoded = try? JSONDecoder().decode([InventoryCount].self, from: data) {
            inventoryCounts = decoded
        }

        if let data = UserDefaults.standard.data(forKey: usageKey),
           let decoded = try? JSONDecoder().decode([UsageRecord].self, from: data) {
            usageRecords = decoded
        }
    }

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }

    private func saveSuppliers() {
        if let encoded = try? JSONEncoder().encode(suppliers) {
            UserDefaults.standard.set(encoded, forKey: suppliersKey)
        }
    }

    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }

    private func savePurchaseOrders() {
        if let encoded = try? JSONEncoder().encode(purchaseOrders) {
            UserDefaults.standard.set(encoded, forKey: purchaseOrdersKey)
        }
    }

    private func saveCounts() {
        if let encoded = try? JSONEncoder().encode(inventoryCounts) {
            UserDefaults.standard.set(encoded, forKey: countsKey)
        }
    }

    private func saveUsage() {
        if let encoded = try? JSONEncoder().encode(usageRecords) {
            UserDefaults.standard.set(encoded, forKey: usageKey)
        }
    }

    // MARK: - Sample Data

    private func initializeSampleData() {
        guard items.isEmpty && suppliers.isEmpty else { return }

        // Sample supplier
        let supplier = Supplier(
            name: "Massage Warehouse",
            contactPerson: "John Smith",
            email: "orders@massagewarehouse.com",
            phone: "(555) 123-4567",
            website: "www.massagewarehouse.com",
            leadTimeDays: 5
        )
        addSupplier(supplier)

        // Sample inventory items
        let sampleItems: [InventoryItem] = [
            InventoryItem(
                name: "Unscented Massage Oil",
                category: .massageOils,
                sku: "MO-001",
                currentStock: 8,
                unit: .bottle,
                minimumStock: 3,
                maximumStock: 20,
                reorderPoint: 5,
                reorderQuantity: 12,
                costPerUnit: 12.99,
                supplier: supplier,
                location: .mainStorage
            ),
            InventoryItem(
                name: "Lavender Essential Oil",
                category: .essentialOils,
                sku: "EO-LAV",
                currentStock: 5,
                unit: .ounce,
                minimumStock: 2,
                maximumStock: 10,
                reorderPoint: 3,
                reorderQuantity: 6,
                costPerUnit: 18.50,
                supplier: supplier,
                location: .cabinet
            ),
            InventoryItem(
                name: "Massage Table Sheets",
                category: .linens,
                sku: "LN-SHT",
                currentStock: 15,
                unit: .piece,
                minimumStock: 10,
                maximumStock: 30,
                reorderPoint: 12,
                reorderQuantity: 20,
                costPerUnit: 8.99,
                supplier: supplier,
                location: .laundry
            ),
            InventoryItem(
                name: "Hot Stone Set",
                category: .equipment,
                sku: "EQ-HST",
                currentStock: 2,
                unit: .set,
                minimumStock: 1,
                maximumStock: 3,
                reorderPoint: 1,
                reorderQuantity: 1,
                costPerUnit: 89.99,
                supplier: supplier,
                location: .treatmentRoom1
            )
        ]

        for item in sampleItems {
            addItem(item)
        }
    }
}

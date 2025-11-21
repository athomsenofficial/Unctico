import SwiftUI

struct InventoryManagementView: View {
    @StateObject private var repository = InventoryRepository.shared
    @StateObject private var inventoryService = InventoryService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                InventoryListView()
                    .tabItem {
                        Label("Items", systemImage: "list.bullet")
                    }
                    .tag(0)
                
                AlertsView()
                    .tabItem {
                        Label("Alerts", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tag(1)
                
                PurchaseOrdersView()
                    .tabItem {
                        Label("Orders", systemImage: "doc.text.fill")
                    }
                    .tag(2)
                
                InventoryStatsView()
                    .tabItem {
                        Label("Reports", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
            }
            .navigationTitle("Inventory")
        }
    }
}

// MARK: - Inventory List View

struct InventoryListView: View {
    @StateObject private var repository = InventoryRepository.shared
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory?
    @State private var showingAddItem = false
    
    var filteredItems: [InventoryItem] {
        var items = repository.getActiveItems()
        
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            items = repository.searchItems(query: searchText)
        }
        
        return items.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(InventoryCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = selectedCategory == category ? nil : category }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            
            List {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "box",
                        description: Text("Add your first inventory item")
                    )
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            InventoryItemRow(item: item)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search inventory")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    Text("\(String(format: "%.1f", item.currentStock)) \(item.unit.abbreviation)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.stockStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(item.stockStatus.color))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", item.totalValue))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Image(systemName: item.stockStatus.icon)
                    .foregroundColor(Color(item.stockStatus.color))
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Alerts View

struct AlertsView: View {
    @StateObject private var repository = InventoryRepository.shared
    @StateObject private var inventoryService = InventoryService.shared
    
    var alerts: [ReorderAlert] {
        inventoryService.generateReorderAlerts(items: repository.items)
    }
    
    var body: some View {
        List {
            if alerts.isEmpty {
                ContentUnavailableView(
                    "No Alerts",
                    systemImage: "checkmark.circle",
                    description: Text("All inventory levels are good")
                )
            } else {
                ForEach(alerts) { alert in
                    AlertRow(alert: alert)
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: ReorderAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.item.name)
                    .font(.headline)
                
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if alert.recommendedQuantity > 0 {
                    Text("Recommended order: \(String(format: "%.1f", alert.recommendedQuantity)) \(alert.item.unit.abbreviation)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Purchase Orders View

struct PurchaseOrdersView: View {
    @StateObject private var repository = InventoryRepository.shared
    @State private var showingNewPO = false
    
    var body: some View {
        List {
            if repository.purchaseOrders.isEmpty {
                ContentUnavailableView(
                    "No Purchase Orders",
                    systemImage: "doc.text",
                    description: Text("Create your first purchase order")
                )
            } else {
                ForEach(repository.purchaseOrders.sorted { $0.orderDate > $1.orderDate }) { po in
                    PurchaseOrderRow(purchaseOrder: po)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewPO = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewPO) {
            Text("Create Purchase Order")
        }
    }
}

struct PurchaseOrderRow: View {
    let purchaseOrder: PurchaseOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(purchaseOrder.poNumber)
                    .font(.headline)
                
                Spacer()
                
                POStatusBadge(status: purchaseOrder.status)
            }
            
            Text(purchaseOrder.supplier.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(purchaseOrder.items.count) items")
                    .font(.caption)
                
                Text("•")
                
                Text(String(format: "$%.2f", purchaseOrder.total))
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let expectedDate = purchaseOrder.expectedDeliveryDate {
                    Text("Due: \(expectedDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(purchaseOrder.isOverdue ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct POStatusBadge: View {
    let status: POStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

// MARK: - Inventory Stats View

struct InventoryStatsView: View {
    @StateObject private var repository = InventoryRepository.shared
    
    var stats: InventoryStatistics {
        repository.getStatistics()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatsCard(
                        title: "Total Items",
                        value: "\(stats.totalItems)",
                        icon: "box.fill",
                        color: .blue
                    )
                    
                    StatsCard(
                        title: "Total Value",
                        value: String(format: "$%.0f", stats.totalValue),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    StatsCard(
                        title: "Low Stock",
                        value: "\(stats.lowStockItems)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                    
                    StatsCard(
                        title: "Out of Stock",
                        value: "\(stats.outOfStockItems)",
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
                .padding()
                
                // Category breakdown
                if !stats.itemsByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Category")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(stats.itemsByCategory.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .frame(width: 30)
                                
                                Text(category.rawValue)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(stats.itemsByCategory[category] ?? 0) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "$%.0f", stats.valueByCategory[category] ?? 0))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct ItemDetailView: View {
    let item: InventoryItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("Details") {
                Text("SKU: \(item.sku)")
                Text("Current Stock: \(String(format: "%.1f", item.currentStock)) \(item.unit.rawValue)")
                Text("Value: \(String(format: "$%.2f", item.totalValue))")
            }
        }
        .navigationTitle(item.name)
    }
}

struct AddInventoryItemView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Text("Add inventory item form")
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    InventoryManagementView()
}

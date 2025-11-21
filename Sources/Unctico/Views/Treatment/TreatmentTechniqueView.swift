import SwiftUI

/// Treatment technique and modality documentation interface
struct TreatmentTechniqueView: View {
    @Binding var techniques: [TreatmentTechniqueRecord]
    @State private var showingAddTechnique = false
    @State private var selectedTechnique: TreatmentTechniqueRecord?
    @State private var filterCategory: TechniqueCategory?

    private var filteredTechniques: [TreatmentTechniqueRecord] {
        if let category = filterCategory {
            return techniques.filter { $0.technique.category == category }
        }
        return techniques
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                categoryFilter

                if filteredTechniques.isEmpty {
                    EmptyTechniqueStateView()
                } else {
                    techniquesList
                }
            }
            .navigationTitle("Treatment Techniques")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTechnique = true
                    } label: {
                        Label("Add Technique", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddTechnique) {
                AddTreatmentTechniqueView { technique in
                    techniques.append(technique)
                    showingAddTechnique = false
                }
            }
            .sheet(item: $selectedTechnique) { technique in
                TechniqueDetailView(technique: technique)
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(
                    title: "All",
                    icon: "list.bullet",
                    color: .blue,
                    isSelected: filterCategory == nil
                ) {
                    filterCategory = nil
                }

                ForEach(TechniqueCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.rawValue,
                        icon: Technique.swedish.icon, // Use first technique's icon for category
                        color: category.color,
                        isSelected: filterCategory == category
                    ) {
                        filterCategory = category
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }

    private var techniquesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTechniques) { technique in
                    TechniqueCard(technique: technique)
                        .onTapGesture {
                            selectedTechnique = technique
                        }
                }
            }
            .padding()
        }
    }
}

struct TechniqueCard: View {
    let technique: TreatmentTechniqueRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: technique.technique.icon)
                .font(.title2)
                .foregroundColor(technique.technique.category.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(technique.technique.rawValue)
                    .font(.headline)

                HStack {
                    Text(technique.bodyAreas.map { $0.rawValue }.joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    Text(technique.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Modalities
                if !technique.modalities.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(technique.modalities.prefix(3), id: \.self) { modality in
                            Image(systemName: modality.icon)
                                .font(.caption)
                                .foregroundColor(modality.color)
                        }
                        if technique.modalities.count > 3 {
                            Text("+\(technique.modalities.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Client response
                HStack(spacing: 4) {
                    Image(systemName: technique.clientResponse.icon)
                        .font(.caption)
                    Text(technique.clientResponse.rawValue)
                        .font(.caption)
                }
                .foregroundColor(technique.clientResponse.color)
            }

            Spacer()

            Circle()
                .fill(technique.pressure.color)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddTreatmentTechniqueView: View {
    let onSave: (TreatmentTechniqueRecord) -> Void

    @State private var selectedTechnique: Technique = .effleurage
    @State private var selectedBodyAreas: Set<BodyLocation> = []
    @State private var duration: Int = 10 // minutes
    @State private var pressure: PressureLevel = .moderate
    @State private var selectedModalities: Set<Modality> = []
    @State private var clientResponse: ClientResponse = .good
    @State private var notes = ""
    @State private var showingBodyAreaPicker = false
    @State private var showingModalityPicker = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Technique") {
                    Picker("Type", selection: $selectedTechnique) {
                        ForEach(TechniqueCategory.allCases, id: \.self) { category in
                            Section(category.rawValue) {
                                ForEach(Technique.allCases.filter { $0.category == category }, id: \.self) { technique in
                                    Label(technique.rawValue, systemImage: technique.icon).tag(technique)
                                }
                            }
                        }
                    }

                    Text(selectedTechnique.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Body Areas") {
                    Button {
                        showingBodyAreaPicker = true
                    } label: {
                        HStack {
                            Text("Select Areas")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedBodyAreas.isEmpty ? "None" : "\(selectedBodyAreas.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !selectedBodyAreas.isEmpty {
                        ForEach(Array(selectedBodyAreas).sorted { $0.rawValue < $1.rawValue }, id: \.self) { area in
                            HStack {
                                Text(area.rawValue)
                                Spacer()
                                Button {
                                    selectedBodyAreas.remove(area)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                Section("Duration & Pressure") {
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 1...120)

                    Picker("Pressure", selection: $pressure) {
                        ForEach(PressureLevel.allCases, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 12, height: 12)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                }

                Section("Modalities (Optional)") {
                    Button {
                        showingModalityPicker = true
                    } label: {
                        HStack {
                            Text("Add Modalities")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedModalities.isEmpty ? "None" : "\(selectedModalities.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !selectedModalities.isEmpty {
                        ForEach(Array(selectedModalities).sorted { $0.rawValue < $1.rawValue }, id: \.self) { modality in
                            HStack {
                                Image(systemName: modality.icon)
                                    .foregroundColor(modality.color)
                                Text(modality.rawValue)
                                Spacer()
                                Button {
                                    selectedModalities.remove(modality)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                Section("Client Response") {
                    Picker("Response", selection: $clientResponse) {
                        ForEach(ClientResponse.allCases, id: \.self) { response in
                            Label(response.rawValue, systemImage: response.icon).tag(response)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Additional observations...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Technique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let record = TreatmentTechniqueRecord(
                            sessionId: UUID(), // Replace with actual session ID
                            technique: selectedTechnique,
                            bodyAreas: Array(selectedBodyAreas),
                            duration: TimeInterval(duration * 60),
                            pressure: pressure,
                            modalities: Array(selectedModalities),
                            clientResponse: clientResponse,
                            notes: notes
                        )
                        onSave(record)
                    }
                    .disabled(selectedBodyAreas.isEmpty)
                }
            }
            .sheet(isPresented: $showingBodyAreaPicker) {
                MultiSelectPicker(
                    title: "Select Body Areas",
                    items: BodyLocation.allCases,
                    selectedItems: $selectedBodyAreas
                )
            }
            .sheet(isPresented: $showingModalityPicker) {
                ModalityMultiSelectPicker(selectedModalities: $selectedModalities)
            }
        }
    }
}

struct MultiSelectPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    let items: [T]
    @Binding var selectedItems: Set<T>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Button {
                        if selectedItems.contains(item) {
                            selectedItems.remove(item)
                        } else {
                            selectedItems.insert(item)
                        }
                    } label: {
                        HStack {
                            Text(item.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedItems.contains(item) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ModalityMultiSelectPicker: View {
    @Binding var selectedModalities: Set<Modality>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(ModalityCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(Modality.allCases.filter { $0.category == category }, id: \.self) { modality in
                            Button {
                                if selectedModalities.contains(modality) {
                                    selectedModalities.remove(modality)
                                } else {
                                    selectedModalities.insert(modality)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: modality.icon)
                                        .foregroundColor(modality.color)
                                    Text(modality.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedModalities.contains(modality) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Modalities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TechniqueDetailView: View {
    let technique: TreatmentTechniqueRecord
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: technique.technique.icon)
                            .font(.largeTitle)
                            .foregroundColor(technique.technique.category.color)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(technique.technique.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(technique.technique.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Description
                    DetailCard(title: "Technique Description") {
                        Text(technique.technique.description)
                            .font(.body)
                    }

                    // Body areas
                    DetailCard(title: "Areas Treated") {
                        ForEach(technique.bodyAreas, id: \.self) { area in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text(area.rawValue)
                            }
                        }
                    }

                    // Duration & Pressure
                    HStack(spacing: 12) {
                        DetailCard(title: "Duration") {
                            Text(technique.formattedDuration)
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        DetailCard(title: "Pressure") {
                            HStack {
                                Circle()
                                    .fill(technique.pressure.color)
                                    .frame(width: 16, height: 16)
                                Text(technique.pressure.rawValue)
                                    .font(.headline)
                            }
                        }
                    }

                    // Modalities
                    if !technique.modalities.isEmpty {
                        DetailCard(title: "Modalities Used") {
                            ForEach(technique.modalities, id: \.self) { modality in
                                HStack {
                                    Image(systemName: modality.icon)
                                        .foregroundColor(modality.color)
                                    Text(modality.rawValue)
                                }
                            }
                        }
                    }

                    // Client response
                    DetailCard(title: "Client Response") {
                        HStack {
                            Image(systemName: technique.clientResponse.icon)
                                .foregroundColor(technique.clientResponse.color)
                            Text(technique.clientResponse.rawValue)
                                .font(.headline)
                                .foregroundColor(technique.clientResponse.color)
                        }
                    }

                    // Notes
                    if !technique.notes.isEmpty {
                        DetailCard(title: "Notes") {
                            Text(technique.notes)
                        }
                    }

                    // Timestamp
                    DetailCard(title: "Recorded") {
                        Text(technique.timestamp, style: .date)
                        Text(technique.timestamp, style: .time)
                    }
                }
                .padding()
            }
            .navigationTitle("Technique Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct EmptyTechniqueStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Techniques Recorded")
                .font(.headline)

            Text("Document treatment techniques to track what works best")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var techniques: [TreatmentTechniqueRecord] = [
            TreatmentTechniqueRecord(
                sessionId: UUID(),
                technique: .deepTissue,
                bodyAreas: [.back, .neck, .shoulder],
                duration: 1200,
                pressure: .firm,
                modalities: [.hotStone, .warmTowels],
                clientResponse: .excellent,
                notes: "Client reported significant relief"
            )
        ]

        var body: some View {
            TreatmentTechniqueView(techniques: $techniques)
        }
    }

    return PreviewWrapper()
}

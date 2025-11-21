import SwiftUI

/// Searchable ICD-10 code selector for diagnosis documentation
struct ICD10CodeSelectorView: View {
    @Binding var selectedCodes: [ICD10Code]
    @State private var searchText = ""
    @State private var selectedCategory: ICD10Category?
    @State private var showingCommonOnly = true
    @Environment(\.dismiss) var dismiss

    private var filteredCodes: [ICD10Code] {
        var codes = showingCommonOnly ? ICD10Code.commonCodes : ICD10Code.commonMassageTherapyCodes

        if let category = selectedCategory {
            codes = codes.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            codes = ICD10Code.search(searchText)
        }

        return codes.sorted { $0.code < $1.code }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter controls
                filterControls

                // Selected codes
                if !selectedCodes.isEmpty {
                    selectedCodesSection
                }

                // Code list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredCodes) { code in
                            CodeRow(
                                code: code,
                                isSelected: selectedCodes.contains(where: { $0.id == code.id })
                            ) {
                                toggleSelection(code)
                            }
                        }

                        if filteredCodes.isEmpty {
                            EmptySearchResultsView(searchText: searchText)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ICD-10 Codes")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by code or description")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
            // Common vs All toggle
            Picker("Filter", selection: $showingCommonOnly) {
                Text("Common").tag(true)
                Text("All Codes").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "All",
                        icon: "list.bullet",
                        color: .blue,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(ICD10Category.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var selectedCodesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected Codes (\(selectedCodes.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button("Clear All") {
                    selectedCodes.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedCodes) { code in
                        SelectedCodeChip(code: code) {
                            selectedCodes.removeAll { $0.id == code.id }
                        }
                    }
                }
                .padding(.horizontal)
            }

            Divider()
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func toggleSelection(_ code: ICD10Code) {
        if let index = selectedCodes.firstIndex(where: { $0.id == code.id }) {
            selectedCodes.remove(at: index)
        } else {
            selectedCodes.append(code)
        }
    }
}

struct CodeRow: View {
    let code: ICD10Code
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: code.category.icon)
                    .font(.title3)
                    .foregroundColor(code.category.color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(code.code)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(code.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    if !code.synonyms.isEmpty {
                        Text(code.synonyms.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding()
            .background(isSelected ? code.category.color.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? code.category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CategoryChip: View {
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

struct SelectedCodeChip: View {
    let code: ICD10Code
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(code.code)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(code.category.color.opacity(0.2))
        .foregroundColor(code.category.color)
        .cornerRadius(12)
    }
}

struct EmptySearchResultsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No codes found")
                .font(.headline)

            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

// MARK: - Code Detail View

struct ICD10CodeDetailView: View {
    let code: ICD10Code
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Code and category
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(code.code)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack {
                                Image(systemName: code.category.icon)
                                    .foregroundColor(code.category.color)

                                Text(code.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if code.isCommon {
                            Text("Common")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(code.description)
                            .font(.body)
                    }

                    // Synonyms
                    if !code.synonyms.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Also known as")
                                .font(.headline)

                            ForEach(code.synonyms, id: \.self) { synonym in
                                Text("• \(synonym)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Usage notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usage Notes")
                            .font(.headline)

                        Text(usageNotes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Code Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var usageNotes: String {
        switch code.category {
        case .pain:
            return "Used when documenting pain complaints. Include location and severity in clinical notes."
        case .musculoskeletal:
            return "Appropriate for muscle, bone, and joint conditions. Document specific findings in SOAP notes."
        case .injury:
            return "Used for acute injuries and strains. Specify initial encounter vs. subsequent encounter."
        case .neurologicalDisorders:
            return "For nerve-related conditions. May require physician referral in some cases."
        case .stressRelated:
            return "Used for stress and anxiety-related conditions. Consider complementary referrals."
        case .postural:
            return "For postural imbalances and related conditions. Document postural assessment findings."
        case .rehabilitation:
            return "Appropriate for post-injury or post-surgical rehabilitation care."
        case .circulatory:
            return "For circulatory conditions. Use caution and obtain physician clearance when needed."
        case .other:
            return "General medical codes. Ensure appropriate documentation of the condition."
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedCodes: [ICD10Code] = []

        var body: some View {
            ICD10CodeSelectorView(selectedCodes: $selectedCodes)
        }
    }

    return PreviewWrapper()
}

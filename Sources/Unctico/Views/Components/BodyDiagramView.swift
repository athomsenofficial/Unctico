import SwiftUI

/// Interactive body diagram for annotating pain and treatment areas
struct BodyDiagramView: View {
    @Binding var annotations: [BodyDiagramAnnotation]
    @State private var selectedAnnotationType: BodyDiagramAnnotation.AnnotationType = .pain
    @State private var selectedSeverity: Int = 5
    @State private var showingAnnotationDetail: BodyDiagramAnnotation? = nil
    @State private var viewSide: BodySide = .front
    let isEditable: Bool

    enum BodySide {
        case front, back
    }

    init(annotations: Binding<[BodyDiagramAnnotation]>, isEditable: Bool = true) {
        self._annotations = annotations
        self.isEditable = isEditable
    }

    var body: some View {
        VStack(spacing: 16) {
            // Side toggle
            Picker("View", selection: $viewSide) {
                Text("Front").tag(BodySide.front)
                Text("Back").tag(BodySide.back)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Body diagram canvas
            GeometryReader { geometry in
                ZStack {
                    // Body outline
                    BodyOutlineView(side: viewSide)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)

                    // Annotations
                    ForEach(annotations) { annotation in
                        AnnotationMarker(
                            annotation: annotation,
                            geometry: geometry
                        )
                        .onTapGesture {
                            showingAnnotationDetail = annotation
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .contentShape(Rectangle())
                .gesture(
                    isEditable ? DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            addAnnotation(at: value.location, in: geometry.size)
                        } : nil
                )
            }
            .frame(height: 500)

            if isEditable {
                // Annotation controls
                VStack(spacing: 12) {
                    Text("Tap on body to add annotation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Annotation type selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BodyDiagramAnnotation.AnnotationType.allCases, id: \.self) { type in
                                AnnotationTypeButton(
                                    type: type,
                                    isSelected: selectedAnnotationType == type,
                                    action: { selectedAnnotationType = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Severity slider
                    VStack(spacing: 4) {
                        HStack {
                            Text("Severity")
                                .font(.subheadline)
                            Spacer()
                            Text("\(selectedSeverity)/10")
                                .font(.subheadline)
                                .bold()
                        }

                        Slider(value: Binding(
                            get: { Double(selectedSeverity) },
                            set: { selectedSeverity = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                    .padding(.horizontal)

                    // Clear all button
                    if !annotations.isEmpty {
                        Button(action: { annotations.removeAll() }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Annotations")
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }

            // Annotations legend
            if !annotations.isEmpty {
                AnnotationsLegendView(annotations: annotations)
            }
        }
        .sheet(item: $showingAnnotationDetail) { annotation in
            AnnotationDetailSheet(
                annotation: annotation,
                onDelete: {
                    annotations.removeAll { $0.id == annotation.id }
                    showingAnnotationDetail = nil
                },
                onUpdate: { updated in
                    if let index = annotations.firstIndex(where: { $0.id == updated.id }) {
                        annotations[index] = updated
                    }
                    showingAnnotationDetail = nil
                }
            )
        }
    }

    private func addAnnotation(at location: CGPoint, in size: CGSize) {
        let normalizedPoint = CGPoint(
            x: location.x / size.width,
            y: location.y / size.height
        )

        let annotation = BodyDiagramAnnotation(
            point: normalizedPoint,
            annotationType: selectedAnnotationType,
            severity: selectedSeverity
        )

        annotations.append(annotation)
    }
}

struct BodyOutlineView: Shape {
    let side: BodyDiagramView.BodySide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        if side == .front {
            // Simplified front body outline
            // Head
            path.addEllipse(in: CGRect(
                x: width * 0.4,
                y: height * 0.02,
                width: width * 0.2,
                height: height * 0.08
            ))

            // Neck
            path.move(to: CGPoint(x: width * 0.45, y: height * 0.1))
            path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.14))
            path.move(to: CGPoint(x: width * 0.55, y: height * 0.1))
            path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.14))

            // Torso
            path.move(to: CGPoint(x: width * 0.3, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.5))
            path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.52))
            path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.6))

            path.move(to: CGPoint(x: width * 0.7, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.5))
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.52))
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.6))

            // Arms
            path.move(to: CGPoint(x: width * 0.3, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.25))
            path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.45))

            path.move(to: CGPoint(x: width * 0.7, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
            path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.45))

            // Legs
            path.move(to: CGPoint(x: width * 0.42, y: height * 0.6))
            path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.95))

            path.move(to: CGPoint(x: width * 0.58, y: height * 0.6))
            path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.95))
        } else {
            // Simplified back body outline
            // Head
            path.addEllipse(in: CGRect(
                x: width * 0.4,
                y: height * 0.02,
                width: width * 0.2,
                height: height * 0.08
            ))

            // Neck & spine
            path.move(to: CGPoint(x: width * 0.5, y: height * 0.1))
            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))

            // Back outline
            path.move(to: CGPoint(x: width * 0.3, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.5))
            path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.52))
            path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.6))

            path.move(to: CGPoint(x: width * 0.7, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.5))
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.52))
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.6))

            // Arms
            path.move(to: CGPoint(x: width * 0.3, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.25))
            path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.45))

            path.move(to: CGPoint(x: width * 0.7, y: height * 0.14))
            path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
            path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.45))

            // Legs
            path.move(to: CGPoint(x: width * 0.42, y: height * 0.6))
            path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.95))

            path.move(to: CGPoint(x: width * 0.58, y: height * 0.6))
            path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.95))
        }

        return path
    }
}

struct AnnotationMarker: View {
    let annotation: BodyDiagramAnnotation
    let geometry: GeometryProxy

    var position: CGPoint {
        CGPoint(
            x: annotation.point.x * geometry.size.width,
            y: annotation.point.y * geometry.size.height
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(annotation.annotationType.color.opacity(0.6))
                .frame(width: CGFloat(annotation.severity * 3 + 15), height: CGFloat(annotation.severity * 3 + 15))

            Image(systemName: annotation.annotationType.icon)
                .font(.caption)
                .foregroundColor(.white)
        }
        .position(position)
    }
}

struct AnnotationTypeButton: View {
    let type: BodyDiagramAnnotation.AnnotationType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(type.rawValue)
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? type.color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct AnnotationsLegendView: View {
    let annotations: [BodyDiagramAnnotation]

    var groupedAnnotations: [BodyDiagramAnnotation.AnnotationType: [BodyDiagramAnnotation]] {
        Dictionary(grouping: annotations, by: { $0.annotationType })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Annotations (\(annotations.count))")
                .font(.headline)

            ForEach(Array(groupedAnnotations.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { type in
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)

                    Text(type.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Text("\(groupedAnnotations[type]?.count ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AnnotationDetailSheet: View {
    let annotation: BodyDiagramAnnotation
    let onDelete: () -> Void
    let onUpdate: (BodyDiagramAnnotation) -> Void

    @State private var notes: String
    @State private var severity: Int
    @Environment(\.dismiss) var dismiss

    init(annotation: BodyDiagramAnnotation, onDelete: @escaping () -> Void, onUpdate: @escaping (BodyDiagramAnnotation) -> Void) {
        self.annotation = annotation
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _notes = State(initialValue: annotation.notes)
        _severity = State(initialValue: annotation.severity)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    HStack {
                        Image(systemName: annotation.annotationType.icon)
                            .foregroundColor(annotation.annotationType.color)
                        Text(annotation.annotationType.rawValue)
                            .font(.headline)
                    }
                }

                Section("Severity") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Level")
                            Spacer()
                            Text("\(severity)/10")
                                .bold()
                        }
                        Slider(value: Binding(
                            get: { Double(severity) },
                            set: { severity = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                }

                Section("Notes") {
                    TextField("Add notes about this area...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Created") {
                    Text(annotation.timestamp, style: .date)
                    Text(annotation.timestamp, style: .time)
                }

                Section {
                    Button(role: .destructive, action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Annotation")
                        }
                    }
                }
            }
            .navigationTitle("Annotation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = BodyDiagramAnnotation(
                            id: annotation.id,
                            point: annotation.point,
                            annotationType: annotation.annotationType,
                            severity: severity,
                            notes: notes,
                            timestamp: annotation.timestamp
                        )
                        onUpdate(updated)
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var annotations: [BodyDiagramAnnotation] = [
            BodyDiagramAnnotation(
                point: CGPoint(x: 0.5, y: 0.3),
                annotationType: .pain,
                severity: 8,
                notes: "Severe pain in neck area"
            ),
            BodyDiagramAnnotation(
                point: CGPoint(x: 0.4, y: 0.4),
                annotationType: .tension,
                severity: 6,
                notes: "Muscle tension in upper back"
            )
        ]

        var body: some View {
            BodyDiagramView(annotations: $annotations)
                .padding()
        }
    }

    return PreviewWrapper()
}

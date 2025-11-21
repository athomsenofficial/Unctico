import SwiftUI

/// Range of Motion (ROM) measurement tool with digital goniometer
struct ROMMeasurementView: View {
    @Binding var measurements: [ROMMeasurement]
    @State private var showingAddMeasurement = false
    @State private var selectedMeasurement: ROMMeasurement?
    @State private var selectedJoint: Joint = .shoulder

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if measurements.isEmpty {
                    EmptyROMStateView()
                } else {
                    measurementsList
                }
            }
            .navigationTitle("ROM Assessment")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMeasurement = true
                    } label: {
                        Label("Add Measurement", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeasurement) {
                AddROMMeasurementView { measurement in
                    measurements.append(measurement)
                    showingAddMeasurement = false
                }
            }
            .sheet(item: $selectedMeasurement) { measurement in
                ROMMeasurementDetailView(
                    measurement: measurement,
                    onUpdate: { updated in
                        if let index = measurements.firstIndex(where: { $0.id == updated.id }) {
                            measurements[index] = updated
                        }
                        selectedMeasurement = nil
                    },
                    onDelete: {
                        measurements.removeAll { $0.id == measurement.id }
                        selectedMeasurement = nil
                    }
                )
            }
        }
    }

    private var measurementsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(measurements) { measurement in
                    ROMMeasurementCard(measurement: measurement)
                        .onTapGesture {
                            selectedMeasurement = measurement
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - ROM Measurement Model

struct ROMMeasurement: Identifiable, Codable {
    let id: UUID
    let joint: Joint
    let movement: Movement
    var degrees: Int
    var pain: Int? // 0-10 scale
    var endFeel: EndFeel?
    var limitation: LimitationType?
    var notes: String
    let measuredDate: Date
    let side: BodySide

    init(
        id: UUID = UUID(),
        joint: Joint,
        movement: Movement,
        degrees: Int,
        pain: Int? = nil,
        endFeel: EndFeel? = nil,
        limitation: LimitationType? = nil,
        notes: String = "",
        measuredDate: Date = Date(),
        side: BodySide = .bilateral
    ) {
        self.id = id
        self.joint = joint
        self.movement = movement
        self.degrees = degrees
        self.pain = pain
        self.endFeel = endFeel
        self.limitation = limitation
        self.notes = notes
        self.measuredDate = measuredDate
        self.side = side
    }

    var isWithinNormalRange: Bool {
        let normal = joint.normalRange(for: movement)
        return degrees >= normal.lowerBound && degrees <= normal.upperBound
    }

    var percentageOfNormal: Double {
        let normal = joint.normalRange(for: movement)
        let midpoint = (normal.lowerBound + normal.upperBound) / 2
        return (Double(degrees) / Double(midpoint)) * 100
    }

    var status: ROMStatus {
        if isWithinNormalRange {
            return .normal
        } else if degrees < joint.normalRange(for: movement).lowerBound {
            return .limited
        } else {
            return .hypermobile
        }
    }
}

enum ROMStatus: String {
    case normal = "Normal"
    case limited = "Limited"
    case hypermobile = "Hypermobile"

    var color: Color {
        switch self {
        case .normal: return .green
        case .limited: return .orange
        case .hypermobile: return .yellow
        }
    }
}

enum Joint: String, Codable, CaseIterable {
    case neck = "Neck (Cervical)"
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case wrist = "Wrist"
    case hip = "Hip"
    case knee = "Knee"
    case ankle = "Ankle"
    case spine = "Spine (Thoracic/Lumbar)"

    var icon: String {
        switch self {
        case .neck: return "person.crop.circle"
        case .shoulder: return "figure.arms.open"
        case .elbow: return "figure.flexibility"
        case .wrist: return "hand.raised"
        case .hip: return "figure.walk"
        case .knee: return "figure.run"
        case .ankle: return "figure.walk.circle"
        case .spine: return "figure.stand"
        }
    }

    var movements: [Movement] {
        switch self {
        case .neck:
            return [.flexion, .extension, .lateralFlexionRight, .lateralFlexionLeft, .rotationRight, .rotationLeft]
        case .shoulder:
            return [.flexion, .extension, .abduction, .adduction, .internalRotation, .externalRotation]
        case .elbow:
            return [.flexion, .extension, .pronation, .supination]
        case .wrist:
            return [.flexion, .extension, .radialDeviation, .ulnarDeviation]
        case .hip:
            return [.flexion, .extension, .abduction, .adduction, .internalRotation, .externalRotation]
        case .knee:
            return [.flexion, .extension]
        case .ankle:
            return [.plantarFlexion, .dorsiflexion, .inversion, .eversion]
        case .spine:
            return [.flexion, .extension, .lateralFlexionRight, .lateralFlexionLeft, .rotationRight, .rotationLeft]
        }
    }

    func normalRange(for movement: Movement) -> ClosedRange<Int> {
        switch (self, movement) {
        // Neck
        case (.neck, .flexion): return 40...60
        case (.neck, .extension): return 50...70
        case (.neck, .lateralFlexionLeft), (.neck, .lateralFlexionRight): return 35...45
        case (.neck, .rotationLeft), (.neck, .rotationRight): return 60...80

        // Shoulder
        case (.shoulder, .flexion): return 160...180
        case (.shoulder, .extension): return 50...60
        case (.shoulder, .abduction): return 170...180
        case (.shoulder, .adduction): return 30...50
        case (.shoulder, .internalRotation): return 60...100
        case (.shoulder, .externalRotation): return 80...90

        // Elbow
        case (.elbow, .flexion): return 140...150
        case (.elbow, .extension): return 0...10
        case (.elbow, .pronation): return 75...90
        case (.elbow, .supination): return 80...90

        // Wrist
        case (.wrist, .flexion): return 70...90
        case (.wrist, .extension): return 60...80
        case (.wrist, .radialDeviation): return 15...25
        case (.wrist, .ulnarDeviation): return 30...40

        // Hip
        case (.hip, .flexion): return 110...125
        case (.hip, .extension): return 10...30
        case (.hip, .abduction): return 40...50
        case (.hip, .adduction): return 20...30
        case (.hip, .internalRotation): return 30...40
        case (.hip, .externalRotation): return 40...50

        // Knee
        case (.knee, .flexion): return 130...140
        case (.knee, .extension): return 0...10

        // Ankle
        case (.ankle, .plantarFlexion): return 40...50
        case (.ankle, .dorsiflexion): return 15...20
        case (.ankle, .inversion): return 30...35
        case (.ankle, .eversion): return 15...20

        // Spine
        case (.spine, .flexion): return 70...90
        case (.spine, .extension): return 20...30
        case (.spine, .lateralFlexionLeft), (.spine, .lateralFlexionRight): return 25...35
        case (.spine, .rotationLeft), (.spine, .rotationRight): return 35...45

        default: return 0...180
        }
    }
}

enum Movement: String, Codable, CaseIterable {
    case flexion = "Flexion"
    case extension = "Extension"
    case abduction = "Abduction"
    case adduction = "Adduction"
    case internalRotation = "Internal Rotation"
    case externalRotation = "External Rotation"
    case lateralFlexionRight = "Lateral Flexion (Right)"
    case lateralFlexionLeft = "Lateral Flexion (Left)"
    case rotationRight = "Rotation (Right)"
    case rotationLeft = "Rotation (Left)"
    case pronation = "Pronation"
    case supination = "Supination"
    case radialDeviation = "Radial Deviation"
    case ulnarDeviation = "Ulnar Deviation"
    case plantarFlexion = "Plantar Flexion"
    case dorsiflexion = "Dorsiflexion"
    case inversion = "Inversion"
    case eversion = "Eversion"
}

enum EndFeel: String, Codable, CaseIterable {
    case bony = "Bony (Hard)"
    case capsular = "Capsular (Firm)"
    case soft = "Soft Tissue"
    case muscular = "Muscular"
    case empty = "Empty (Pain)"
    case springy = "Springy Block"

    var description: String {
        switch self {
        case .bony: return "Hard stop, bone-to-bone contact"
        case .capsular: return "Firm, leathery resistance"
        case .soft: return "Soft tissue approximation"
        case .muscular: return "Muscle tension limiting"
        case .empty: return "Pain prevents further motion"
        case .springy: return "Springy rebound, possible cartilage"
        }
    }
}

enum LimitationType: String, Codable, CaseIterable {
    case pain = "Pain"
    case stiffness = "Stiffness"
    case weakness = "Weakness"
    case apprehension = "Apprehension"
    case mechanical = "Mechanical Block"
}

enum BodySide: String, Codable, CaseIterable {
    case left = "Left"
    case right = "Right"
    case bilateral = "Bilateral"
}

// MARK: - Supporting Views

struct ROMMeasurementCard: View {
    let measurement: ROMMeasurement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: measurement.joint.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(measurement.joint.rawValue)
                        .font(.headline)

                    Text(measurement.side.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                Text(measurement.movement.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let pain = measurement.pain, pain > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Pain: \(pain)/10")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(measurement.degrees)°")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(measurement.status.color)

                Text(measurement.status.rawValue)
                    .font(.caption)
                    .foregroundColor(measurement.status.color)

                let normal = measurement.joint.normalRange(for: measurement.movement)
                Text("Normal: \(normal.lowerBound)-\(normal.upperBound)°")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddROMMeasurementView: View {
    let onSave: (ROMMeasurement) -> Void

    @State private var selectedJoint: Joint = .shoulder
    @State private var selectedMovement: Movement = .flexion
    @State private var selectedSide: BodySide = .right
    @State private var degrees: Int = 90
    @State private var pain: Int = 0
    @State private var endFeel: EndFeel?
    @State private var limitation: LimitationType?
    @State private var notes = ""
    @Environment(\.dismiss) var dismiss

    private var normalRange: ClosedRange<Int> {
        selectedJoint.normalRange(for: selectedMovement)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Joint") {
                    Picker("Joint", selection: $selectedJoint) {
                        ForEach(Joint.allCases, id: \.self) { joint in
                            Label(joint.rawValue, systemImage: joint.icon).tag(joint)
                        }
                    }

                    Picker("Side", selection: $selectedSide) {
                        ForEach(BodySide.allCases, id: \.self) { side in
                            Text(side.rawValue).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Movement") {
                    Picker("Type", selection: $selectedMovement) {
                        ForEach(selectedJoint.movements, id: \.self) { movement in
                            Text(movement.rawValue).tag(movement)
                        }
                    }

                    HStack {
                        Text("Normal Range")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(normalRange.lowerBound)° - \(normalRange.upperBound)°")
                            .fontWeight(.medium)
                    }
                }

                Section("Measurement") {
                    VStack(spacing: 16) {
                        // Degrees slider with visual indicator
                        VStack(spacing: 8) {
                            HStack {
                                Text("Degrees")
                                Spacer()
                                Text("\(degrees)°")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(statusColor)
                            }

                            Slider(value: Binding(
                                get: { Double(degrees) },
                                set: { degrees = Int($0) }
                            ), in: 0...180, step: 5)

                            // Visual range indicator
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)

                                    // Normal range
                                    Rectangle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(
                                            width: geometry.size.width * CGFloat(normalRange.upperBound - normalRange.lowerBound) / 180,
                                            height: 8
                                        )
                                        .cornerRadius(4)
                                        .offset(x: geometry.size.width * CGFloat(normalRange.lowerBound) / 180)

                                    // Current position
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 16, height: 16)
                                        .offset(x: geometry.size.width * CGFloat(degrees) / 180 - 8)
                                }
                            }
                            .frame(height: 16)

                            HStack {
                                Text("0°")
                                    .font(.caption)
                                Spacer()
                                Text("90°")
                                    .font(.caption)
                                Spacer()
                                Text("180°")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        // Pain scale
                        VStack(spacing: 8) {
                            HStack {
                                Text("Pain During Movement")
                                Spacer()
                                Text("\(pain)/10")
                                    .fontWeight(.medium)
                                    .foregroundColor(pain > 0 ? .orange : .secondary)
                            }

                            HStack(spacing: 4) {
                                ForEach(0...10, id: \.self) { value in
                                    Button {
                                        pain = value
                                    } label: {
                                        Text("\(value)")
                                            .font(.caption)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(pain == value ? Color.orange : Color(.systemGray5))
                                            .foregroundColor(pain == value ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Assessment") {
                    Picker("End Feel", selection: $endFeel) {
                        Text("Not assessed").tag(nil as EndFeel?)
                        ForEach(EndFeel.allCases, id: \.self) { feel in
                            Text(feel.rawValue).tag(feel as EndFeel?)
                        }
                    }

                    if let feel = endFeel {
                        Text(feel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Picker("Limitation", selection: $limitation) {
                        Text("No limitation").tag(nil as LimitationType?)
                        ForEach(LimitationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as LimitationType?)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New ROM Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let measurement = ROMMeasurement(
                            joint: selectedJoint,
                            movement: selectedMovement,
                            degrees: degrees,
                            pain: pain > 0 ? pain : nil,
                            endFeel: endFeel,
                            limitation: limitation,
                            notes: notes,
                            side: selectedSide
                        )
                        onSave(measurement)
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        if degrees >= normalRange.lowerBound && degrees <= normalRange.upperBound {
            return .green
        } else if degrees < normalRange.lowerBound {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct ROMMeasurementDetailView: View {
    let measurement: ROMMeasurement
    let onUpdate: (ROMMeasurement) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: measurement.joint.icon)
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(measurement.joint.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("\(measurement.movement.rawValue) - \(measurement.side.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Measured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(measurement.degrees)°")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(measurement.status.color)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Normal Range")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                let normal = measurement.joint.normalRange(for: measurement.movement)
                                Text("\(normal.lowerBound)-\(normal.upperBound)°")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }

                        HStack {
                            Text(measurement.status.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(measurement.status.color.opacity(0.2))
                                .foregroundColor(measurement.status.color)
                                .cornerRadius(8)

                            Text("\(Int(measurement.percentageOfNormal))% of normal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Details
                    if let pain = measurement.pain {
                        DetailSection(title: "Pain Level") {
                            HStack {
                                ForEach(1...10, id: \.self) { level in
                                    Circle()
                                        .fill(level <= pain ? Color.orange : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                                Text("\(pain)/10")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    if let endFeel = measurement.endFeel {
                        DetailSection(title: "End Feel") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(endFeel.rawValue)
                                    .font(.headline)
                                Text(endFeel.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if let limitation = measurement.limitation {
                        DetailSection(title: "Limitation") {
                            Text(limitation.rawValue)
                                .font(.headline)
                        }
                    }

                    if !measurement.notes.isEmpty {
                        DetailSection(title: "Notes") {
                            Text(measurement.notes)
                                .font(.body)
                        }
                    }

                    DetailSection(title: "Measured On") {
                        Text(measurement.measuredDate, style: .date)
                            .font(.headline)
                    }
                }
                .padding()
            }
            .navigationTitle("ROM Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .destructive) {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
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

struct EmptyROMStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.flexibility")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No ROM Measurements")
                .font(.headline)

            Text("Tap + to add your first range of motion measurement")
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
        @State private var measurements: [ROMMeasurement] = [
            ROMMeasurement(
                joint: .shoulder,
                movement: .flexion,
                degrees: 150,
                pain: 3,
                endFeel: .capsular,
                limitation: .pain,
                notes: "Limited by pain, improving from last week",
                side: .right
            )
        ]

        var body: some View {
            ROMMeasurementView(measurements: $measurements)
        }
    }

    return PreviewWrapper()
}

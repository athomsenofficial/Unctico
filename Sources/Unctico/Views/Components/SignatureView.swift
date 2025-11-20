import SwiftUI

/// Signature capture view for digital signing
struct SignatureView: View {
    @Binding var signatureImage: UIImage?
    @State private var currentDrawing = Drawing()
    @State private var drawings: [Drawing] = []
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign below")
                .font(.headline)
                .foregroundColor(.secondary)

            // Signature canvas
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    )

                Canvas { context, size in
                    for drawing in drawings {
                        var path = Path()
                        if let firstPoint = drawing.points.first {
                            path.move(to: firstPoint)
                            for point in drawing.points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        context.stroke(
                            path,
                            with: .color(.black),
                            lineWidth: 2
                        )
                    }

                    // Draw current stroke
                    if !currentDrawing.points.isEmpty {
                        var path = Path()
                        path.move(to: currentDrawing.points[0])
                        for point in currentDrawing.points.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(
                            path,
                            with: .color(.black),
                            lineWidth: 2
                        )
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentDrawing.points.append(value.location)
                        }
                        .onEnded { _ in
                            drawings.append(currentDrawing)
                            currentDrawing = Drawing()
                            updateSignatureImage()
                        }
                )
            }
            .frame(height: 200)
            .padding()

            // Action buttons
            HStack(spacing: 16) {
                Button(action: clearSignature) {
                    Label("Clear", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }

                Button(action: updateSignatureImage) {
                    Label("Done", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(drawings.isEmpty)
            }
            .padding(.horizontal)
        }
    }

    private func clearSignature() {
        drawings = []
        currentDrawing = Drawing()
        signatureImage = nil
    }

    private func updateSignatureImage() {
        let renderer = ImageRenderer(content:
            Canvas { context, size in
                for drawing in drawings {
                    var path = Path()
                    if let firstPoint = drawing.points.first {
                        path.move(to: firstPoint)
                        for point in drawing.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(
                        path,
                        with: .color(.black),
                        lineWidth: 2
                    )
                }
            }
            .frame(width: 400, height: 200)
            .background(.white)
        )

        if let uiImage = renderer.uiImage {
            signatureImage = uiImage
        }
    }
}

struct Drawing {
    var points: [CGPoint] = []
}

/// Signature display view (for showing saved signatures)
struct SignatureDisplayView: View {
    let signatureData: Data?

    var body: some View {
        Group {
            if let data = signatureData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text("No signature")
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var signature: UIImage?

        var body: some View {
            SignatureView(signatureImage: $signature)
                .padding()
        }
    }

    return PreviewWrapper()
}

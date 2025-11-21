import SwiftUI
import PencilKit

/// Digital signature capture view using PencilKit
struct SignaturePadView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var signatureData: Data?

    @State private var canvasView = PKCanvasView()
    @State private var showingClearAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Sign in the box below")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Use your finger or Apple Pencil to sign")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))

                // Signature Canvas
                SignatureCanvas(canvasView: $canvasView)
                    .border(Color.gray.opacity(0.3), width: 2)

                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }

                    Button(action: saveSignature) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.tranquilTeal)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Signature?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearSignature()
                }
            } message: {
                Text("This will erase your current signature.")
            }
        }
    }

    private func clearSignature() {
        canvasView.drawing = PKDrawing()
    }

    private func saveSignature() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        signatureData = image.pngData()

        // Log signature capture for audit trail
        AuditLogger.shared.log(
            event: .documentSigned,
            details: "Digital signature captured - \(signatureData?.count ?? 0) bytes"
        )

        dismiss()
    }
}

// MARK: - Signature Canvas (PencilKit Integration)
struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .white
        canvasView.isOpaque = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No updates needed
    }
}

// MARK: - Fallback: Simple Drawing View (if PencilKit unavailable)
struct SimpleSignatureView: View {
    @Binding var signatureData: Data?
    @State private var currentPath = Path()
    @State private var paths: [Path] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white

                // Drawn paths
                ForEach(paths.indices, id: \.self) { index in
                    paths[index]
                        .stroke(Color.black, lineWidth: 3)
                }

                // Current path
                currentPath
                    .stroke(Color.black, lineWidth: 3)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newPoint = value.location
                        if currentPath.isEmpty {
                            currentPath.move(to: newPoint)
                        } else {
                            currentPath.addLine(to: newPoint)
                        }
                    }
                    .onEnded { _ in
                        paths.append(currentPath)
                        currentPath = Path()
                    }
            )
        }
    }
}

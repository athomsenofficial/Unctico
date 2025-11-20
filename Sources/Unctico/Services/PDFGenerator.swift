import Combine
import Foundation
import PDFKit

class PDFGenerator {
    static let shared = PDFGenerator()

    private init() {}

    // MARK: - Invoice PDF Generation

    func generateInvoicePDF(invoice: Invoice, client: Client) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Unctico",
            kCGPDFContextAuthor: "Massage Therapy Practice",
            kCGPDFContextTitle: "Invoice \(invoice.invoiceNumber)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // 8.5 x 11 inches
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let textColor = UIColor.black
            let accentColor = UIColor(red: 0.4, green: 0.7, blue: 0.7, alpha: 1.0)

            var currentY: CGFloat = 60

            // Header
            drawText(
                "INVOICE",
                at: CGPoint(x: 60, y: currentY),
                fontSize: 32,
                bold: true,
                color: accentColor,
                in: context
            )

            currentY += 50

            // Business Info (Left)
            drawText("Your Practice Name", at: CGPoint(x: 60, y: currentY), fontSize: 14, bold: true, in: context)
            currentY += 20
            drawText("123 Wellness Street", at: CGPoint(x: 60, y: currentY), fontSize: 10, in: context)
            currentY += 15
            drawText("City, ST 12345", at: CGPoint(x: 60, y: currentY), fontSize: 10, in: context)
            currentY += 15
            drawText("(555) 123-4567", at: CGPoint(x: 60, y: currentY), fontSize: 10, in: context)

            // Invoice Info (Right)
            let rightX: CGFloat = 400
            var rightY: CGFloat = 110
            drawText("Invoice #: \(invoice.invoiceNumber)", at: CGPoint(x: rightX, y: rightY), fontSize: 10, in: context)
            rightY += 15
            drawText("Date: \(formatDate(invoice.issueDate))", at: CGPoint(x: rightX, y: rightY), fontSize: 10, in: context)
            rightY += 15
            drawText("Due: \(formatDate(invoice.dueDate))", at: CGPoint(x: rightX, y: rightY), fontSize: 10, in: context)

            currentY += 60

            // Client Info
            drawText("Bill To:", at: CGPoint(x: 60, y: currentY), fontSize: 12, bold: true, in: context)
            currentY += 20
            drawText(client.fullName, at: CGPoint(x: 60, y: currentY), fontSize: 11, in: context)
            currentY += 15
            if let email = client.email {
                drawText(email, at: CGPoint(x: 60, y: currentY), fontSize: 10, in: context)
                currentY += 15
            }
            if let phone = client.phone {
                drawText(phone, at: CGPoint(x: 60, y: currentY), fontSize: 10, in: context)
                currentY += 15
            }

            currentY += 30

            // Table Header
            let tableStartY = currentY
            drawRect(CGRect(x: 60, y: tableStartY, width: 492, height: 30), color: accentColor.withAlphaComponent(0.2), in: context)

            drawText("Description", at: CGPoint(x: 70, y: tableStartY + 10), fontSize: 10, bold: true, in: context)
            drawText("Qty", at: CGPoint(x: 340, y: tableStartY + 10), fontSize: 10, bold: true, in: context)
            drawText("Price", at: CGPoint(x: 400, y: tableStartY + 10), fontSize: 10, bold: true, in: context)
            drawText("Total", at: CGPoint(x: 480, y: tableStartY + 10), fontSize: 10, bold: true, in: context)

            currentY = tableStartY + 40

            // Line Items
            for item in invoice.lineItems {
                drawText(item.description, at: CGPoint(x: 70, y: currentY), fontSize: 10, in: context)
                drawText("\(item.quantity)", at: CGPoint(x: 350, y: currentY), fontSize: 10, in: context)
                drawText("$\(String(format: "%.2f", item.unitPrice))", at: CGPoint(x: 390, y: currentY), fontSize: 10, in: context)
                drawText("$\(String(format: "%.2f", item.total))", at: CGPoint(x: 470, y: currentY), fontSize: 10, in: context)
                currentY += 20
            }

            currentY += 20

            // Totals
            drawLine(from: CGPoint(x: 350, y: currentY), to: CGPoint(x: 552, y: currentY), in: context)
            currentY += 15

            drawText("Subtotal:", at: CGPoint(x: 400, y: currentY), fontSize: 10, in: context)
            drawText("$\(String(format: "%.2f", invoice.subtotal))", at: CGPoint(x: 480, y: currentY), fontSize: 10, in: context)
            currentY += 20

            if invoice.discount > 0 {
                drawText("Discount:", at: CGPoint(x: 400, y: currentY), fontSize: 10, in: context)
                drawText("-$\(String(format: "%.2f", invoice.discount))", at: CGPoint(x: 475, y: currentY), fontSize: 10, in: context)
                currentY += 20
            }

            if invoice.taxAmount > 0 {
                drawText("Tax (\(Int(invoice.taxRate * 100))%):", at: CGPoint(x: 400, y: currentY), fontSize: 10, in: context)
                drawText("$\(String(format: "%.2f", invoice.taxAmount))", at: CGPoint(x: 480, y: currentY), fontSize: 10, in: context)
                currentY += 20
            }

            drawLine(from: CGPoint(x: 350, y: currentY), to: CGPoint(x: 552, y: currentY), in: context)
            currentY += 15

            drawText("Total:", at: CGPoint(x: 400, y: currentY), fontSize: 12, bold: true, in: context)
            drawText("$\(String(format: "%.2f", invoice.total))", at: CGPoint(x: 475, y: currentY), fontSize: 12, bold: true, color: accentColor, in: context)

            if invoice.paidAmount > 0 {
                currentY += 20
                drawText("Paid:", at: CGPoint(x: 400, y: currentY), fontSize: 10, in: context)
                drawText("-$\(String(format: "%.2f", invoice.paidAmount))", at: CGPoint(x: 475, y: currentY), fontSize: 10, in: context)
                currentY += 20

                drawText("Balance Due:", at: CGPoint(x: 400, y: currentY), fontSize: 11, bold: true, in: context)
                drawText("$\(String(format: "%.2f", invoice.balanceDue))", at: CGPoint(x: 470, y: currentY), fontSize: 11, bold: true, color: .red, in: context)
            }

            // Notes
            if let notes = invoice.notes, !notes.isEmpty {
                currentY += 40
                drawText("Notes:", at: CGPoint(x: 60, y: currentY), fontSize: 10, bold: true, in: context)
                currentY += 15
                drawText(notes, at: CGPoint(x: 60, y: currentY), fontSize: 9, maxWidth: 492, in: context)
            }

            // Footer
            let footerY: CGFloat = 720
            drawText("Thank you for your business!", at: CGPoint(x: 60, y: footerY), fontSize: 10, color: .gray, in: context)
        }

        // Save to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("Invoice_\(invoice.invoiceNumber).pdf")

        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    // MARK: - SOAP Note PDF Generation

    func generateSOAPNotePDF(note: SOAPNote, client: Client) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var currentY: CGFloat = 60

            // Header
            drawText("SOAP NOTE", at: CGPoint(x: 60, y: currentY), fontSize: 24, bold: true, in: context)
            currentY += 40

            // Client Info
            drawText("Client: \(client.fullName)", at: CGPoint(x: 60, y: currentY), fontSize: 12, in: context)
            currentY += 20
            drawText("Date: \(formatDate(note.date))", at: CGPoint(x: 60, y: currentY), fontSize: 12, in: context)
            currentY += 40

            // Subjective
            drawSectionHeader("SUBJECTIVE", at: &currentY, in: context)
            if !note.subjective.chiefComplaint.isEmpty {
                drawText("Chief Complaint:", at: CGPoint(x: 60, y: currentY), fontSize: 10, bold: true, in: context)
                currentY += 15
                drawText(note.subjective.chiefComplaint, at: CGPoint(x: 60, y: currentY), fontSize: 9, maxWidth: 492, in: context)
                currentY += 20
            }
            drawText("Pain Level: \(note.subjective.painLevel)/10", at: CGPoint(x: 60, y: currentY), fontSize: 9, in: context)
            currentY += 15
            drawText("Stress Level: \(note.subjective.stressLevel)/10", at: CGPoint(x: 60, y: currentY), fontSize: 9, in: context)
            currentY += 30

            // Objective
            drawSectionHeader("OBJECTIVE", at: &currentY, in: context)
            drawText("Areas Worked: \(note.objective.areasWorked.count) locations", at: CGPoint(x: 60, y: currentY), fontSize: 9, in: context)
            currentY += 30

            // Assessment
            drawSectionHeader("ASSESSMENT", at: &currentY, in: context)
            if !note.assessment.progressNotes.isEmpty {
                drawText(note.assessment.progressNotes, at: CGPoint(x: 60, y: currentY), fontSize: 9, maxWidth: 492, in: context)
                currentY += 30
            }

            // Plan
            drawSectionHeader("PLAN", at: &currentY, in: context)
            if !note.plan.treatmentFrequency.isEmpty {
                drawText("Frequency: \(note.plan.treatmentFrequency)", at: CGPoint(x: 60, y: currentY), fontSize: 9, in: context)
                currentY += 15
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("SOAP_Note_\(formatDate(note.date)).pdf")

        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    private func drawText(
        _ text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        bold: Bool = false,
        color: UIColor = .black,
        maxWidth: CGFloat = 492,
        in context: UIGraphicsPDFRendererContext
    ) {
        let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let rect = CGRect(x: point.x, y: point.y, width: maxWidth, height: 500)
        text.draw(in: rect, withAttributes: attributes)
    }

    private func drawRect(_ rect: CGRect, color: UIColor, in context: UIGraphicsPDFRendererContext) {
        context.cgContext.setFillColor(color.cgColor)
        context.cgContext.fill(rect)
    }

    private func drawLine(from start: CGPoint, to end: CGPoint, in context: UIGraphicsPDFRendererContext) {
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: start)
        context.cgContext.addLine(to: end)
        context.cgContext.strokePath()
    }

    private func drawSectionHeader(_ title: String, at y: inout CGFloat, in context: UIGraphicsPDFRendererContext) {
        let accentColor = UIColor(red: 0.4, green: 0.7, blue: 0.7, alpha: 1.0)
        drawText(title, at: CGPoint(x: 60, y: y), fontSize: 14, bold: true, color: accentColor, in: context)
        y += 25
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

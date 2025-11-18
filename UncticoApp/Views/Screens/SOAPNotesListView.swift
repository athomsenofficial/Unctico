// SOAPNotesListView.swift
// List of all SOAP notes
// QA Note: Shows clinical documentation

import SwiftUI

struct SOAPNotesListView: View {

    // MARK: - Environment Objects

    @EnvironmentObject var dataManager: DataManager

    // MARK: - State

    @State private var showingCreateNote = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.soapNotes.sorted { $0.createdDate > $1.createdDate }) { note in
                    NavigationLink(destination: SOAPNoteDetailView(note: note)) {
                        SOAPNoteRow(note: note)
                    }
                }
            }
            .navigationTitle("SOAP Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateNote) {
                CreateSOAPNoteView()
            }
            .overlay {
                if dataManager.soapNotes.isEmpty {
                    emptyState
                }
            }
        }
    }

    // MARK: - View Components

    /// Empty state
    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No SOAP Notes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Clinical notes will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - SOAP Note Row

struct SOAPNoteRow: View {
    let note: SOAPNote
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Client name
            if let client = dataManager.getClient(id: note.clientId) {
                Text(client.fullName)
                    .font(.headline)
            }

            // Chief complaint
            if !note.subjective.chiefComplaint.isEmpty {
                Text(note.subjective.chiefComplaint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Date
            Text(note.createdDate, formatter: DateFormatter.fullDateTime)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview

struct SOAPNotesListView_Previews: PreviewProvider {
    static var previews: some View {
        SOAPNotesListView()
            .environmentObject(DataManager())
    }
}

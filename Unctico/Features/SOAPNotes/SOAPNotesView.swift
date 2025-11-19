// SOAPNotesView.swift
// SOAP notes documentation view (Subjective, Objective, Assessment, Plan)

import SwiftUI

/// SOAP notes management view
struct SOAPNotesView: View {

    // MARK: - State

    @State private var searchText = ""
    @State private var showingNewNote = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                emptyState
            }
            .navigationTitle("SOAP Notes")
            .searchable(text: $searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NewSOAPNoteView()
            }
        }
    }

    // MARK: - View Components

    /// Empty state when no notes
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No SOAP Notes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Document client sessions using SOAP note format")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingNewNote = true
            } label: {
                Text("Create SOAP Note")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - New SOAP Note View

struct NewSOAPNoteView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedClient: Client?
    @State private var sessionDate = Date()

    // SOAP note components
    @State private var subjective = ""
    @State private var objective = ""
    @State private var assessment = ""
    @State private var plan = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Information") {
                    Button {
                        // TODO: Show client picker
                    } label: {
                        HStack {
                            Text("Client")
                            Spacer()
                            if let client = selectedClient {
                                Text(client.fullName)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Select...")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    DatePicker("Date", selection: $sessionDate, displayedComponents: [.date])
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subjective")
                            .font(.headline)
                        Text("Client's reported symptoms, pain, concerns")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $subjective)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Objective")
                            .font(.headline)
                        Text("Observed findings, palpation, range of motion")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $objective)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assessment")
                            .font(.headline)
                        Text("Analysis and professional opinion")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $assessment)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan")
                            .font(.headline)
                        Text("Treatment plan, recommendations, follow-up")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $plan)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("New SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Save SOAP note (encrypted)
                        dismiss()
                    }
                    .disabled(selectedClient == nil)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SOAPNotesView()
}

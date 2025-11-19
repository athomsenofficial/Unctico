// ScheduleView.swift
// Main scheduling interface with calendar and settings

import SwiftUI

/// Main schedule view with calendar and settings
struct ScheduleView: View {

    @State private var showingAvailabilitySettings = false

    var body: some View {
        NavigationStack {
            CalendarView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAvailabilitySettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showingAvailabilitySettings) {
                    // TODO: Get actual user ID from auth
                    AvailabilitySettingsView(userId: UUID())
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ScheduleView()
}

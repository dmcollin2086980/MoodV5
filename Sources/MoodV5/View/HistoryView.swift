import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: MoodEntry?
    
    init(moodStore: MoodStore) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(moodStore: moodStore))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time Frame Picker
                Picker("Time Frame", selection: $viewModel.selectedTimeFrame) {
                    ForEach(HistoryViewModel.TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewModel.entries.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Entries",
                        message: "Your mood history will appear here",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.entries) { entry in
                                MoodEntryCard(entry: entry) {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mood History")
            .refreshable {
                viewModel.refreshEntries()
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        viewModel.deleteEntry(entry)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this mood entry?")
            }
            .withErrorAlert(error: $viewModel.error) {
                viewModel.error = nil
            }
        }
    }
}

#Preview {
    HistoryView(moodStore: try! RealmMoodStore())
} 
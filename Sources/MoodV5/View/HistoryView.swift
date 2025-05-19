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
                    emptyStateView
                } else {
                    entriesList
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
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No entries yet")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Your mood history will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var entriesList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                MoodEntryRow(entry: entry)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.moodType)
                    .font(.headline)
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(entry.tags), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(moodStore: try! RealmMoodStore())
} 
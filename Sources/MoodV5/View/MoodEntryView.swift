import SwiftUI

struct MoodEntryView: View {
    @StateObject private var viewModel: MoodEntryViewModel
    @State private var showingTags = false
    
    init(moodStore: MoodStore) {
        _viewModel = StateObject(wrappedValue: MoodEntryViewModel(moodStore: moodStore))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood Selection Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: viewModel.selectedMood == mood,
                                action: { viewModel.selectedMood = mood }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Note Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.note)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Tags Button
                    Button(action: { showingTags = true }) {
                        HStack {
                            Image(systemName: "tag")
                            Text("Add Tags")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: { viewModel.saveMood() }) {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedMood != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.selectedMood == nil)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("How are you feeling?")
            .sheet(isPresented: $showingTags) {
                TagSelectionView(selectedTags: $viewModel.selectedTags)
            }
            .withErrorAlert(error: $viewModel.error) {
                viewModel.error = nil
            }
        }
    }
}

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    let commonTags = ["Work", "Family", "Health", "Social", "Exercise", "Sleep"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(commonTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

#Preview {
    MoodEntryView(moodStore: try! RealmMoodStore())
} 

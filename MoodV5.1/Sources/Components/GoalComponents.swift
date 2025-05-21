import SwiftUI

// MARK: - Goal Card
struct GoalCard: View {
    let goal: Goal
    @ObservedObject var viewModel: GoalsViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                        
                        Text(goal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: { viewModel.incrementProgress(for: goal) }) {
                            Label("Mark Progress", systemImage: "plus.circle")
                        }
                        
                        Button(action: { viewModel.resetProgress(for: goal) }) {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
                
                ProgressView(value: Double(goal.currentCount), total: Double(goal.targetCount))
                    .tint(goal.isCompleted ? .green : .blue)
                
                HStack {
                    Text("\(goal.currentCount)/\(goal.targetCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(goal.frequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteGoal(goal)
            }
        } message: {
            Text("Are you sure you want to delete this goal?")
        }
    }
}

// MARK: - Goal List
struct GoalList: View {
    @ObservedObject var viewModel: GoalsViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.goals) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    viewModel.deleteGoal(viewModel.goals[index])
                }
            }
        }
        .listStyle(.plain)
    }
}
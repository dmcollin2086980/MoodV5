import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel: GoalsViewModel
    @State private var showingNewGoalSheet = false
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: Goal?
    
    init(goalStore: GoalStore) {
        _viewModel = StateObject(wrappedValue: GoalsViewModel(goalStore: goalStore))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.goals.isEmpty {
                        EmptyStateView(
                            icon: "target",
                            title: "No Goals Yet",
                            message: "Set your first goal to start tracking your progress",
                            actionTitle: "Create Goal",
                            action: { showingNewGoalSheet = true }
                        )
                    } else {
                        if !viewModel.overdueGoals.isEmpty {
                            overdueGoalsSection
                        }
                        
                        activeGoalsSection
                        
                        if !viewModel.completedGoals.isEmpty {
                            completedGoalsSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewGoalSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewGoalSheet) {
                NewGoalView(viewModel: viewModel)
            }
            .alert("Delete Goal", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let goal = goalToDelete {
                        viewModel.deleteGoal(goal)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this goal?")
            }
            .alert("Goal Completed! 🎉", isPresented: $viewModel.showingCompletionAlert) {
                Button("OK") {
                    viewModel.showingCompletionAlert = false
                    viewModel.completedGoal = nil
                }
            } message: {
                if let goal = viewModel.completedGoal {
                    Text("Congratulations on completing '\(goal.title)'!")
                }
            }
            .withErrorAlert(error: $viewModel.error) {
                viewModel.error = nil
            }
        }
    }
    
    private var overdueGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overdue")
                .font(.headline)
                .foregroundColor(.red)
            
            ForEach(viewModel.overdueGoals) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
            }
        }
    }
    
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active")
                .font(.headline)
            
            ForEach(viewModel.activeGoals) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
            }
        }
    }
    
    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(.headline)
                .foregroundColor(.green)
            
            ForEach(viewModel.completedGoals) { goal in
                GoalCard(goal: goal, viewModel: viewModel)
            }
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    @ObservedObject var viewModel: GoalsViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
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
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(goal.currentCount)/\(goal.targetCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(GoalFrequency(rawValue: goal.frequency)?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: goal.progress)
                    .tint(goal.isCompleted ? .green : .blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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

struct NewGoalView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var frequency = GoalFrequency.daily
    @State private var targetCount = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Frequency")) {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(GoalFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("Target")) {
                    Stepper("Target Count: \(targetCount)", value: $targetCount, in: 1...100)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    viewModel.createGoal(
                        title: title,
                        description: description,
                        frequency: frequency,
                        targetCount: targetCount
                    )
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

#Preview {
    GoalsView(goalStore: try! RealmGoalStore())
} 
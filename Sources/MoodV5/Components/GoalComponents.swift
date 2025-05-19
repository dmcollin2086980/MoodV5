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
                    
                    Text(goal.frequency.rawValue)
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

// MARK: - Goal Progress Row
struct GoalProgressRow: View {
    let progress: WeeklyReport.GoalProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(progress.goal.title)
                .font(.subheadline)
            
            HStack {
                ProgressView(value: progress.completionRate)
                    .tint(progress.completionRate >= 1.0 ? .green : .blue)
                
                Text("\(Int(progress.completionRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if progress.streak > 0 {
                Text("Current Streak: \(progress.streak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let impact = progress.impactOnMood {
                Text("Mood Impact: \(impact > 0 ? "+" : "")\(String(format: "%.1f", impact))")
                    .font(.caption)
                    .foregroundColor(impact > 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Goal Impact Card
struct GoalImpactCard: View {
    let correlation: WeeklyReport.PatternAnalysis.GoalMoodCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Goal Impact")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(correlation.goal.title)
                .font(.body)
            
            Text("Impact: \(correlation.impact == .positive ? "Positive" : "Negative")")
                .font(.caption)
                .foregroundColor(correlation.impact == .positive ? .green : .red)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
} 
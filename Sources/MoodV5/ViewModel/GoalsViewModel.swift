import Foundation
import Combine

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingCompletionAlert = false
    @Published var completedGoal: Goal?
    
    private let goalStore: GoalStore
    private var cancellables = Set<AnyCancellable>()
    
    init(goalStore: GoalStore) {
        self.goalStore = goalStore
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        goalStore.goalsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                self?.goals = goals
            }
            .store(in: &cancellables)
    }
    
    func createGoal(title: String, description: String, frequency: GoalFrequency, targetCount: Int) {
        let goal = Goal(title: title, description: description, frequency: frequency, targetCount: targetCount)
        
        do {
            try goalStore.save(goal)
        } catch {
            self.error = error
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        do {
            try goalStore.delete(goal: goal)
        } catch {
            self.error = error
        }
    }
    
    func incrementProgress(for goal: Goal) {
        do {
            goal.incrementProgress()
            try goalStore.update(goal)
            
            if goal.isCompleted {
                completedGoal = goal
                showingCompletionAlert = true
            }
        } catch {
            self.error = error
        }
    }
    
    func resetProgress(for goal: Goal) {
        do {
            goal.resetProgress()
            try goalStore.update(goal)
        } catch {
            self.error = error
        }
    }
    
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var overdueGoals: [Goal] {
        goals.filter { $0.isOverdue && !$0.isCompleted }
    }
} 
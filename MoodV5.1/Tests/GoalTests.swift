import XCTest
@testable import MoodV5_1

final class GoalTests: XCTestCase {
    var goalStore: RealmGoalStore!
    var viewModel: GoalsViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        goalStore = try! RealmGoalStore()
        viewModel = GoalsViewModel(goalStore: goalStore)
    }
    
    override func tearDown() {
        viewModel = nil
        goalStore = nil
        super.tearDown()
    }
    
    func testGoalCreation() {
        let title = "Test Goal"
        let description = "Test Description"
        let frequency = GoalFrequency.daily
        let targetCount = 5
        
        viewModel.createGoal(
            title: title,
            description: description,
            frequency: frequency,
            targetCount: targetCount
        )
        
        XCTAssertEqual(viewModel.goals.count, 1)
        let goal = viewModel.goals.first!
        XCTAssertEqual(goal.title, title)
        XCTAssertEqual(goal.description, description)
        XCTAssertEqual(goal.frequency, frequency.rawValue)
        XCTAssertEqual(goal.targetCount, targetCount)
        XCTAssertEqual(goal.currentCount, 0)
        XCTAssertFalse(goal.isCompleted)
    }
    
    func testGoalProgress() {
        let goal = Goal(
            title: "Test Goal",
            description: "Test Description",
            frequency: .daily,
            targetCount: 3
        )
        
        try! goalStore.save(goal)
        
        // Test progress increment
        viewModel.incrementProgress(for: goal)
        XCTAssertEqual(goal.currentCount, 1)
        XCTAssertFalse(goal.isCompleted)
        
        // Test completion
        viewModel.incrementProgress(for: goal)
        viewModel.incrementProgress(for: goal)
        XCTAssertEqual(goal.currentCount, 3)
        XCTAssertTrue(goal.isCompleted)
        
        // Test progress reset
        viewModel.resetProgress(for: goal)
        XCTAssertEqual(goal.currentCount, 0)
        XCTAssertFalse(goal.isCompleted)
    }
    
    func testGoalDeletion() {
        let goal = Goal(
            title: "Test Goal",
            description: "Test Description",
            frequency: .daily,
            targetCount: 1
        )
        
        try! goalStore.save(goal)
        XCTAssertEqual(viewModel.goals.count, 1)
        
        viewModel.deleteGoal(goal)
        XCTAssertEqual(viewModel.goals.count, 0)
    }
    
    func testGoalOverdue() {
        let goal = Goal(
            title: "Test Goal",
            description: "Test Description",
            frequency: .daily,
            targetCount: 1
        )
        
        // Set last completed date to yesterday
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        goal.lastCompletedDate = yesterday
        
        try! goalStore.save(goal)
        
        XCTAssertTrue(goal.isOverdue)
        XCTAssertTrue(viewModel.overdueGoals.contains(where: { $0.id == goal.id }))
    }
    
    func testGoalCategories() {
        // Create completed goal
        let completedGoal = Goal(
            title: "Completed Goal",
            description: "Test",
            frequency: .daily,
            targetCount: 1
        )
        completedGoal.incrementProgress()
        
        // Create active goal
        let activeGoal = Goal(
            title: "Active Goal",
            description: "Test",
            frequency: .daily,
            targetCount: 2
        )
        
        try! goalStore.save(completedGoal)
        try! goalStore.save(activeGoal)
        
        XCTAssertEqual(viewModel.completedGoals.count, 1)
        XCTAssertEqual(viewModel.activeGoals.count, 1)
        XCTAssertEqual(viewModel.goals.count, 2)
    }
} 
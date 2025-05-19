import XCTest
@testable import MoodV5

final class CoachTests: XCTestCase {
    var moodStore: RealmMoodStore!
    var coachService: CoachService!
    var viewModel: CoachViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        moodStore = try! RealmMoodStore()
        coachService = CoachService(moodStore: moodStore)
        viewModel = CoachViewModel(coachService: coachService)
    }
    
    override func tearDown() {
        viewModel = nil
        coachService = nil
        moodStore = nil
        super.tearDown()
    }
    
    func testEmptyStateInsight() {
        let insight = coachService.generateDailyInsight()
        
        XCTAssertEqual(insight.title, "Welcome! 👋")
        XCTAssertEqual(insight.type, .neutral)
        XCTAssertNotNil(insight.action)
    }
    
    func testNegativeMoodPattern() {
        // Create three consecutive bad moods
        let dates = [
            Date(),
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        ]
        
        for date in dates {
            let entry = MoodEntry(date: date, moodType: MoodType.bad.rawValue, note: "Test")
            try! moodStore.save(entry)
        }
        
        let insight = coachService.generateDailyInsight()
        
        XCTAssertEqual(insight.title, "Rough Patch 😔")
        XCTAssertEqual(insight.type, .improvement)
        XCTAssertNotNil(insight.action)
    }
    
    func testPositiveMoodPattern() {
        // Create three consecutive good moods
        let dates = [
            Date(),
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        ]
        
        for date in dates {
            let entry = MoodEntry(date: date, moodType: MoodType.great.rawValue, note: "Test")
            try! moodStore.save(entry)
        }
        
        let insight = coachService.generateDailyInsight()
        
        XCTAssertEqual(insight.title, "On a Roll! 🌟")
        XCTAssertEqual(insight.type, .positive)
        XCTAssertNotNil(insight.action)
    }
    
    func testStreakDetection() {
        // Create entries for the last 5 days
        for day in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            let entry = MoodEntry(date: date, moodType: MoodType.okay.rawValue, note: "Test")
            try! moodStore.save(entry)
        }
        
        let insight = coachService.generateDailyInsight()
        
        XCTAssertEqual(insight.title, "Impressive Streak! 🔥")
        XCTAssertEqual(insight.type, .positive)
        XCTAssertNotNil(insight.action)
    }
    
    func testMoodImprovement() {
        // Create two entries with improving mood
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()
        
        let yesterdayEntry = MoodEntry(date: yesterday, moodType: MoodType.bad.rawValue, note: "Test")
        let todayEntry = MoodEntry(date: today, moodType: MoodType.good.rawValue, note: "Test")
        
        try! moodStore.save(yesterdayEntry)
        try! moodStore.save(todayEntry)
        
        let insight = coachService.generateDailyInsight()
        
        XCTAssertEqual(insight.title, "Mood Lift! 📈")
        XCTAssertEqual(insight.type, .positive)
        XCTAssertNotNil(insight.action)
    }
    
    func testViewModelRefresh() {
        // Test initial state
        XCTAssertNil(viewModel.currentInsight)
        
        // Add some entries
        let entry = MoodEntry(date: Date(), moodType: MoodType.good.rawValue, note: "Test")
        try! moodStore.save(entry)
        
        // Refresh insight
        viewModel.refreshInsight()
        
        // Wait for async operation
        let expectation = XCTestExpectation(description: "Wait for insight refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        
        XCTAssertNotNil(viewModel.currentInsight)
    }
} 
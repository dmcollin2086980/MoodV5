import XCTest
@testable import MoodV5

final class ReportTests: XCTestCase {
    var moodStore: RealmMoodStore!
    var goalStore: RealmGoalStore!
    var coachService: CoachService!
    var reportService: ReportService!
    var viewModel: ReportViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        moodStore = try! RealmMoodStore()
        goalStore = try! RealmGoalStore()
        coachService = CoachService()
        reportService = ReportService(
            moodStore: moodStore,
            goalStore: goalStore,
            coachService: coachService
        )
        viewModel = ReportViewModel(reportService: reportService)
    }
    
    override func tearDown() {
        viewModel = nil
        reportService = nil
        coachService = nil
        goalStore = nil
        moodStore = nil
        super.tearDown()
    }
    
    func testReportGeneration() throws {
        // Create test data
        let calendar = Calendar.current
        let now = Date()
        
        // Add mood entries for the past week
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: day % 2 == 0 ? MoodType.good.rawValue : MoodType.neutral.rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        // Add test goals
        let goal = Goal(title: "Test Goal", description: "Test", frequency: .daily, targetCount: 7)
        try goalStore.save(goal)
        
        // Generate report
        viewModel.generateReport()
        
        // Verify report
        XCTAssertNotNil(viewModel.report)
        guard let report = viewModel.report else { return }
        
        // Check date range
        XCTAssertEqual(calendar.dateComponents([.day], from: report.startDate, to: report.endDate).day, 6)
        
        // Check mood distribution
        XCTAssertEqual(report.moodDistribution[MoodType.good], 4)
        XCTAssertEqual(report.moodDistribution[MoodType.neutral], 3)
        
        // Check average mood
        XCTAssertEqual(report.averageMood, 3.5, accuracy: 0.1)
        
        // Check most frequent mood
        XCTAssertEqual(report.mostFrequentMood, .good)
        
        // Check goal progress
        XCTAssertEqual(report.goalProgress.count, 1)
        XCTAssertEqual(report.goalProgress[0].goal.title, "Test Goal")
        
        // Check mood trends
        XCTAssertFalse(report.moodTrends.dailyAverages.isEmpty)
        XCTAssertNotNil(report.moodTrends.peakMoodTime)
        XCTAssertNotNil(report.moodTrends.lowMoodTime)
        
        // Check time of day analysis
        XCTAssertNotNil(report.moodTrends.timeOfDayAnalysis)
        XCTAssertNotNil(report.moodTrends.timeOfDayAnalysis.bestTimeOfDay)
        XCTAssertNotNil(report.moodTrends.timeOfDayAnalysis.worstTimeOfDay)
        
        // Check pattern analysis
        XCTAssertNotNil(report.patternAnalysis)
    }
    
    func testTimeOfDayAnalysis() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create entries for different times of day
        let times: [(hour: Int, mood: MoodType)] = [
            (8, .good),    // Morning
            (14, .neutral), // Afternoon
            (20, .bad)     // Evening
        ]
        
        for (hour, mood) in times {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: mood.rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check time of day averages
        let timeOfDay = report.moodTrends.timeOfDayAnalysis
        XCTAssertEqual(timeOfDay.morningAverage, 4.0) // Good
        XCTAssertEqual(timeOfDay.afternoonAverage, 3.0) // Neutral
        XCTAssertEqual(timeOfDay.eveningAverage, 2.0) // Bad
        
        // Check best and worst times
        XCTAssertEqual(timeOfDay.bestTimeOfDay, .morning)
        XCTAssertEqual(timeOfDay.worstTimeOfDay, .evening)
    }
    
    func testPatternAnalysis() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create a pattern of good moods in the morning
        for day in 0..<7 {
            if let date = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -day, to: now)!) {
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: MoodType.good.rawValue,
                    note: "Morning entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        // Add a goal that correlates with mood
        let goal = Goal(title: "Exercise", description: "Daily exercise", frequency: .daily, targetCount: 7)
        try goalStore.save(goal)
        
        // Complete the goal on good mood days
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                goal.completions.append(GoalCompletion(date: date))
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check recurring patterns
        XCTAssertFalse(report.patternAnalysis.recurringPatterns.isEmpty)
        if let strongestPattern = report.patternAnalysis.recurringPatterns.max(by: { $0.confidence < $1.confidence }) {
            XCTAssertTrue(strongestPattern.pattern.contains("good"))
            XCTAssertTrue(strongestPattern.pattern.contains("morning"))
        }
        
        // Check goal-mood correlations
        XCTAssertFalse(report.patternAnalysis.goalMoodCorrelations.isEmpty)
        if let strongestCorrelation = report.patternAnalysis.goalMoodCorrelations.max(by: { $0.correlation < $1.correlation }) {
            XCTAssertEqual(strongestCorrelation.goal.title, "Exercise")
        }
        
        // Check weekly patterns
        XCTAssertFalse(report.patternAnalysis.weeklyPatterns.isEmpty)
    }
    
    func testGoalMoodImpact() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create a goal
        let goal = Goal(title: "Test Goal", description: "Test", frequency: .daily, targetCount: 7)
        try goalStore.save(goal)
        
        // Add mood entries with and without goal completion
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                // Add mood entry
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: day % 2 == 0 ? MoodType.good.rawValue : MoodType.neutral.rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
                
                // Complete goal on even days
                if day % 2 == 0 {
                    goal.completions.append(GoalCompletion(date: date))
                }
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check goal progress
        XCTAssertEqual(report.goalProgress.count, 1)
        let progress = report.goalProgress[0]
        
        // Verify mood impact
        XCTAssertNotNil(progress.impactOnMood)
        if let impact = progress.impactOnMood {
            XCTAssertGreaterThan(impact, 0) // Should be positive impact
        }
    }
    
    func testMoodTrends() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create improving mood trend
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                let moodValue = min(5, 1 + day) // Increasing mood values
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: MoodType.allCases[moodValue - 1].rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check trend direction
        XCTAssertEqual(report.moodTrends.trendDirection, .improving)
        
        // Check consistency score
        XCTAssertLessThan(report.moodTrends.consistencyScore, 0.8) // Should be less consistent due to improvement
        
        // Check daily averages
        XCTAssertEqual(report.moodTrends.dailyAverages.count, 7)
        XCTAssertEqual(report.moodTrends.dailyAverages.first?.1, 1.0)
        XCTAssertEqual(report.moodTrends.dailyAverages.last?.1, 5.0)
    }
    
    func testStableMoodTrends() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create stable mood trend
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: MoodType.good.rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check trend direction
        XCTAssertEqual(report.moodTrends.trendDirection, .stable)
        
        // Check consistency score
        XCTAssertGreaterThan(report.moodTrends.consistencyScore, 0.8) // Should be very consistent
        
        // Check daily averages
        XCTAssertEqual(report.moodTrends.dailyAverages.count, 7)
        for (_, average) in report.moodTrends.dailyAverages {
            XCTAssertEqual(average, 4.0, accuracy: 0.1) // All should be around 4.0 (good)
        }
    }
    
    func testFluctuatingMoodTrends() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create fluctuating mood trend
        let moodValues = [1, 5, 2, 4, 1, 5, 3]
        for (day, value) in moodValues.enumerated() {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: MoodType.allCases[value - 1].rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        viewModel.generateReport()
        
        guard let report = viewModel.report else {
            XCTFail("Report should not be nil")
            return
        }
        
        // Check trend direction
        XCTAssertEqual(report.moodTrends.trendDirection, .fluctuating)
        
        // Check consistency score
        XCTAssertLessThan(report.moodTrends.consistencyScore, 0.4) // Should be very inconsistent
        
        // Check daily averages
        XCTAssertEqual(report.moodTrends.dailyAverages.count, 7)
    }
    
    func testEmptyReport() throws {
        // Generate report with no data
        viewModel.generateReport()
        
        // Verify report
        XCTAssertNotNil(viewModel.report)
        guard let report = viewModel.report else { return }
        
        // Check mood distribution
        XCTAssertTrue(report.moodDistribution.isEmpty)
        
        // Check average mood
        XCTAssertEqual(report.averageMood, 0)
        
        // Check goal progress
        XCTAssertTrue(report.goalProgress.isEmpty)
        
        // Check mood trends
        XCTAssertTrue(report.moodTrends.dailyAverages.isEmpty)
        XCTAssertEqual(report.moodTrends.trendDirection, .stable)
        XCTAssertEqual(report.moodTrends.consistencyScore, 1.0)
        XCTAssertNil(report.moodTrends.peakMoodTime)
        XCTAssertNil(report.moodTrends.lowMoodTime)
    }
    
    func testReportInsights() throws {
        // Create test data with negative mood trend
        let calendar = Calendar.current
        let now = Date()
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                let moodValue = max(1, 5 - day) // Decreasing mood values
                let moodEntry = MoodEntry(
                    date: date,
                    moodType: MoodType.allCases[moodValue - 1].rawValue,
                    note: "Test entry"
                )
                try moodStore.save(moodEntry)
            }
        }
        
        // Generate report
        viewModel.generateReport()
        
        // Verify insights
        XCTAssertNotNil(viewModel.report)
        guard let report = viewModel.report else { return }
        
        // Check that insights are generated
        XCTAssertFalse(report.insights.isEmpty)
        
        // Check that recommendations are generated
        XCTAssertFalse(report.recommendations.isEmpty)
        
        // Check for trend-specific insights
        XCTAssertTrue(report.insights.contains { $0.contains("declining") })
    }
    
    func testReportSharing() throws {
        // Create test data
        let moodEntry = MoodEntry(date: Date(), moodType: MoodType.good.rawValue, note: "Test")
        try moodStore.save(moodEntry)
        
        let goal = Goal(title: "Test Goal", description: "Test", frequency: .daily, targetCount: 1)
        try goalStore.save(goal)
        
        // Generate report
        viewModel.generateReport()
        
        // Share report
        viewModel.shareReport()
        
        // Verify share sheet is shown
        XCTAssertTrue(viewModel.showingShareSheet)
    }
    
    func testMoodDistributionData() throws {
        // Create test data
        let moodEntry = MoodEntry(date: Date(), moodType: MoodType.good.rawValue, note: "Test")
        try moodStore.save(moodEntry)
        
        // Generate report
        viewModel.generateReport()
        
        // Verify mood distribution data
        let distributionData = viewModel.moodDistributionData
        XCTAssertEqual(distributionData.count, 1)
        XCTAssertEqual(distributionData[0].0, .good)
        XCTAssertEqual(distributionData[0].1, 1)
    }
    
    func testGoalProgressData() throws {
        // Create test goal
        let goal = Goal(title: "Test Goal", description: "Test", frequency: .daily, targetCount: 2)
        goal.currentCount = 1
        try goalStore.save(goal)
        
        // Generate report
        viewModel.generateReport()
        
        // Verify goal progress data
        let progressData = viewModel.goalProgressData
        XCTAssertEqual(progressData.count, 1)
        XCTAssertEqual(progressData[0].0.title, "Test Goal")
        XCTAssertEqual(progressData[0].1, 0.5)
    }
    
    func testAverageMoodColor() throws {
        // Test different mood values
        let testCases: [(Double, Color)] = [
            (1.0, .red),
            (2.5, .orange),
            (3.5, .yellow),
            (4.5, .green)
        ]
        
        for (mood, expectedColor) in testCases {
            // Create test data
            let moodEntry = MoodEntry(
                date: Date(),
                moodType: MoodType.allCases[Int(mood) - 1].rawValue,
                note: "Test"
            )
            try moodStore.save(moodEntry)
            
            // Generate report
            viewModel.generateReport()
            
            // Verify color
            XCTAssertEqual(viewModel.averageMoodColor, expectedColor)
        }
    }
} 
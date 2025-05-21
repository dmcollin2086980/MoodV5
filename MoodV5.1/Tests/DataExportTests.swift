import XCTest
@testable import MoodV5_1

final class DataExportTests: XCTestCase {
    var moodStore: RealmMoodStore!
    var goalStore: RealmGoalStore!
    var settingsStore: RealmSettingsStore!
    var dataExportService: DataExportService!
    var viewModel: DataExportViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        moodStore = try! RealmMoodStore()
        goalStore = try! RealmGoalStore()
        settingsStore = try! RealmSettingsStore()
        dataExportService = DataExportService(
            moodStore: moodStore,
            goalStore: goalStore,
            settingsStore: settingsStore
        )
        viewModel = DataExportViewModel(dataExportService: dataExportService)
    }
    
    override func tearDown() {
        viewModel = nil
        dataExportService = nil
        settingsStore = nil
        goalStore = nil
        moodStore = nil
        super.tearDown()
    }
    
    func testExportData() throws {
        // Create test data
        let moodEntry = MoodEntry(date: Date(), moodType: MoodType.good.rawValue, note: "Test")
        try moodStore.save(moodEntry)
        
        let goal = Goal(title: "Test Goal", description: "Test", frequency: .daily, targetCount: 1)
        try goalStore.save(goal)
        
        // Test JSON export
        viewModel.exportFormat = .json
        viewModel.exportData()
        
        XCTAssertNotNil(viewModel.exportData)
        
        // Verify exported data
        let exportData = try JSONDecoder().decode(ExportData.self, from: viewModel.exportData!)
        XCTAssertEqual(exportData.moodEntries.count, 1)
        XCTAssertEqual(exportData.goals.count, 1)
        XCTAssertEqual(exportData.moodEntries[0].moodType, MoodType.good.rawValue)
        XCTAssertEqual(exportData.goals[0].title, "Test Goal")
    }
    
    func testImportData() throws {
        // Create test export data
        let exportData = ExportData(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            exportDate: Date(),
            moodEntries: [
                ExportData.MoodEntryExport(
                    id: "1",
                    date: Date(),
                    moodType: MoodType.good.rawValue,
                    note: "Test"
                )
            ],
            goals: [
                ExportData.GoalExport(
                    id: "1",
                    title: "Test Goal",
                    description: "Test",
                    frequency: GoalFrequency.daily.rawValue,
                    targetCount: 1,
                    currentCount: 0,
                    startDate: Date(),
                    lastCompletedDate: nil,
                    isCompleted: false
                )
            ],
            settings: ExportData.UserSettingsExport(
                reminderEnabled: true,
                reminderTime: Date(),
                darkModeEnabled: true,
                notificationsEnabled: true,
                weeklyReportEnabled: true,
                defaultMoodNote: "Test",
                lastBackupDate: nil,
                autoBackupEnabled: true
            )
        )
        
        // Export to JSON
        let jsonData = try JSONEncoder().encode(exportData)
        
        // Import the data
        viewModel.exportFormat = .json
        viewModel.importData(jsonData)
        
        // Verify imported data
        let importedMoodEntries = moodStore.fetchAllEntries()
        let importedGoals = goalStore.fetchAllGoals()
        let importedSettings = settingsStore.fetchSettings()
        
        XCTAssertEqual(importedMoodEntries.count, 1)
        XCTAssertEqual(importedGoals.count, 1)
        XCTAssertEqual(importedMoodEntries[0].moodType, MoodType.good.rawValue)
        XCTAssertEqual(importedGoals[0].title, "Test Goal")
        XCTAssertTrue(importedSettings.reminderEnabled)
        XCTAssertTrue(importedSettings.darkModeEnabled)
    }
    
    func testInvalidImportData() {
        // Test with invalid JSON
        let invalidData = "invalid json".data(using: .utf8)!
        
        viewModel.exportFormat = .json
        viewModel.importData(invalidData)
        
        XCTAssertNotNil(viewModel.error)
    }
    
    func testVersionCompatibility() throws {
        // Create export data with different version
        let exportData = ExportData(
            version: "0.0.0", // Different version
            exportDate: Date(),
            moodEntries: [],
            goals: [],
            settings: ExportData.UserSettingsExport(
                reminderEnabled: false,
                reminderTime: nil,
                darkModeEnabled: false,
                notificationsEnabled: true,
                weeklyReportEnabled: true,
                defaultMoodNote: "",
                lastBackupDate: nil,
                autoBackupEnabled: false
            )
        )
        
        let jsonData = try JSONEncoder().encode(exportData)
        
        viewModel.exportFormat = .json
        viewModel.importData(jsonData)
        
        XCTAssertNotNil(viewModel.error)
    }
    
    func testExportFormat() {
        // Test JSON format
        viewModel.exportFormat = .json
        XCTAssertEqual(viewModel.exportUTType, .json)
        XCTAssertEqual(viewModel.exportFileName.hasSuffix(".json"), true)
        
        // Test CSV format
        viewModel.exportFormat = .csv
        XCTAssertEqual(viewModel.exportUTType, .commaSeparatedText)
        XCTAssertEqual(viewModel.exportFileName.hasSuffix(".csv"), true)
    }
} 
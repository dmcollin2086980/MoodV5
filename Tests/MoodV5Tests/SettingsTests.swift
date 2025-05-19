import XCTest
@testable import MoodV5

final class SettingsTests: XCTestCase {
    var settingsStore: RealmSettingsStore!
    var viewModel: SettingsViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        settingsStore = try! RealmSettingsStore()
        viewModel = SettingsViewModel(settingsStore: settingsStore)
    }
    
    override func tearDown() {
        viewModel = nil
        settingsStore = nil
        super.tearDown()
    }
    
    func testDefaultSettings() {
        let settings = viewModel.settings
        
        XCTAssertFalse(settings.reminderEnabled)
        XCTAssertNil(settings.reminderTime)
        XCTAssertFalse(settings.darkModeEnabled)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.weeklyReportEnabled)
        XCTAssertEqual(settings.defaultMoodNote, "")
        XCTAssertNil(settings.lastBackupDate)
        XCTAssertFalse(settings.autoBackupEnabled)
    }
    
    func testToggleReminder() {
        XCTAssertFalse(viewModel.settings.reminderEnabled)
        
        viewModel.toggleReminder()
        XCTAssertTrue(viewModel.settings.reminderEnabled)
        
        viewModel.toggleReminder()
        XCTAssertFalse(viewModel.settings.reminderEnabled)
    }
    
    func testUpdateReminderTime() {
        let testTime = Date()
        viewModel.updateReminderTime(testTime)
        
        XCTAssertEqual(viewModel.settings.reminderTime, testTime)
    }
    
    func testToggleDarkMode() {
        XCTAssertFalse(viewModel.settings.darkModeEnabled)
        
        viewModel.toggleDarkMode()
        XCTAssertTrue(viewModel.settings.darkModeEnabled)
        
        viewModel.toggleDarkMode()
        XCTAssertFalse(viewModel.settings.darkModeEnabled)
    }
    
    func testUpdateDefaultMoodNote() {
        let testNote = "Feeling great!"
        viewModel.updateDefaultMoodNote(testNote)
        
        XCTAssertEqual(viewModel.settings.defaultMoodNote, testNote)
    }
    
    func testToggleAutoBackup() {
        XCTAssertFalse(viewModel.settings.autoBackupEnabled)
        
        viewModel.toggleAutoBackup()
        XCTAssertTrue(viewModel.settings.autoBackupEnabled)
        
        viewModel.toggleAutoBackup()
        XCTAssertFalse(viewModel.settings.autoBackupEnabled)
    }
    
    func testResetToDefaults() {
        // Modify settings
        viewModel.toggleReminder()
        viewModel.toggleDarkMode()
        viewModel.updateDefaultMoodNote("Test note")
        
        // Reset to defaults
        viewModel.resetToDefaults()
        
        // Verify settings are back to defaults
        XCTAssertFalse(viewModel.settings.reminderEnabled)
        XCTAssertFalse(viewModel.settings.darkModeEnabled)
        XCTAssertEqual(viewModel.settings.defaultMoodNote, "")
    }
    
    func testSettingsPersistence() {
        // Create new settings
        let testTime = Date()
        viewModel.updateReminderTime(testTime)
        viewModel.toggleReminder()
        
        // Create new view model to test persistence
        let newViewModel = SettingsViewModel(settingsStore: settingsStore)
        
        // Verify settings persisted
        XCTAssertTrue(newViewModel.settings.reminderEnabled)
        XCTAssertEqual(newViewModel.settings.reminderTime, testTime)
    }
} 
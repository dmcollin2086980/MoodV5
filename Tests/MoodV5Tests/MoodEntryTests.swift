import XCTest
@testable import MoodV5

final class MoodEntryTests: XCTestCase {
    var moodStore: RealmMoodStore!
    
    override func setUp() {
        super.setUp()
        // Use in-memory Realm for testing
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        moodStore = try! RealmMoodStore()
    }
    
    override func tearDown() {
        moodStore = nil
        super.tearDown()
    }
    
    func testMoodEntryCreation() {
        let entry = MoodEntry(moodType: .good, note: "Feeling good", tags: ["Work"])
        
        XCTAssertEqual(entry.moodType, MoodType.good.rawValue)
        XCTAssertEqual(entry.note, "Feeling good")
        XCTAssertEqual(entry.tags.count, 1)
        XCTAssertEqual(entry.tags.first, "Work")
    }
    
    func testMoodStoreSaveAndFetch() throws {
        let entry = MoodEntry(moodType: .great, note: "Excellent day", tags: ["Family"])
        
        try moodStore.save(entry)
        
        let entries = moodStore.fetchAllEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.moodType, MoodType.great.rawValue)
        XCTAssertEqual(entries.first?.note, "Excellent day")
    }
    
    func testMoodEntryViewModel() {
        let viewModel = MoodEntryViewModel(moodStore: moodStore)
        
        XCTAssertFalse(viewModel.isSaveEnabled)
        
        viewModel.selectedMood = .good
        XCTAssertTrue(viewModel.isSaveEnabled)
        
        viewModel.note = "Test note"
        viewModel.selectedTags = ["Test"]
        
        viewModel.saveMood()
        
        let entries = moodStore.fetchAllEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.moodType, MoodType.good.rawValue)
        XCTAssertEqual(entries.first?.note, "Test note")
        XCTAssertEqual(entries.first?.tags.count, 1)
    }
} 
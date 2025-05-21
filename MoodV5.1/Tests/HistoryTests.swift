import XCTest
@testable import MoodV5_1

final class HistoryTests: XCTestCase {
    var moodStore: RealmMoodStore!
    var viewModel: HistoryViewModel!
    
    override func setUp() {
        super.setUp()
        let config = Realm.Configuration(inMemoryIdentifier: "test")
        moodStore = try! RealmMoodStore()
        viewModel = HistoryViewModel(moodStore: moodStore)
    }
    
    override func tearDown() {
        viewModel = nil
        moodStore = nil
        super.tearDown()
    }
    
    func testTimeFrameFiltering() throws {
        // Create entries for different time periods
        let now = Date()
        let calendar = Calendar.current
        
        // Create an entry from yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let entry1 = MoodEntry(moodType: .good, note: "Yesterday", tags: [])
        entry1.date = yesterday
        
        // Create an entry from last month
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let entry2 = MoodEntry(moodType: .great, note: "Last Month", tags: [])
        entry2.date = lastMonth
        
        // Save entries
        try moodStore.save(entry1)
        try moodStore.save(entry2)
        
        // Test week filter
        viewModel.selectedTimeFrame = .week
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 1)
        XCTAssertEqual(viewModel.entries.first?.note, "Yesterday")
        
        // Test month filter
        viewModel.selectedTimeFrame = .month
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 2)
        
        // Test all time filter
        viewModel.selectedTimeFrame = .all
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 2)
    }
    
    func testDeleteEntry() throws {
        let entry = MoodEntry(moodType: .good, note: "Test", tags: [])
        try moodStore.save(entry)
        
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 1)
        
        viewModel.deleteEntry(entry)
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 0)
    }
    
    func testEmptyState() {
        viewModel.refreshEntries()
        XCTAssertEqual(viewModel.entries.count, 0)
    }
} 
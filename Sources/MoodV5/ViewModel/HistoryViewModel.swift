import Foundation
import Combine

class HistoryViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var selectedTimeFrame: TimeFrame = .week
    @Published var isLoading = false
    @Published var error: Error?
    
    private let moodStore: MoodStore
    private var cancellables = Set<AnyCancellable>()
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        
        var dateRange: (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                let start = calendar.date(byAdding: .day, value: -7, to: now)!
                return (start, now)
            case .month:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                return (start, now)
            case .year:
                let start = calendar.date(byAdding: .year, value: -1, to: now)!
                return (start, now)
            case .all:
                return nil
            }
        }
    }
    
    init(moodStore: MoodStore) {
        self.moodStore = moodStore
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        moodStore.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.updateEntries(entries)
            }
            .store(in: &cancellables)
    }
    
    private func updateEntries(_ allEntries: [MoodEntry]) {
        guard let dateRange = selectedTimeFrame.dateRange else {
            entries = allEntries
            return
        }
        
        entries = allEntries.filter { entry in
            entry.date >= dateRange.start && entry.date <= dateRange.end
        }
    }
    
    func deleteEntry(_ entry: MoodEntry) {
        do {
            try moodStore.delete(entry: entry)
        } catch {
            self.error = error
        }
    }
    
    func refreshEntries() {
        isLoading = true
        if let dateRange = selectedTimeFrame.dateRange {
            entries = moodStore.fetchEntries(from: dateRange.start, to: dateRange.end)
        } else {
            entries = moodStore.fetchAllEntries()
        }
        isLoading = false
    }
} 
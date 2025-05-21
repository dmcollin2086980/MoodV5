import Foundation
import RealmSwift
import Combine

protocol MoodStore {
    func save(_ moodEntry: MoodEntry) throws
    func fetchAllEntries() -> [MoodEntry]
    func fetchEntries(from date: Date, to date: Date) -> [MoodEntry]
    func delete(entry: MoodEntry) throws
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> { get }
}

class RealmMoodStore: MoodStore {
    private let realm: Realm
    private let entriesSubject = CurrentValueSubject<[MoodEntry], Never>([])
    
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }
    
    init() throws {
        realm = try Realm()
        setupNotificationToken()
    }
    
    private func setupNotificationToken() {
        let entries = realm.objects(MoodEntry.self)
        entriesSubject.send(Array(entries))
        
        _ = entries.observe { [weak self] changes in
            switch changes {
            case .initial(let entries):
                self?.entriesSubject.send(Array(entries))
            case .update(let entries, _, _, _):
                self?.entriesSubject.send(Array(entries))
            case .error(let error):
                print("Error observing entries: \(error)")
            }
        }
    }
    
    func save(_ moodEntry: MoodEntry) throws {
        try realm.write {
            realm.add(moodEntry)
        }
    }
    
    func fetchAllEntries() -> [MoodEntry] {
        Array(realm.objects(MoodEntry.self).sorted(byKeyPath: "date", ascending: false))
    }
    
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        return Array(realm.objects(MoodEntry.self).filter(predicate).sorted(byKeyPath: "date", ascending: false))
    }
    
    func delete(entry: MoodEntry) throws {
        try realm.write {
            realm.delete(entry)
        }
    }
} 
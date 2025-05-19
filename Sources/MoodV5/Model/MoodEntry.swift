import Foundation
import RealmSwift

enum MoodType: String, CaseIterable, Codable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case bad = "Bad"
    case terrible = "Terrible"
    
    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😕"
        case .terrible: return "😢"
        }
    }
}

class MoodEntry: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var date: Date
    @Persisted var moodType: String
    @Persisted var note: String?
    @Persisted var tags: List<String>
    
    convenience init(moodType: MoodType, note: String? = nil, tags: [String] = []) {
        self.init()
        self.id = ObjectId.generate()
        self.date = Date()
        self.moodType = moodType.rawValue
        self.note = note
        self.tags.append(objectsIn: tags)
    }
} 
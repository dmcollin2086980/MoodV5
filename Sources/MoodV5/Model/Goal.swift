import Foundation
import RealmSwift

enum GoalFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var description: String {
        switch self {
        case .daily: return "Every day"
        case .weekly: return "Every week"
        case .monthly: return "Every month"
        }
    }
}

class GoalCompletion: Object {
    @Persisted var date: Date
    
    override init() {
        super.init()
    }
    
    convenience init(date: Date) {
        self.init()
        self.date = date
    }
}

class Goal: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var description: String
    @Persisted var frequency: String
    @Persisted var targetCount: Int
    @Persisted var currentCount: Int
    @Persisted var startDate: Date
    @Persisted var lastCompletedDate: Date?
    @Persisted var isCompleted = false
    @Persisted var completions = List<GoalCompletion>()
    
    override init() {
        super.init()
    }
    
    convenience init(title: String, description: String, frequency: GoalFrequency, targetCount: Int) {
        self.init()
        self.id = ObjectId.generate()
        self.title = title
        self.description = description
        self.frequency = frequency.rawValue
        self.targetCount = targetCount
        self.currentCount = 0
        self.startDate = Date()
    }
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentCount) / Double(targetCount)
    }
    
    var isOverdue: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch GoalFrequency(rawValue: frequency) ?? .daily {
        case .daily:
            return !calendar.isDateInToday(lastCompleted)
        case .weekly:
            return calendar.dateComponents([.day], from: lastCompleted, to: now).day ?? 0 > 7
        case .monthly:
            return calendar.dateComponents([.month], from: lastCompleted, to: now).month ?? 0 > 0
        }
    }
    
    func incrementProgress() {
        currentCount += 1
        lastCompletedDate = Date()
        
        if currentCount >= targetCount {
            isCompleted = true
        }
    }
    
    func resetProgress() {
        currentCount = 0
        isCompleted = false
    }
} 
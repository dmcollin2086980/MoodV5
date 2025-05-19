import Foundation
import RealmSwift

class UserSettings: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var reminderEnabled = false
    @Persisted var reminderTime: Date?
    @Persisted var darkModeEnabled = false
    @Persisted var notificationsEnabled = true
    @Persisted var weeklyReportEnabled = true
    @Persisted var defaultMoodNote = ""
    @Persisted var lastBackupDate: Date?
    @Persisted var autoBackupEnabled = false
    
    override init() {
        super.init()
        self.id = ObjectId.generate()
    }
    
    // Computed properties for convenience
    var formattedReminderTime: String {
        guard let time = reminderTime else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    var hasCompletedOnboarding: Bool {
        // This will be used to track if the user has completed the initial setup
        return reminderTime != nil
    }
} 
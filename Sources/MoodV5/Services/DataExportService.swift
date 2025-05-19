import Foundation
import RealmSwift

enum ExportFormat {
    case json
    case csv
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let moodEntries: [MoodEntryExport]
    let goals: [GoalExport]
    let settings: UserSettingsExport
    
    struct MoodEntryExport: Codable {
        let id: String
        let date: Date
        let moodType: String
        let note: String
        
        init(from entry: MoodEntry) {
            self.id = entry.id.stringValue
            self.date = entry.date
            self.moodType = entry.moodType
            self.note = entry.note
        }
    }
    
    struct GoalExport: Codable {
        let id: String
        let title: String
        let description: String
        let frequency: String
        let targetCount: Int
        let currentCount: Int
        let startDate: Date
        let lastCompletedDate: Date?
        let isCompleted: Bool
        
        init(from goal: Goal) {
            self.id = goal.id.stringValue
            self.title = goal.title
            self.description = goal.description
            self.frequency = goal.frequency
            self.targetCount = goal.targetCount
            self.currentCount = goal.currentCount
            self.startDate = goal.startDate
            self.lastCompletedDate = goal.lastCompletedDate
            self.isCompleted = goal.isCompleted
        }
    }
    
    struct UserSettingsExport: Codable {
        let reminderEnabled: Bool
        let reminderTime: Date?
        let darkModeEnabled: Bool
        let notificationsEnabled: Bool
        let weeklyReportEnabled: Bool
        let defaultMoodNote: String
        let lastBackupDate: Date?
        let autoBackupEnabled: Bool
        
        init(from settings: UserSettings) {
            self.reminderEnabled = settings.reminderEnabled
            self.reminderTime = settings.reminderTime
            self.darkModeEnabled = settings.darkModeEnabled
            self.notificationsEnabled = settings.notificationsEnabled
            self.weeklyReportEnabled = settings.weeklyReportEnabled
            self.defaultMoodNote = settings.defaultMoodNote
            self.lastBackupDate = settings.lastBackupDate
            self.autoBackupEnabled = settings.autoBackupEnabled
        }
    }
}

class DataExportService {
    private let moodStore: MoodStore
    private let goalStore: GoalStore
    private let settingsStore: SettingsStore
    
    init(moodStore: MoodStore, goalStore: GoalStore, settingsStore: SettingsStore) {
        self.moodStore = moodStore
        self.goalStore = goalStore
        self.settingsStore = settingsStore
    }
    
    func exportData(format: ExportFormat) throws -> Data {
        let exportData = ExportData(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            exportDate: Date(),
            moodEntries: moodStore.fetchAllEntries().map(ExportData.MoodEntryExport.init),
            goals: goalStore.fetchAllGoals().map(ExportData.GoalExport.init),
            settings: ExportData.UserSettingsExport(from: settingsStore.fetchSettings())
        )
        
        switch format {
        case .json:
            return try JSONEncoder().encode(exportData)
        case .csv:
            return try generateCSV(from: exportData)
        }
    }
    
    func importData(_ data: Data, format: ExportFormat) throws {
        let exportData: ExportData
        
        switch format {
        case .json:
            exportData = try JSONDecoder().decode(ExportData.self, from: data)
        case .csv:
            exportData = try parseCSV(data)
        }
        
        // Validate data
        try validateImportData(exportData)
        
        // Import data
        try importMoodEntries(exportData.moodEntries)
        try importGoals(exportData.goals)
        try importSettings(exportData.settings)
    }
    
    private func generateCSV(from data: ExportData) throws -> Data {
        var csvString = "version,exportDate\n"
        csvString += "\(data.version),\(data.exportDate.formatted())\n\n"
        
        // Mood entries
        csvString += "moodEntries\n"
        csvString += "id,date,moodType,note\n"
        for entry in data.moodEntries {
            csvString += "\(entry.id),\(entry.date.formatted()),\(entry.moodType),\(entry.note)\n"
        }
        
        // Goals
        csvString += "\ngoals\n"
        csvString += "id,title,description,frequency,targetCount,currentCount,startDate,lastCompletedDate,isCompleted\n"
        for goal in data.goals {
            let lastCompletedStr = goal.lastCompletedDate?.formatted() ?? ""
            csvString += "\(goal.id),\(goal.title),\(goal.description),\(goal.frequency),\(goal.targetCount),\(goal.currentCount),\(goal.startDate.formatted()),\(lastCompletedStr),\(goal.isCompleted)\n"
        }
        
        // Settings
        csvString += "\nsettings\n"
        csvString += "reminderEnabled,reminderTime,darkModeEnabled,notificationsEnabled,weeklyReportEnabled,defaultMoodNote,lastBackupDate,autoBackupEnabled\n"
        let settings = data.settings
        let reminderTimeStr = settings.reminderTime?.formatted() ?? ""
        let lastBackupStr = settings.lastBackupDate?.formatted() ?? ""
        csvString += "\(settings.reminderEnabled),\(reminderTimeStr),\(settings.darkModeEnabled),\(settings.notificationsEnabled),\(settings.weeklyReportEnabled),\(settings.defaultMoodNote),\(lastBackupStr),\(settings.autoBackupEnabled)\n"
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func parseCSV(_ data: Data) throws -> ExportData {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV data"])
        }
        
        // Split the CSV into sections
        let sections = csvString.components(separatedBy: "\n\n")
        guard sections.count >= 4 else {
            throw NSError(domain: "DataExportService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV format"])
        }
        
        // Parse version and export date
        let headerLines = sections[0].components(separatedBy: "\n")
        guard headerLines.count >= 2 else {
            throw NSError(domain: "DataExportService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid header format"])
        }
        
        let version = headerLines[1].components(separatedBy: ",")[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        guard let exportDate = dateFormatter.date(from: headerLines[1].components(separatedBy: ",")[1]) else {
            throw NSError(domain: "DataExportService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid export date"])
        }
        
        // Parse mood entries
        let moodEntryLines = sections[1].components(separatedBy: "\n")
        var moodEntries: [ExportData.MoodEntryExport] = []
        
        for line in moodEntryLines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ",")
            guard components.count >= 4,
                  let date = dateFormatter.date(from: components[1]) else { continue }
            
            let entry = ExportData.MoodEntryExport(
                id: components[0],
                date: date,
                moodType: components[2],
                note: components[3]
            )
            moodEntries.append(entry)
        }
        
        // Parse goals
        let goalLines = sections[2].components(separatedBy: "\n")
        var goals: [ExportData.GoalExport] = []
        
        for line in goalLines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ",")
            guard components.count >= 9,
                  let targetCount = Int(components[4]),
                  let currentCount = Int(components[5]),
                  let startDate = dateFormatter.date(from: components[6]),
                  let isCompleted = Bool(components[8]) else { continue }
            
            let lastCompletedDate = components[7].isEmpty ? nil : dateFormatter.date(from: components[7])
            
            let goal = ExportData.GoalExport(
                id: components[0],
                title: components[1],
                description: components[2],
                frequency: components[3],
                targetCount: targetCount,
                currentCount: currentCount,
                startDate: startDate,
                lastCompletedDate: lastCompletedDate,
                isCompleted: isCompleted
            )
            goals.append(goal)
        }
        
        // Parse settings
        let settingsLines = sections[3].components(separatedBy: "\n")
        guard settingsLines.count >= 2 else {
            throw NSError(domain: "DataExportService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid settings format"])
        }
        
        let settingsComponents = settingsLines[1].components(separatedBy: ",")
        guard settingsComponents.count >= 8,
              let reminderEnabled = Bool(settingsComponents[0]),
              let darkModeEnabled = Bool(settingsComponents[2]),
              let notificationsEnabled = Bool(settingsComponents[3]),
              let weeklyReportEnabled = Bool(settingsComponents[4]),
              let autoBackupEnabled = Bool(settingsComponents[7]) else {
            throw NSError(domain: "DataExportService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid settings data"])
        }
        
        let reminderTime = settingsComponents[1].isEmpty ? nil : dateFormatter.date(from: settingsComponents[1])
        let lastBackupDate = settingsComponents[6].isEmpty ? nil : dateFormatter.date(from: settingsComponents[6])
        
        let settings = ExportData.UserSettingsExport(
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            darkModeEnabled: darkModeEnabled,
            notificationsEnabled: notificationsEnabled,
            weeklyReportEnabled: weeklyReportEnabled,
            defaultMoodNote: settingsComponents[5],
            lastBackupDate: lastBackupDate,
            autoBackupEnabled: autoBackupEnabled
        )
        
        return ExportData(
            version: version,
            exportDate: exportDate,
            moodEntries: moodEntries,
            goals: goals,
            settings: settings
        )
    }
    
    private func validateImportData(_ data: ExportData) throws {
        // Validate version compatibility
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        if data.version != currentVersion {
            throw NSError(domain: "DataExportService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Incompatible data version"])
        }
        
        // Validate data integrity
        for entry in data.moodEntries {
            guard MoodType(rawValue: entry.moodType) != nil else {
                throw NSError(domain: "DataExportService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid mood type in import data"])
            }
        }
        
        for goal in data.goals {
            guard GoalFrequency(rawValue: goal.frequency) != nil else {
                throw NSError(domain: "DataExportService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid goal frequency in import data"])
            }
        }
    }
    
    private func importMoodEntries(_ entries: [ExportData.MoodEntryExport]) throws {
        for entry in entries {
            let moodEntry = MoodEntry(
                date: entry.date,
                moodType: entry.moodType,
                note: entry.note
            )
            try moodStore.save(moodEntry)
        }
    }
    
    private func importGoals(_ goals: [ExportData.GoalExport]) throws {
        for goal in goals {
            let newGoal = Goal(
                title: goal.title,
                description: goal.description,
                frequency: GoalFrequency(rawValue: goal.frequency) ?? .daily,
                targetCount: goal.targetCount
            )
            newGoal.currentCount = goal.currentCount
            newGoal.lastCompletedDate = goal.lastCompletedDate
            newGoal.isCompleted = goal.isCompleted
            try goalStore.save(newGoal)
        }
    }
    
    private func importSettings(_ settings: ExportData.UserSettingsExport) throws {
        let currentSettings = self.settingsStore.fetchSettings()
        currentSettings.reminderEnabled = settings.reminderEnabled
        currentSettings.reminderTime = settings.reminderTime
        currentSettings.darkModeEnabled = settings.darkModeEnabled
        currentSettings.notificationsEnabled = settings.notificationsEnabled
        currentSettings.weeklyReportEnabled = settings.weeklyReportEnabled
        currentSettings.defaultMoodNote = settings.defaultMoodNote
        currentSettings.lastBackupDate = settings.lastBackupDate
        currentSettings.autoBackupEnabled = settings.autoBackupEnabled
        try self.settingsStore.update(currentSettings)
    }
} 
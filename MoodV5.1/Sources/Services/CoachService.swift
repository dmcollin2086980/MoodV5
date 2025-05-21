import Foundation
import Combine

struct CoachingInsight {
    let title: String
    let message: String
    let type: InsightType
    let action: String?
    
    enum InsightType {
        case positive
        case neutral
        case improvement
    }
}

class CoachService {
    private let moodStore: MoodStore
    
    init(moodStore: MoodStore) {
        self.moodStore = moodStore
    }
    
    func generateDailyInsight() -> CoachingInsight {
        let entries = moodStore.fetchAllEntries()
        let recentEntries = getRecentEntries(entries, days: 7)
        
        if recentEntries.isEmpty {
            return CoachingInsight(
                title: "Welcome! 👋",
                message: "Start tracking your mood to receive personalized insights and tips.",
                type: .neutral,
                action: "Log your first mood"
            )
        }
        
        // Analyze mood patterns
        if let pattern = analyzeMoodPattern(recentEntries) {
            return pattern
        }
        
        // Check for streaks
        if let streak = analyzeStreak(recentEntries) {
            return streak
        }
        
        // Check for mood improvement
        if let improvement = analyzeMoodImprovement(recentEntries) {
            return improvement
        }
        
        // Default insight
        return CoachingInsight(
            title: "Keep Going! 💪",
            message: "Consistency is key to understanding your mood patterns. Try to log your mood daily.",
            type: .neutral,
            action: "Log today's mood"
        )
    }
    
    private func getRecentEntries(_ entries: [MoodEntry], days: Int) -> [MoodEntry] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return entries.filter { $0.date >= startDate }
            .sorted { $0.date > $1.date }
    }
    
    private func analyzeMoodPattern(_ entries: [MoodEntry]) -> CoachingInsight? {
        guard entries.count >= 3 else { return nil }
        
        let recentMoods = entries.prefix(3).map { MoodType(rawValue: $0.moodType) ?? .okay }
        
        // Check for consecutive negative moods
        if recentMoods.allSatisfy({ $0 == .bad || $0 == .terrible }) {
            return CoachingInsight(
                title: "Rough Patch 😔",
                message: "I notice you've been feeling down lately. Remember, it's okay to not be okay. Consider reaching out to friends or trying some self-care activities.",
                type: .improvement,
                action: "Try a mood-lifting activity"
            )
        }
        
        // Check for consecutive positive moods
        if recentMoods.allSatisfy({ $0 == .great || $0 == .good }) {
            return CoachingInsight(
                title: "On a Roll! 🌟",
                message: "You're doing great! Keep up the positive momentum. What's been contributing to your good mood?",
                type: .positive,
                action: "Reflect on what's working"
            )
        }
        
        return nil
    }
    
    private func analyzeStreak(_ entries: [MoodEntry]) -> CoachingInsight? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check for daily logging streak
        var streakCount = 0
        var currentDate = today
        
        for entry in entries {
            let entryDate = calendar.startOfDay(for: entry.date)
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                continue
            }
            
            let daysBetween = calendar.dateComponents([.day], from: entryDate, to: currentDate).day ?? 0
            if daysBetween == 1 {
                streakCount += 1
                currentDate = entryDate
            } else {
                break
            }
        }
        
        if streakCount >= 3 {
            return CoachingInsight(
                title: "Impressive Streak! 🔥",
                message: "You've logged your mood for \(streakCount) days in a row! This consistency will help you better understand your mood patterns.",
                type: .positive,
                action: "Keep the streak going"
            )
        }
        
        return nil
    }
    
    private func analyzeMoodImprovement(_ entries: [MoodEntry]) -> CoachingInsight? {
        guard entries.count >= 2 else { return nil }
        
        let recentMood = MoodType(rawValue: entries[0].moodType) ?? .okay
        let previousMood = MoodType(rawValue: entries[1].moodType) ?? .okay
        
        if recentMood.rawValue > previousMood.rawValue {
            return CoachingInsight(
                title: "Mood Lift! 📈",
                message: "Your mood has improved since your last entry. What helped with this positive change?",
                type: .positive,
                action: "Reflect on what helped"
            )
        }
        
        return nil
    }
} 
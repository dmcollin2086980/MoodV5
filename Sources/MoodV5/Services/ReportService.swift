import Foundation
import RealmSwift

struct WeeklyReport {
    let startDate: Date
    let endDate: Date
    let moodDistribution: [MoodType: Int]
    let averageMood: Double
    let mostFrequentMood: MoodType
    let goalProgress: [GoalProgress]
    let insights: [String]
    let recommendations: [String]
    let moodTrends: MoodTrends
    let patternAnalysis: PatternAnalysis
    
    struct GoalProgress {
        let goal: Goal
        let completionRate: Double
        let streak: Int
        let impactOnMood: Double?
    }
    
    struct MoodTrends {
        let dailyAverages: [(Date, Double)]
        let trendDirection: TrendDirection
        let consistencyScore: Double
        let peakMoodTime: Date?
        let lowMoodTime: Date?
        let timeOfDayAnalysis: TimeOfDayAnalysis
        
        enum TrendDirection {
            case improving
            case declining
            case stable
            case fluctuating
        }
        
        struct TimeOfDayAnalysis {
            let morningAverage: Double
            let afternoonAverage: Double
            let eveningAverage: Double
            let bestTimeOfDay: TimeOfDay
            let worstTimeOfDay: TimeOfDay
            
            enum TimeOfDay {
                case morning
                case afternoon
                case evening
            }
        }
    }
    
    struct PatternAnalysis {
        let recurringPatterns: [RecurringPattern]
        let goalMoodCorrelations: [GoalMoodCorrelation]
        let weeklyPatterns: [WeeklyPattern]
        
        struct RecurringPattern {
            let pattern: String
            let frequency: Int
            let confidence: Double
        }
        
        struct GoalMoodCorrelation {
            let goal: Goal
            let correlation: Double
            let impact: Impact
            
            enum Impact {
                case positive
                case negative
                case neutral
            }
        }
        
        struct WeeklyPattern {
            let dayOfWeek: Int
            let averageMood: Double
            let commonActivities: [String]
        }
    }
}

class ReportService {
    private let moodStore: MoodStore
    private let goalStore: GoalStore
    private let coachService: CoachService
    
    init(moodStore: MoodStore, goalStore: GoalStore, coachService: CoachService) {
        self.moodStore = moodStore
        self.goalStore = goalStore
        self.coachService = coachService
    }
    
    func generateWeeklyReport() throws -> WeeklyReport {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate date range for the past week
        guard let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now),
              let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else {
            throw NSError(domain: "ReportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date range"])
        }
        
        // Fetch mood entries for the week
        let entries = moodStore.fetchEntries(from: startDate, to: endDate)
        
        // Calculate mood distribution and averages
        let (moodDistribution, averageMood, mostFrequentMood) = calculateMoodStats(entries: entries)
        
        // Calculate goal progress with streaks and mood impact
        let goalProgress = calculateGoalProgress(from: startDate, to: endDate, entries: entries)
        
        // Calculate mood trends with time of day analysis
        let moodTrends = analyzeMoodTrends(entries: entries, from: startDate, to: endDate)
        
        // Analyze patterns
        let patternAnalysis = analyzePatterns(entries: entries, goals: goalStore.fetchAllGoals(), from: startDate, to: endDate)
        
        // Generate insights and recommendations
        let insights = generateInsights(
            moodDistribution: moodDistribution,
            averageMood: averageMood,
            goalProgress: goalProgress,
            moodTrends: moodTrends,
            patternAnalysis: patternAnalysis
        )
        
        let recommendations = generateRecommendations(
            moodDistribution: moodDistribution,
            averageMood: averageMood,
            goalProgress: goalProgress,
            moodTrends: moodTrends,
            patternAnalysis: patternAnalysis
        )
        
        return WeeklyReport(
            startDate: startDate,
            endDate: endDate,
            moodDistribution: moodDistribution,
            averageMood: averageMood,
            mostFrequentMood: mostFrequentMood,
            goalProgress: goalProgress,
            insights: insights,
            recommendations: recommendations,
            moodTrends: moodTrends,
            patternAnalysis: patternAnalysis
        )
    }
    
    private func calculateMoodStats(entries: [MoodEntry]) -> ([MoodType: Int], Double, MoodType) {
        var moodDistribution: [MoodType: Int] = [:]
        var totalMoodValue = 0
        var entryCount = 0
        
        for entry in entries {
            if let moodType = MoodType(rawValue: entry.moodType) {
                moodDistribution[moodType, default: 0] += 1
                totalMoodValue += Int(moodType.rawValue) ?? 0
                entryCount += 1
            }
        }
        
        let averageMood = entryCount > 0 ? Double(totalMoodValue) / Double(entryCount) : 0
        let mostFrequentMood = moodDistribution.max(by: { $0.value < $1.value })?.key ?? .okay
        
        return (moodDistribution, averageMood, mostFrequentMood)
    }
    
    private func calculateGoalProgress(from startDate: Date, to endDate: Date, entries: [MoodEntry]) -> [WeeklyReport.GoalProgress] {
        let goals = goalStore.fetchAllGoals()
        var goalProgress: [WeeklyReport.GoalProgress] = []
        
        for goal in goals {
            let completionRate = calculateGoalCompletionRate(goal, from: startDate, to: endDate)
            let streak = calculateGoalStreak(goal, from: startDate, to: endDate)
            let impactOnMood = calculateGoalMoodImpact(goal: goal, entries: entries)
            
            goalProgress.append(WeeklyReport.GoalProgress(
                goal: goal,
                completionRate: completionRate,
                streak: streak,
                impactOnMood: impactOnMood
            ))
        }
        
        return goalProgress
    }
    
    private func calculateGoalStreak(_ goal: Goal, from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var currentStreak = 0
        var maxStreak = 0
        var lastDate: Date?
        
        // Get all goal completions within date range
        let completions = goal.completions.filter { completion in
            completion.date >= startDate && completion.date <= endDate
        }.sorted { $0.date < $1.date }
        
        for completion in completions {
            let completionDay = calendar.startOfDay(for: completion.date)
            
            if let last = lastDate {
                let lastDay = calendar.startOfDay(for: last)
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: completionDay).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else {
                    // Streak broken
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = completion.date
        }
        
        // Check final streak
        maxStreak = max(maxStreak, currentStreak)
        return maxStreak
    }
    
    private func calculateGoalMoodImpact(goal: Goal, entries: [MoodEntry]) -> Double? {
        guard !entries.isEmpty else { return nil }
        
        var moodSumWithGoal = 0.0
        var moodSumWithoutGoal = 0.0
        var countWithGoal = 0
        var countWithoutGoal = 0
        
        for entry in entries {
            let day = Calendar.current.startOfDay(for: entry.date)
            let goalCompleted = goal.completions.contains { Calendar.current.startOfDay(for: $0.date) == day }
            
            if let moodType = MoodType(rawValue: entry.moodType) {
                if goalCompleted {
                    moodSumWithGoal += Double(Int(moodType.rawValue) ?? 0)
                    countWithGoal += 1
                } else {
                    moodSumWithoutGoal += Double(Int(moodType.rawValue) ?? 0)
                    countWithoutGoal += 1
                }
            }
        }
        
        guard countWithGoal > 0 && countWithoutGoal > 0 else { return nil }
        
        let avgWithGoal = moodSumWithGoal / Double(countWithGoal)
        let avgWithoutGoal = moodSumWithoutGoal / Double(countWithoutGoal)
        
        return avgWithGoal - avgWithoutGoal
    }
    
    private func analyzeMoodTrends(entries: [MoodEntry], from startDate: Date, to endDate: Date) -> WeeklyReport.MoodTrends {
        let calendar = Calendar.current
        var dailyAverages: [(Date, Double)] = []
        var timeOfDayMoods: [WeeklyReport.MoodTrends.TimeOfDayAnalysis.TimeOfDay: [Double]] = [:]
        
        // Group entries by day and time of day
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            let hour = calendar.component(.hour, from: entry.date)
            
            if let moodType = MoodType(rawValue: entry.moodType) {
                let timeOfDay: WeeklyReport.MoodTrends.TimeOfDayAnalysis.TimeOfDay
                switch hour {
                case 5..<12: timeOfDay = .morning
                case 12..<17: timeOfDay = .afternoon
                default: timeOfDay = .evening
                }
                
                timeOfDayMoods[timeOfDay, default: []].append(Double(Int(moodType.rawValue) ?? 0))
            }
        }
        
        // Calculate daily averages
        for day in stride(from: startDate, through: endDate, by: 86400) {
            let dayStart = calendar.startOfDay(for: day)
            let dayEntries = entries.filter { calendar.startOfDay(for: $0.date) == dayStart }
            
            if !dayEntries.isEmpty {
                let average = dayEntries.compactMap { MoodType(rawValue: $0.moodType)?.rawValue }
                    .compactMap { Int($0) }
                    .map { Double($0) }
                    .reduce(0, +) / Double(dayEntries.count)
                dailyAverages.append((dayStart, average))
            }
        }
        
        // Calculate time of day averages
        let morningAvg = (timeOfDayMoods[.morning]?.reduce(0, +) ?? 0) / Double(timeOfDayMoods[.morning]?.count ?? 1)
        let afternoonAvg = (timeOfDayMoods[.afternoon]?.reduce(0, +) ?? 0) / Double(timeOfDayMoods[.afternoon]?.count ?? 1)
        let eveningAvg = (timeOfDayMoods[.evening]?.reduce(0, +) ?? 0) / Double(timeOfDayMoods[.evening]?.count ?? 1)
        
        let timeOfDayAnalysis = WeeklyReport.MoodTrends.TimeOfDayAnalysis(
            morningAverage: morningAvg,
            afternoonAverage: afternoonAvg,
            eveningAverage: eveningAvg,
            bestTimeOfDay: [.morning: morningAvg, .afternoon: afternoonAvg, .evening: eveningAvg]
                .max(by: { $0.value < $1.value })?.key ?? .morning,
            worstTimeOfDay: [.morning: morningAvg, .afternoon: afternoonAvg, .evening: eveningAvg]
                .min(by: { $0.value < $1.value })?.key ?? .evening
        )
        
        return WeeklyReport.MoodTrends(
            dailyAverages: dailyAverages,
            trendDirection: calculateTrendDirection(dailyAverages: dailyAverages),
            consistencyScore: calculateConsistencyScore(dailyAverages: dailyAverages),
            peakMoodTime: dailyAverages.max(by: { $0.1 < $1.1 })?.0,
            lowMoodTime: dailyAverages.min(by: { $0.1 < $1.1 })?.0,
            timeOfDayAnalysis: timeOfDayAnalysis
        )
    }
    
    private func analyzePatterns(entries: [MoodEntry], goals: [Goal], from startDate: Date, to endDate: Date) -> WeeklyReport.PatternAnalysis {
        // Analyze recurring patterns
        let recurringPatterns = findRecurringPatterns(entries: entries)
        
        // Analyze goal-mood correlations
        let goalMoodCorrelations = analyzeGoalMoodCorrelations(goals: goals, entries: entries)
        
        // Analyze weekly patterns
        let weeklyPatterns = analyzeWeeklyPatterns(entries: entries)
        
        return WeeklyReport.PatternAnalysis(
            recurringPatterns: recurringPatterns,
            goalMoodCorrelations: goalMoodCorrelations,
            weeklyPatterns: weeklyPatterns
        )
    }
    
    private func findRecurringPatterns(entries: [MoodEntry]) -> [WeeklyReport.PatternAnalysis.RecurringPattern] {
        var patterns: [WeeklyReport.PatternAnalysis.RecurringPattern] = []
        
        // Group entries by mood type and time of day
        let calendar = Calendar.current
        var moodTimePatterns: [String: Int] = [:]
        
        for entry in entries {
            if let moodType = MoodType(rawValue: entry.moodType) {
                let hour = calendar.component(.hour, from: entry.date)
                let timeOfDay: String
                switch hour {
                case 5..<12: timeOfDay = "morning"
                case 12..<17: timeOfDay = "afternoon"
                default: timeOfDay = "evening"
                }
                
                let pattern = "\(moodType.rawValue)_\(timeOfDay)"
                moodTimePatterns[pattern, default: 0] += 1
            }
        }
        
        // Convert to recurring patterns
        for (pattern, frequency) in moodTimePatterns {
            if frequency >= 2 { // Only include patterns that occur at least twice
                let components = pattern.split(separator: "_")
                if components.count == 2,
                   let moodType = MoodType(rawValue: String(components[0])) {
                    patterns.append(WeeklyReport.PatternAnalysis.RecurringPattern(
                        pattern: "\(moodType.rawValue) mood in the \(components[1])",
                        frequency: frequency,
                        confidence: Double(frequency) / Double(entries.count)
                    ))
                }
            }
        }
        
        return patterns
    }
    
    private func analyzeGoalMoodCorrelations(goals: [Goal], entries: [MoodEntry]) -> [WeeklyReport.PatternAnalysis.GoalMoodCorrelation] {
        var correlations: [WeeklyReport.PatternAnalysis.GoalMoodCorrelation] = []
        
        for goal in goals {
            if let impact = calculateGoalMoodImpact(goal: goal, entries: entries) {
                let correlation = WeeklyReport.PatternAnalysis.GoalMoodCorrelation(
                    goal: goal,
                    correlation: abs(impact),
                    impact: impact > 0 ? .positive : .negative
                )
                correlations.append(correlation)
            }
        }
        
        return correlations
    }
    
    private func analyzeWeeklyPatterns(entries: [MoodEntry]) -> [WeeklyReport.PatternAnalysis.WeeklyPattern] {
        let calendar = Calendar.current
        var dayPatterns: [Int: (moodSum: Double, count: Int, activities: Set<String>)] = [:]
        
        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.date)
            if let moodType = MoodType(rawValue: entry.moodType) {
                let current = dayPatterns[weekday] ?? (0, 0, [])
                dayPatterns[weekday] = (
                    moodSum: current.moodSum + Double(Int(moodType.rawValue) ?? 0),
                    count: current.count + 1,
                    activities: current.activities.union(entry.tags)
                )
            }
        }
        
        return dayPatterns.map { weekday, data in
            WeeklyReport.PatternAnalysis.WeeklyPattern(
                dayOfWeek: weekday,
                averageMood: data.moodSum / Double(data.count),
                commonActivities: Array(data.activities)
            )
        }
    }
    
    private func calculateTrendDirection(dailyAverages: [(Date, Double)]) -> WeeklyReport.MoodTrends.TrendDirection {
        guard dailyAverages.count >= 2 else { return .stable }
        
        var increasingCount = 0
        var decreasingCount = 0
        var sameCount = 0
        
        for i in 1..<dailyAverages.count {
            let diff = dailyAverages[i].1 - dailyAverages[i-1].1
            if abs(diff) < 0.1 {
                sameCount += 1
            } else if diff > 0 {
                increasingCount += 1
            } else {
                decreasingCount += 1
            }
        }
        
        let total = dailyAverages.count - 1
        if sameCount >= total * 0.7 {
            return .stable
        } else if increasingCount >= total * 0.6 {
            return .improving
        } else if decreasingCount >= total * 0.6 {
            return .declining
        } else {
            return .fluctuating
        }
    }
    
    private func calculateConsistencyScore(dailyAverages: [(Date, Double)]) -> Double {
        guard dailyAverages.count >= 2 else { return 1.0 }
        
        let average = dailyAverages.map { $0.1 }.reduce(0, +) / Double(dailyAverages.count)
        let variance = dailyAverages.map { pow($0.1 - average, 2) }.reduce(0, +) / Double(dailyAverages.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to a 0-1 score where 1 is most consistent
        return max(0, min(1, 1 - (standardDeviation / 2)))
    }
    
    private func calculateGoalCompletionRate(_ goal: Goal, from startDate: Date, to endDate: Date) -> Double {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        switch GoalFrequency(rawValue: goal.frequency) ?? .daily {
        case .daily:
            return Double(goal.currentCount) / Double(days + 1)
        case .weekly:
            return Double(goal.currentCount) / Double(max(1, (days + 1) / 7))
        case .monthly:
            return Double(goal.currentCount) / Double(max(1, (days + 1) / 30))
        }
    }
    
    private func generateInsights(
        moodDistribution: [MoodType: Int],
        averageMood: Double,
        goalProgress: [WeeklyReport.GoalProgress],
        moodTrends: WeeklyReport.MoodTrends,
        patternAnalysis: WeeklyReport.PatternAnalysis
    ) -> [String] {
        var insights: [String] = []
        
        // Mood insights
        if let mostFrequent = moodDistribution.max(by: { $0.value < $1.value }) {
            insights.append("Your most common mood this week was \(mostFrequent.key.rawValue).")
        }
        
        if averageMood > 3.5 {
            insights.append("You've been feeling positive overall this week!")
        } else if averageMood < 2.5 {
            insights.append("You've been feeling down this week. Remember, it's okay to not be okay.")
        }
        
        // Time of day insights
        let timeOfDay = moodTrends.timeOfDayAnalysis
        insights.append("You tend to feel best during the \(timeOfDay.bestTimeOfDay).")
        
        // Pattern insights
        if let strongestPattern = patternAnalysis.recurringPatterns.max(by: { $0.confidence < $1.confidence }) {
            insights.append("You often experience \(strongestPattern.pattern).")
        }
        
        // Goal impact insights
        if let strongestCorrelation = patternAnalysis.goalMoodCorrelations.max(by: { $0.correlation < $1.correlation }) {
            let impact = strongestCorrelation.impact == .positive ? "positively" : "negatively"
            insights.append("Completing '\(strongestCorrelation.goal.title)' \(impact) affects your mood.")
        }
        
        // Weekly pattern insights
        if let bestDay = patternAnalysis.weeklyPatterns.max(by: { $0.averageMood < $1.averageMood }) {
            let weekday = Calendar.current.weekdaySymbols[bestDay.dayOfWeek - 1]
            insights.append("You typically feel best on \(weekday)s.")
        }
        
        return insights
    }
    
    private func generateRecommendations(
        moodDistribution: [MoodType: Int],
        averageMood: Double,
        goalProgress: [WeeklyReport.GoalProgress],
        moodTrends: WeeklyReport.MoodTrends,
        patternAnalysis: WeeklyReport.PatternAnalysis
    ) -> [String] {
        var recommendations: [String] = []
        
        // Mood-based recommendations
        if averageMood < 2.5 {
            recommendations.append("Try to engage in activities that usually lift your mood.")
            recommendations.append("Consider reaching out to friends or family for support.")
        }
        
        // Time of day recommendations
        let timeOfDay = moodTrends.timeOfDayAnalysis
        recommendations.append("Schedule important activities during your best time of day (\(timeOfDay.bestTimeOfDay)).")
        
        // Pattern-based recommendations
        if let strongestPattern = patternAnalysis.recurringPatterns.max(by: { $0.confidence < $1.confidence }) {
            recommendations.append("Be mindful of your \(strongestPattern.pattern) pattern and plan accordingly.")
        }
        
        // Goal-based recommendations
        let lowProgressGoals = goalProgress.filter { $0.completionRate < 0.3 }
        if !lowProgressGoals.isEmpty {
            recommendations.append("Break down your goals into smaller, more manageable steps.")
            recommendations.append("Set reminders to help you stay on track with your goals.")
        }
        
        return recommendations
    }
} 
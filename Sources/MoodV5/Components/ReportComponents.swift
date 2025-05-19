import SwiftUI

// MARK: - Pattern Card
struct PatternCard: View {
    let pattern: WeeklyReport.PatternAnalysis.RecurringPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Recurring Pattern")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(pattern.pattern)
                .font(.body)
            
            Text("Confidence: \(Int(pattern.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Weekly Pattern Card
struct WeeklyPatternCard: View {
    let pattern: WeeklyReport.PatternAnalysis.WeeklyPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Best Day")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(Calendar.current.weekdaySymbols[pattern.dayOfWeek - 1])
                .font(.body)
            
            Text("Average Mood: \(String(format: "%.1f", pattern.averageMood))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !pattern.commonActivities.isEmpty {
                Text("Common Activities:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(pattern.commonActivities.prefix(3), id: \.self) { activity in
                    Text("• \(activity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(text)
                .font(.body)
        }
    }
} 
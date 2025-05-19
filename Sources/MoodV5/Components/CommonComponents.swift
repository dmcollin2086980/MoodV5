import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

// MARK: - Error Alert
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { action() }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Shared Components

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

// MARK: - Time of Day Card
struct TimeOfDayCard: View {
    let title: String
    let average: Double
    let isBest: Bool
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f", average))
                .font(.title2)
                .foregroundColor(moodColor(for: average))
            
            if isBest {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func moodColor(for value: Double) -> Color {
        if value >= 4.0 {
            return .green
        } else if value >= 3.0 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Goal Progress Row
struct GoalProgressRow: View {
    let progress: WeeklyReport.GoalProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(progress.goal.title)
                .font(.subheadline)
            
            HStack {
                ProgressView(value: progress.completionRate)
                    .tint(progress.completionRate >= 1.0 ? .green : .blue)
                
                Text("\(Int(progress.completionRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if progress.streak > 0 {
                Text("Current Streak: \(progress.streak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let impact = progress.impactOnMood {
                Text("Mood Impact: \(impact > 0 ? \"+\" : \"\")\(String(format: "%.1f", impact))")
                    .font(.caption)
                    .foregroundColor(impact > 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Goal Impact Card
struct GoalImpactCard: View {
    let correlation: WeeklyReport.PatternAnalysis.GoalMoodCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Goal Impact")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(correlation.goal.title)
                .font(.body)
            
            Text("Impact: \(correlation.impact == .positive ? \"Positive\" : \"Negative\")")
                .font(.caption)
                .foregroundColor(correlation.impact == .positive ? .green : .red)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - View Extensions
extension View {
    func withErrorAlert(error: Binding<Error?>, action: @escaping () -> Void) -> some View {
        modifier(ErrorAlert(error: error, action: action))
    }
} 
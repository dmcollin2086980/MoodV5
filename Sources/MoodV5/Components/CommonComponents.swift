import SwiftUI

// MARK: - Component Styles
// MARK: - Color Constants
extension Color {
    static let systemBackground = Color(.systemBackground)
    static let secondaryText = Color.secondary
    static let cardBackground = Color(.systemGray6)
    
    static let positive = Color.green
    static let negative = Color.red
    static let neutral = Color.yellow
    
    static let patternCardBackground = Color(.systemGray6)
    static let weeklyPatternCardBackground = Color(.systemGray6)
    static let goalImpactCardBackground = Color(.systemGray6)
    
    static func moodImpactColor(value: Double) -> Color {
        switch value {
        case ..<2.0: return .red
        case 2.0..<3.0: return .orange
        case 3.0..<4.0: return .yellow
        case 4.0..<5.0: return .green
        default: return .blue
        }
    }
}

// MARK: - Font Constants
extension Font {
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let caption = Font.caption
    static let title2 = Font.title2
}

// MARK: - Spacing Constants
extension CGFloat {
    static let spacingSmall: CGFloat = 5
    static let spacingMedium: CGFloat = 8
    static let spacingLarge: CGFloat = 12
    static let spacingExtraLarge: CGFloat = 16
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.spacingLarge)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

struct CardContentStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.spacingMedium)
    }
}

struct MoodImpactColor: ViewModifier {
    let value: Double
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(value >= 4.0 ? .positive : value >= 3.0 ? .neutral : .negative)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func cardContentStyle() -> some View {
        modifier(CardContentStyle())
    }
    
    func moodImpactColor(value: Double) -> some View {
        modifier(MoodImpactColor(value: value))
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: .spacingExtraLarge) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondaryText)
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
            .cardStyle()
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
        VStack(spacing: .spacingExtraLarge) {
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

// MARK: - Card Components

// MARK: - Pattern Cards
struct PatternCard: View {
    let pattern: WeeklyReport.PatternAnalysis.RecurringPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text("Recurring Pattern")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Text(pattern.pattern)
                .font(.body)
            
            Text("Confidence: \(Int(pattern.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .padding(.spacingMedium)
        .background(.patternCardBackground)
        .cornerRadius(8)
    }
}

struct WeeklyPatternCard: View {
    let pattern: WeeklyReport.PatternAnalysis.WeeklyPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text("Best Day")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Text(Calendar.current.weekdaySymbols[pattern.dayOfWeek - 1])
                .font(.body)
            
            Text("Average Mood: \(String(format: "%.1f", pattern.averageMood))")
                .font(.caption)
                .foregroundColor(.secondaryText)
            
            if !pattern.commonActivities.isEmpty {
                Text("Common Activities:")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                ForEach(pattern.commonActivities.prefix(3), id: \.self) { activity in
                    Text("• \(activity)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(.spacingMedium)
        .background(.weeklyPatternCardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Row Components
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

// MARK: - Goal Components
struct GoalProgressRow: View {
    let progress: WeeklyReport.GoalProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text(progress.goal.title)
                .font(.subheadline)
            
            HStack {
                ProgressView(value: progress.completionRate)
                    .tint(progress.completionRate >= 1.0 ? .positive : .blue)
                
                Text("\(Int(progress.completionRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            if progress.streak > 0 {
                Text("Current Streak: \(progress.streak) days")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            if let impact = progress.impactOnMood {
                let impactText = impact > 0 ? "+" : ""
                Text("Mood Impact: \(impactText)\(String(format: "%.1f", impact))")
                    .font(.caption)
                    .foregroundColor(impact > 0 ? .positive : .negative)
            }
        }
    }
}

struct GoalImpactCard: View {
    let correlation: WeeklyReport.PatternAnalysis.GoalMoodCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text("Goal Impact")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Text(correlation.goal.title)
                .font(.body)
            
            Text(correlation.impact == .positive ? "Impact: Positive" : "Impact: Negative")
                .font(.caption)
                .foregroundColor(correlation.impact == .positive ? .positive : .negative)
        }
        .padding(.spacingMedium)
        .background(.goalImpactCardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Time Components
struct TimeOfDayCard: View {
    let title: String
    let average: Double
    let isBest: Bool
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Text(String(format: "%.1f", average))
                .font(.title2)
                .foregroundColor(.moodImpactColor(value: average))
            
            if isBest {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingMedium)
        .background(.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - View Extensions
extension View {
    func withErrorAlert(error: Binding<Error?>, action: @escaping () -> Void) -> some View {
        modifier(ErrorAlert(error: error, action: action))
    }
} 
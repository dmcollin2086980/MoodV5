import SwiftUI

// MARK: - Color Constants
extension Color {
    static let systemBackground = Color(.systemBackground)
    static let secondaryText = Color.secondary
    static let cardBackground = Color(.systemBackground)
    
    static let positive = Color.green
    static let negative = Color.red
    static let neutral = Color.yellow
    
    static let patternCardBackground = Color.blue.opacity(0.1)
    static let weeklyPatternCardBackground = Color.green.opacity(0.1)
    static let goalImpactCardBackground = Color.purple.opacity(0.1)
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

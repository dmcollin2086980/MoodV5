import SwiftUI

struct CoachView: View {
    @StateObject private var viewModel: CoachViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(coachService: CoachService) {
        _viewModel = StateObject(wrappedValue: CoachViewModel(coachService: coachService))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let insight = viewModel.currentInsight {
                        insightCard(insight)
                    }
                }
                .padding()
            }
            .navigationTitle("Your Coach")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshInsight() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your mood patterns...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func insightCard(_ insight: CoachingInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(insight.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                insightIcon(for: insight.type)
            }
            
            Text(insight.message)
                .font(.body)
                .foregroundColor(.secondary)
            
            if let action = insight.action {
                Button(action: { viewModel.handleAction() }) {
                    Text(action)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(insightColor(for: insight.type))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(radius: 5)
        )
    }
    
    private func insightIcon(for type: CoachingInsight.InsightType) -> some View {
        let (icon, color) = iconAndColor(for: type)
        
        return Image(systemName: icon)
            .font(.title)
            .foregroundColor(color)
    }
    
    private func iconAndColor(for type: CoachingInsight.InsightType) -> (String, Color) {
        switch type {
        case .positive:
            return ("star.fill", .yellow)
        case .neutral:
            return ("lightbulb.fill", .blue)
        case .improvement:
            return ("heart.fill", .red)
        }
    }
    
    private func insightColor(for type: CoachingInsight.InsightType) -> Color {
        switch type {
        case .positive:
            return .green
        case .neutral:
            return .blue
        case .improvement:
            return .orange
        }
    }
}

#Preview {
    CoachView(coachService: CoachService(moodStore: try! RealmMoodStore()))
} 
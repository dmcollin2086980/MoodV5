import SwiftUI
import Charts
import Combine

struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(reportService: ReportService) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(reportService: reportService))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Generating Report...")
                } else if let report = viewModel.report {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Date Range
                            Text("\(report.startDate.formatted(date: .abbreviated, time: .omitted)) - \(report.endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Mood Summary Card
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Mood Summary")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Average Mood")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f", report.averageMood))
                                            .font(.title)
                                            .foregroundColor(viewModel.averageMoodColor)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Most Frequent")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(report.mostFrequentMood.rawValue)
                                            .font(.title3)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Time of Day Analysis
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Time of Day Analysis")
                                    .font(.headline)
                                
                                HStack(spacing: 20) {
                                    TimeOfDayCard(
                                        title: "Morning",
                                        average: report.moodTrends.timeOfDayAnalysis.morningAverage,
                                        isBest: report.moodTrends.timeOfDayAnalysis.bestTimeOfDay == .morning
                                    )
                                    
                                    TimeOfDayCard(
                                        title: "Afternoon",
                                        average: report.moodTrends.timeOfDayAnalysis.afternoonAverage,
                                        isBest: report.moodTrends.timeOfDayAnalysis.bestTimeOfDay == .afternoon
                                    )
                                    
                                    TimeOfDayCard(
                                        title: "Evening",
                                        average: report.moodTrends.timeOfDayAnalysis.eveningAverage,
                                        isBest: report.moodTrends.timeOfDayAnalysis.bestTimeOfDay == .evening
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Mood Distribution Chart
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Mood Distribution")
                                    .font(.headline)
                                
                                Chart(viewModel.moodDistributionData, id: \.0) { item in
                                    BarMark(
                                        x: .value("Count", item.1),
                                        y: .value("Mood", item.0.rawValue)
                                    )
                                    .foregroundStyle(by: .value("Mood", item.0.rawValue))
                                }
                                .frame(height: 200)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Pattern Analysis
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Pattern Analysis")
                                    .font(.headline)
                                
                                if let strongestPattern = report.patternAnalysis.recurringPatterns.max(by: { $0.confidence < $1.confidence }) {
                                    PatternCard(pattern: strongestPattern)
                                }
                                
                                if let strongestCorrelation = report.patternAnalysis.goalMoodCorrelations.max(by: { $0.correlation < $1.correlation }) {
                                    GoalImpactCard(correlation: strongestCorrelation)
                                }
                                
                                if let bestDay = report.patternAnalysis.weeklyPatterns.max(by: { $0.averageMood < $1.averageMood }) {
                                    WeeklyPatternCard(pattern: bestDay)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Goal Progress
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Goal Progress")
                                    .font(.headline)
                                
                                ForEach(report.goalProgress, id: \.goal.id) { progress in
                                    GoalProgressRow(progress: progress)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Insights
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights")
                                    .font(.headline)
                                
                                ForEach(report.insights, id: \.self) { insight in
                                    InsightRow(text: insight)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            
                            // Recommendations
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recommendations")
                                    .font(.headline)
                                
                                ForEach(report.recommendations, id: \.self) { recommendation in
                                    RecommendationRow(text: recommendation)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Report Available",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Generate a weekly report to see your mood trends and insights.")
                    )
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if viewModel.report != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.shareReport()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            viewModel.generateReport()
        }
    }
}

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
        .background(isBest ? Color.yellow.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private func moodColor(for value: Double) -> Color {
        switch value {
        case 0..<2: return .red
        case 2..<3: return .orange
        case 3..<4: return .yellow
        default: return .green
        }
    }
}

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

struct GoalImpactCard: View {
    let correlation: WeeklyReport.PatternAnalysis.GoalMoodCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Goal Impact")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(correlation.goal.title)
                .font(.body)
            
            Text("Impact: \(correlation.impact == .positive ? "Positive" : "Negative")")
                .font(.caption)
                .foregroundColor(correlation.impact == .positive ? .green : .red)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

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
                Text("Mood Impact: \(impact > 0 ? "+" : "")\(String(format: "%.1f", impact))")
                    .font(.caption)
                    .foregroundColor(impact > 0 ? .green : .red)
            }
        }
    }
}

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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportView(reportService: ReportService(
        moodStore: MockMoodStore(),
        goalStore: MockGoalStore(),
        coachService: CoachService(moodStore: MockMoodStore())
    ))
}

// Mock stores for preview
class MockMoodStore: MoodStore {
    func save(_ moodEntry: MoodEntry) throws {}
    func fetchAllEntries() -> [MoodEntry] { return [] }
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] { return [] }
    func delete(entry: MoodEntry) throws {}
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> {
        Just([]).eraseToAnyPublisher()
    }
}

class MockGoalStore: GoalStore {
    func save(_ goal: Goal) throws {}
    func fetchAllGoals() -> [Goal] { return [] }
    func delete(goal: Goal) throws {}
    func update(_ goal: Goal) throws {}
    var goalsPublisher: AnyPublisher<[Goal], Never> {
        Just([]).eraseToAnyPublisher()
    }
} 
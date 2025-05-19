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
                    LoadingView(message: "Generating Report...")
                } else if let report = viewModel.report {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Date Range
                            Text("\(report.startDate.formatted(date: .abbreviated, time: .omitted)) - \(report.endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Mood Summary Card
                            CardView {
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
                            }

                            // Time of Day Analysis
                            CardView {
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
                            }

                            // Mood Distribution Chart
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Mood Distribution")
                                        .font(.headline)

                                    MoodDistributionChart(data: viewModel.moodDistributionData)
                                }
                            }

                            // Pattern Analysis
                            CardView {
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
                            }

                            // Goal Progress
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Goal Progress")
                                        .font(.headline)

                                    ForEach(report.goalProgress, id: \.goal.id) { progress in
                                        GoalProgressRow(progress: progress)
                                    }
                                }
                            }

                            // Insights
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Insights")
                                        .font(.headline)

                                    ForEach(report.insights, id: \.self) { insight in
                                        InsightRow(text: insight)
                                    }
                                }
                            }

                            // Recommendations
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Recommendations")
                                        .font(.headline)

                                    ForEach(report.recommendations, id: \.self) { recommendation in
                                        RecommendationRow(text: recommendation)
                                    }
                                }
                            }
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
            .withErrorAlert(error: $viewModel.error) {
                viewModel.error = nil
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
}

#Preview {
    ReportView(reportService: ReportService(
        moodStore: try! RealmMoodStore(),
        goalStore: try! RealmGoalStore(),
        coachService: CoachService(moodStore: try! RealmMoodStore())
    ))
}

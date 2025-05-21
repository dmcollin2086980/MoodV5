import SwiftUI
import Charts
import Combine

// It's assumed that WeeklyReport, ReportViewModel, LoadingView, CardView,
// and EmptyStateView (from CommonComponents.swift) are defined and accessible.
// Also, other report-specific sub-views like MoodDistributionChart would be needed
// if the reportContent function were to be fully fleshed out as in previous versions.

struct ReportView: View {
    // Using @ObservedObject. If ReportView creates and owns ReportViewModel,
    // @StateObject is generally preferred to tie the ViewModel's lifecycle to the View.
    // If the ViewModel is passed from a parent view that owns it, @ObservedObject is correct.
    @ObservedObject private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss

    // Initializer for the ViewModel
    init(reportService: ReportService) {
        viewModel = ReportViewModel(reportService: reportService)
    }

    var body: some View {
        // Using NavigationView for broader compatibility (iOS <16)
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    // Assuming LoadingView is defined (e.g., in CommonComponents.swift)
                    LoadingView(message: "Generating Report...")
                } else if let report = viewModel.report {
                    reportContent(report: report)
                } else {
                    // Using EmptyStateView for iOS 15 compatibility
                    // Assuming EmptyStateView is defined (e.g., in CommonComponents.swift)
                    EmptyStateView(
                        icon: "chart.bar.doc.horizontal",
                        title: "No Report Available",
                        message: "Generate a weekly report to see your mood trends and insights."
                    )
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            // The .toolbar modifier is where the "Ambiguous use" error occurs.
            // The syntax used here for ToolbarItemGroups is standard.
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        viewModel.generateReport()
                    }
                    // If you had a share button, it would go here or in another ToolbarItemGroup
                    // For example:
                    // Button { viewModel.shareReport() } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
            // .withErrorAlert and .sheet for sharing would be added here if needed,
            // similar to your previous full ReportView version.
            // .onAppear { viewModel.generateReport() } // Could also be placed here
        }
        // This onAppear might be more suitable on the ZStack or the content within it,
        // or handled internally by the ViewModel.
        // For now, the "Generate" button handles report generation.
    }
    
    // Extracted report content view builder
    @ViewBuilder
    private func reportContent(report: WeeklyReport) -> some View {
        ScrollView {
            // Formatting dates
            let startDateString = report.startDate.formatted(.dateTime.month().day())
            let endDateString = report.endDate.formatted(.dateTime.month().day())
            
            VStack(spacing: 20) {
                // Date Range
                Text("\(startDateString) - \(endDateString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Mood Summary Card
                // Assuming CardView is defined (e.g., in CommonComponents.swift)
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood Summary")
                            .font(.headline)
                        
                        // Example of content within the card
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Average Mood")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", report.averageMood))
                                    .font(.title)
                                    // .foregroundColor(viewModel.averageMoodColor) // viewModel isn't directly in scope here
                                    // You might need to pass the color or the whole viewModel if needed
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Most Frequent")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(report.mostFrequentMood.rawValue) // Assuming MoodType has a rawValue
                                    .font(.title3)
                            }
                        }
                        // Add more details to the summary card as needed
                    }
                    .padding() // Ensure CardView content has padding
                }
                
                // Add other sections like Time of Day Analysis, Mood Distribution Chart,
                // Pattern Analysis, Goal Progress, Insights, Recommendations
                // using CardView and the respective component views from CommonComponents.swift
                // For example:
                // CardView { MoodDistributionChart(data: viewModel.moodDistributionData) }
                // CardView { if let pattern = report.patternAnalysis.recurringPatterns.first { PatternCard(pattern: pattern) } }

            }
            .padding()
        }
    }
}

// Previe
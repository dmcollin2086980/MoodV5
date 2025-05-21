import Foundation
import SwiftUI
import Combine

class ReportViewModel: ObservableObject {
    @Published var report: WeeklyReport?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingShareSheet = false
    
    private let reportService: ReportService
    private var cancellables = Set<AnyCancellable>()
    
    init(reportService: ReportService) {
        self.reportService = reportService
    }
    
    func generateReport() {
        isLoading = true
        error = nil
        
        do {
            report = try reportService.generateWeeklyReport()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func shareReport() {
        guard let report = report else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var reportText = "Weekly Mood Report\n"
        reportText += "\(dateFormatter.string(from: report.startDate)) - \(dateFormatter.string(from: report.endDate))\n\n"
        
        // Mood Summary
        reportText += "Mood Summary:\n"
        reportText += "Average Mood: \(String(format: "%.1f", report.averageMood))\n"
        reportText += "Most Frequent Mood: \(report.mostFrequentMood.rawValue)\n\n"
        
        // Mood Distribution
        reportText += "Mood Distribution:\n"
        for (mood, count) in report.moodDistribution.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            reportText += "\(mood.rawValue): \(count) times\n"
        }
        reportText += "\n"
        
        // Goal Progress
        reportText += "Goal Progress:\n"
        for progress in report.goalProgress {
            reportText += "• \(progress.goal.title): \(Int(progress.completionRate * 100))% complete"
            if progress.streak > 0 {
                reportText += " (Streak: \(progress.streak) days)"
            }
            reportText += "\n"
        }
        reportText += "\n"
        
        // Insights
        reportText += "Insights:\n"
        for insight in report.insights {
            reportText += "• \(insight)\n"
        }
        reportText += "\n"
        
        // Recommendations
        reportText += "Recommendations:\n"
        for recommendation in report.recommendations {
            reportText += "• \(recommendation)\n"
        }
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "weekly-report-\(dateFormatter.string(from: Date())).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try reportText.write(to: fileURL, atomically: true, encoding: .utf8)
            showingShareSheet = true
        } catch {
            self.error = error
        }
    }
    
    var moodDistributionData: [(MoodType, Int)] {
        guard let report = report else { return [] }
        return report.moodDistribution.sorted { $0.key.rawValue < $1.key.rawValue }
    }
    
    var goalProgressData: [(Goal, Double)] {
        guard let report = report else { return [] }
        return report.goalProgress.map { ($0.goal, $0.completionRate) }
    }
    
    var averageMoodColor: Color {
        guard let report = report else { return .gray }
        let value = report.averageMood
        switch value {
        case 0..<2: return .red
        case 2..<3: return .orange
        case 3..<4: return .yellow
        default: return .green
        }
    }
} 
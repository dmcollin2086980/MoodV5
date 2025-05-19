import SwiftUI

// MARK: - Report Specific Components
struct ReportHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ReportSummary: View {
    let moodScore: Double
    let goalProgress: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood Score")
                    .font(.headline)
                
                Text(String(format: "%.1f", moodScore))
                    .font(.title)
                    .foregroundColor(moodColor(for: moodScore))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Progress")
                    .font(.headline)
                
                ProgressView(value: goalProgress)
                    .tint(.blue)
            }
        }
        .padding()
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
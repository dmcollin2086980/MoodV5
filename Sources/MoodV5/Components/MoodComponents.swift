import SwiftUI

// MARK: - Mood Button
struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                Text(mood.rawValue)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Mood Entry Card
struct MoodEntryCard: View {
    let entry: MoodEntry
    let onDelete: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(entry.moodType.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text(entry.moodType.rawValue)
                            .font(.headline)
                        
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Mood Distribution Chart
struct MoodDistributionChart: View {
    let data: [(MoodType, Int)]
    
    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("Count", item.1),
                y: .value("Mood", item.0.rawValue)
            )
            .foregroundStyle(by: .value("Mood", item.0.rawValue))
        }
        .frame(height: 200)
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
import SwiftUI
import Charts

// MARK: - Mood Button
struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.rawValue)
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
                    Text(entry.moodType.rawValue)
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
        Chart {
            ForEach(data, id: \.0) { mood, count in
                BarMark(
                    x: .value("Count", count),
                    y: .value("Mood", mood.rawValue)
                )
                .foregroundStyle(by: .value("Mood", mood.rawValue))
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Mood Timeline
struct MoodTimeline: View {
    let entries: [MoodEntry]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(entries) { entry in
                    MoodEntryCard(entry: entry, onDelete: {})
                }
            }
            .padding()
        }
    }
}
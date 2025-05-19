import SwiftUI

struct ContentView: View {
    private let moodStore: MoodStore
    private let goalStore: GoalStore
    private let settingsStore: SettingsStore
    
    init() {
        do {
            self.moodStore = try RealmMoodStore()
            self.goalStore = try RealmGoalStore()
            self.settingsStore = try RealmSettingsStore()
        } catch {
            fatalError("Failed to initialize stores: \(error)")
        }
    }
    
    private var coachService: CoachService {
        CoachService(moodStore: moodStore)
    }
    
    var body: some View {
        TabView {
            MoodEntryView(moodStore: moodStore)
                .tabItem {
                    Label("Mood", systemImage: "face.smiling")
                }
            
            HistoryView(moodStore: moodStore)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            GoalsView(goalStore: goalStore)
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            
            CoachView(coachService: coachService)
                .tabItem {
                    Label("Coach", systemImage: "brain")
                }
        }
    }
}

#Preview {
    ContentView()
} 
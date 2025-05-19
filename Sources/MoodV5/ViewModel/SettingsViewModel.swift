import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingTimePicker = false
    
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.settings = settingsStore.fetchSettings()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        settingsStore.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)
    }
    
    func updateReminderTime(_ time: Date) {
        settings.reminderTime = time
        saveSettings()
    }
    
    func toggleReminder() {
        settings.reminderEnabled.toggle()
        saveSettings()
    }
    
    func toggleDarkMode() {
        settings.darkModeEnabled.toggle()
        saveSettings()
    }
    
    func toggleNotifications() {
        settings.notificationsEnabled.toggle()
        saveSettings()
    }
    
    func toggleWeeklyReport() {
        settings.weeklyReportEnabled.toggle()
        saveSettings()
    }
    
    func updateDefaultMoodNote(_ note: String) {
        settings.defaultMoodNote = note
        saveSettings()
    }
    
    func toggleAutoBackup() {
        settings.autoBackupEnabled.toggle()
        saveSettings()
    }
    
    private func saveSettings() {
        do {
            try settingsStore.update(settings)
        } catch {
            self.error = error
        }
    }
    
    func resetToDefaults() {
        let defaultSettings = UserSettings()
        do {
            try settingsStore.update(defaultSettings)
        } catch {
            self.error = error
        }
    }
} 
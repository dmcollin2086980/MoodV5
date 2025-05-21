import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(settingsStore: SettingsStore) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsStore: settingsStore))
    }
    
    var body: some View {
        NavigationView {
            Form {
                notificationsSection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
    
    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Daily Reminder", isOn: $viewModel.settings.reminderEnabled)
            
            if viewModel.settings.reminderEnabled {
                HStack {
                    Text("Reminder Time")
                    Spacer()
                    Button(viewModel.settings.formattedReminderTime) {
                        viewModel.showingTimePicker = true
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Toggle("Weekly Report", isOn: $viewModel.settings.weeklyReportEnabled)
        }
    }
    
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Toggle("Dark Mode", isOn: $viewModel.settings.darkModeEnabled)
            
            TextField("Default Mood Note", text: $viewModel.settings.defaultMoodNote)
        }
    }
    
    private var dataSection: some View {
        Section(header: Text("Data")) {
            Toggle("Auto Backup", isOn: $viewModel.settings.autoBackupEnabled)
            
            if let lastBackup = viewModel.settings.lastBackupDate {
                HStack {
                    Text("Last Backup")
                    Spacer()
                    Text(lastBackup, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Export Data") {
                // TODO: Implement data export
            }
            
            Button("Import Data") {
                // TODO: Implement data import
            }
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }
}

struct TimePickerView: View {
    @Binding var time: Date
    let onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
            .navigationTitle("Set Reminder Time")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave(time)
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    SettingsView(settingsStore: try! RealmSettingsStore())
} 
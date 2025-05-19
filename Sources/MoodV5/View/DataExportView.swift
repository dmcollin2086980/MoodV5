import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @StateObject private var viewModel: DataExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(dataExportService: DataExportService) {
        _viewModel = StateObject(wrappedValue: DataExportViewModel(dataExportService: dataExportService))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $viewModel.exportFormat) {
                        Text("JSON").tag(ExportFormat.json)
                        Text("CSV").tag(ExportFormat.csv)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: { viewModel.exportData() }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: { viewModel.showingImportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Data")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Data Management")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                if let data = viewModel.exportedData {
                    ShareSheet(activityItems: [data])
                }
            }
            .fileImporter(
                isPresented: $viewModel.showingImportSheet,
                allowedContentTypes: [viewModel.exportUTType],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let data = try Data(contentsOf: url)
                        viewModel.importData(data)
                    } catch {
                        viewModel.error = error
                    }
                case .failure(let error):
                    viewModel.error = error
                }
            }
        }
    }
}

#Preview {
    DataExportView(dataExportService: DataExportService(
        moodStore: RealmMoodStore(),
        goalStore: RealmGoalStore(),
        settingsStore: RealmSettingsStore()
    ))
} 
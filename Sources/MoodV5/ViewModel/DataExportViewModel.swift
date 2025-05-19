import Foundation
import SwiftUI
import UniformTypeIdentifiers

class DataExportViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingExportSheet = false
    @Published var showingImportSheet = false
    @Published var exportedData: Data?
    @Published var exportFormat: ExportFormat = .json
    
    private let dataExportService: DataExportService
    
    init(dataExportService: DataExportService) {
        self.dataExportService = dataExportService
    }
    
    func exportData() {
        isLoading = true
        
        do {
            exportedData = try dataExportService.exportData(format: exportFormat)
            showingExportSheet = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func importData(_ data: Data) {
        isLoading = true
        
        do {
            try dataExportService.importData(data, format: exportFormat)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    var exportUTType: UTType {
        switch exportFormat {
        case .json:
            return .json
        case .csv:
            return .commaSeparatedText
        }
    }
    
    var exportFileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "moodv5-backup-\(dateString).\(exportFormat.fileExtension)"
    }
} 
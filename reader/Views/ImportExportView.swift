import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var isExportHovered: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                AboutButton(
                    title: "Import Books...",
                    systemImage: "square.and.arrow.down",
                    action: {
                        showingImporter.toggle()
                    }
                )
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [.json, .commaSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    handleImport(result: result)
                }
                
                Menu {
                    Button("JSON") {
                        handleExport(format: .json)
                    }
                    
                    Button("CSV") {
                        handleExport(format: .csv)
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                        Text("Export Books...")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.primary)
                            .font(.system(size: 12))
                            .padding(.leading, -5)
                    }
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                isExportHovered
                                ? Color.gray.opacity(0.2)
                                : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isExportHovered ? Color.gray : Color.clear,
                                lineWidth: 1)
                    )
                    .animation(
                        .easeInOut(duration: 0.2), value: isExportHovered
                    )
                    .frame(width: 150)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isExportHovered = hovering
                }
            }
            
            if let error = importError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }
        }
        .padding()
        .frame(width: 400)
        .onDisappear {
            releaseSettingsWindowResources()
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                if url.pathExtension.lowercased() == "json" {
                    dataManager.importBooks(from: url) { result in
                        handleImportResult(result)
                    }
                } else if url.pathExtension.lowercased() == "csv" {
                    dataManager.importBooksFromCSV(from: url) { result in
                        handleImportResult(result)
                    }
                } else {
                    importError =
                    "Unsupported file format. Please use JSON or CSV."
                }
            }
        case .failure(let error):
            importError = "File selection error: \(error.localizedDescription)"
        }
    }
    
    private func handleImportResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            appState.showImportSuccess()
        case .failure(let error):
            importError = "Import failed: \(error.localizedDescription)"
        }
    }
    
    private enum ExportFormat {
        case json, csv
        
        var utType: UTType {
            switch self {
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    private func handleExport(format: ExportFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.utType]
        panel.nameFieldStringValue =
        "books-\(currentDateString()).\(format.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            switch format {
            case .json:
                dataManager.exportBooks(to: url) { result in
                    handleExportResult(result)
                }
            case .csv:
                dataManager.exportBooksToCSV(to: url) { result in
                    handleExportResult(result)
                }
            }
        }
    }
    
    private func handleExportResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            appState.showExportSuccess()
        case .failure(let error):
            importError = "Export failed: \(error.localizedDescription)"
        }
    }
    
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

extension UTType {
    static let commaSeparatedText = UTType(filenameExtension: "csv")!
}

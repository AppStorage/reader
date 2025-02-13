import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appState: AppState
    @State private var showingImporter = false
    @State private var importError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                AboutButton(title: "Import JSON", systemImage: "square.and.arrow.down", action: {
                    showingImporter.toggle()
                })
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    handleImport(result: result)
                }
                
                AboutButton(title: "Export JSON", systemImage: "square.and.arrow.up", action: {
                    handleExport()
                })
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
                dataManager.importBooks(from: url) { result in
                    switch result {
                    case .success:
                        appState.showImportSuccess()
                    case .failure(let error):
                        importError = "Import failed: \(error.localizedDescription)"
                    }
                }
            }
        case .failure(let error):
            importError = "File selection error: \(error.localizedDescription)"
        }
    }
    
    private func handleExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "books-\(currentDateString()).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            dataManager.exportBooks(to: url) { result in
                switch result {
                case .success:
                    appState.showExportSuccess()
                case .failure(let error):
                    importError = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

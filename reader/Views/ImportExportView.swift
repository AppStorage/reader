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
    
    // MARK: Import JSON
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    guard url.startAccessingSecurityScopedResource() else {
                        importError = "Failed to access file permissions."
                        return
                    }
                    
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    let jsonData = try Data(contentsOf: url)
                    
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    if let importedData = try? decoder.decode([BookTransferData].self, from: jsonData) {
                        for book in importedData {
                            let newBook = DataConversion.toBookData(from: book)
                            dataManager.addBook(book: newBook)
                        }
                        appState.showImportSuccess()
                    } else {
                        importError = "Failed to parse JSON."
                    }
                } catch {
                    importError = "Failed to load file: \(error.localizedDescription)"
                }
            }
        case .failure(let error):
            importError = "File selection error: \(error.localizedDescription)"
        }
    }
    
    // MARK: Export JSON
    private func handleExport() {
        let books = dataManager.books
            .filter { $0.status != .deleted }
            .map { DataConversion.toTransferData(from: $0) }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(books) else {
            importError = "Failed to encode books to JSON."
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "Books.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try jsonData.write(to: url)
                appState.showExportSuccess()
            } catch {
                importError = "Failed to save file: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: Cleanup
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

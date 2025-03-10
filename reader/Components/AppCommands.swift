import SwiftUI

struct AppCommands {
    @MainActor static func fileCommands(appState: AppState, dataManager: DataManager, openWindow: @escaping (String) -> Void) -> some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add Book") {
                openWindow("addBookWindow")
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Divider()
            
            Button("Import Books...") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                
                if panel.runModal() == .OK, let url = panel.url {
                    dataManager.importBooks(from: url) { result in
                        switch result {
                        case .success:
                            appState.showImportSuccess()
                        case .failure(let error):
                            appState.alertType = .error("Import failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .keyboardShortcut("i", modifiers: .command)
            
            Button("Export Books...") {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "books-\(currentDateString()).json"
                
                if panel.runModal() == .OK, let url = panel.url {
                    dataManager.exportBooks(to: url) { result in
                        switch result {
                        case .success:
                            appState.showExportSuccess()
                        case .failure(let error):
                            appState.alertType = .error("Export failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .keyboardShortcut("e", modifiers: .command)
        }
    }
    
    @MainActor static func appInfoCommands(appState: AppState) -> some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Updates...") {
                appState.checkForAppUpdates(isUserInitiated: true)
            }
            .disabled(appState.isCheckingForUpdates)
        }
    }
    
    static func settingsCommands(appState: AppState, dataManager: DataManager) -> some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                readerApp.showSettingsWindow(appState: appState, dataManager: dataManager) {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
    
    @MainActor static func deleteCommands(appState: AppState, viewModel: ContentViewModel) -> some Commands {
        CommandGroup(after: CommandGroupPlacement.pasteboard) {
            let selectedBooks = appState.selectedBooks
            let bookCount = selectedBooks.count
            
            let deleteLabel = bookCount == 1 ? "Delete Book" : "Delete Books"
            let permanentDeleteLabel = bookCount == 1 ? "Permanently Delete Book" : "Permanently Delete Books"
            
            Button(deleteLabel) {
                guard !selectedBooks.isEmpty else { return }
                
                if selectedBooks.allSatisfy({ $0.status == .deleted }) {
                    appState.showPermanentDeleteConfirmation(for: selectedBooks)
                } else {
                    appState.showSoftDeleteConfirmation(for: selectedBooks)
                }
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(selectedBooks.isEmpty)
            
            Button(permanentDeleteLabel) {
                guard !selectedBooks.isEmpty else { return }
                appState.showPermanentDeleteConfirmation(for: selectedBooks)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(selectedBooks.isEmpty)
        }
    }
}

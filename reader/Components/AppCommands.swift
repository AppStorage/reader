import SwiftUI
import Combine

@MainActor
struct AppCommands {
    private static var cancellables = Set<AnyCancellable>()
    
    // MARK: - Import/Export Actions
    static func fileCommands(
        appState: AppState,
        dataManager: DataManager,
        openWindow: @escaping (String) -> Void
    ) -> some Commands {
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
                    dataManager.importBooks(from: url)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                appState.alertManager?.showError("Import failed: \(error.localizedDescription)")
                            }
                        }, receiveValue: {
                            appState.alertManager?.showImportSuccess()
                        })
                        .store(in: &Self.cancellables)
                }
            }
            .keyboardShortcut("i", modifiers: .command)
            
            Button("Export Books...") {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "books-\(DateFormatterUtils.currentDateString()).json"
                
                if panel.runModal() == .OK, let url = panel.url {
                    dataManager.exportBooks(to: url)
                        .sink(receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                appState.alertManager?.showError("Export failed: \(error.localizedDescription)")
                            }
                        }, receiveValue: {
                            appState.alertManager?.showExportSuccess()
                        })
                        .store(in: &Self.cancellables)
                }
            }
            .keyboardShortcut("e", modifiers: .command)
        }
    }
    
    // MARK: - Update
    static func appInfoCommands(appState: AppState) -> some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Updates...") {
                appState.checkForAppUpdates(isUserInitiated: true)
            }
            .disabled(appState.isCheckingForUpdates)
        }
    }
    
    // MARK: - Settings
    static func settingsCommands(openWindow: @escaping (String) -> Void) -> some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                openWindow("preferencesWindow")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
    
    // MARK: - Delete Book Actions
    static func deleteCommands(
        appState: AppState,
        contentViewModel: ContentViewModel
    ) -> some Commands {
        CommandGroup(after: CommandGroupPlacement.pasteboard) {
            let selectedBooks = appState.selectedBooks
            let bookCount = selectedBooks.count
            
            let deleteLabel = bookCount == 1 ? "Delete Book" : "Delete Books"
            let permanentDeleteLabel = bookCount == 1 ? "Permanently Delete Book" : "Permanently Delete Books"
            
            Button(deleteLabel) {
                guard !selectedBooks.isEmpty else { return }
                
                if selectedBooks.allSatisfy({ $0.status == .deleted }) {
                    appState.alertManager?.showPermanentDeleteConfirmation(for: selectedBooks)
                } else {
                    appState.alertManager?.showSoftDeleteConfirmation(for: selectedBooks)
                }
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(selectedBooks.isEmpty)
            
            Button(permanentDeleteLabel) {
                guard !selectedBooks.isEmpty else { return }
                appState.alertManager?.showPermanentDeleteConfirmation(for: selectedBooks)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(selectedBooks.isEmpty)
        }
    }
}

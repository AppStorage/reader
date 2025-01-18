import SwiftUI

struct AppCommands {
    @MainActor static func fileCommands(openWindow: @escaping (String) -> Void) -> some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add Book") {
                openWindow("addBookWindow")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
    
    @MainActor static func appInfoCommands(appState: AppState) -> some Commands {
        CommandGroup(after: .appInfo) {
            Button("Check for Updates") {
                appState.checkForAppUpdates(isUserInitiated: true)
            }
            .disabled(appState.isCheckingForUpdates)
        }
    }
    
    static func settingsCommands(appState: AppState) -> some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Preferences...") {
                readerApp.showSettingsWindow(appState: appState) {
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
            
            // Soft Delete
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
            
            // Permanent Delete
            Button(permanentDeleteLabel) {
                guard !selectedBooks.isEmpty else { return }
                appState.showPermanentDeleteConfirmation(for: selectedBooks)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(selectedBooks.isEmpty)
        }
    }
}

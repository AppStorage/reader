import SwiftUI

extension AlertType {
    @MainActor func createAlert(appState: AppState) -> Alert {
        switch self {
        case .newUpdateAvailable:
            return Alert(
                title: Text("New Update Available"),
                message: Text("reader \(appState.latestVersion ?? "unknown") is available. Would you like to download it?"),
                primaryButton: .default(Text("Download")) {
                    if let downloadURL = appState.downloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                },
                secondaryButton: .cancel(Text("Later"))
            )
        case .upToDate:
            return Alert(
                title: Text("No Updates Available"),
                message: Text("You are already on the latest version."),
                dismissButton: .default(Text("OK"))
            )
        case .error(let errorDetails):
            return Alert(
                title: Text("Error"),
                message: Text(errorDetails),
                dismissButton: .default(Text("OK"))
            )
            
        case .softDelete(let book):
            return Alert(
                title: Text("Move to Deleted?"),
                message: Text("This will move the book '\(book.title)' to deleted."),
                primaryButton: .default(Text("Delete")) {
                    appState.viewModel?.softDeleteBook(book)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            
        case .permanentDelete(let book):
            return Alert(
                title: Text("Permanently Delete?"),
                message: Text("This will permanently delete the book '\(book.title)'. You can't undo this action."),
                primaryButton: .destructive(Text("Delete")) {
                    appState.viewModel?.permanentlyDeleteBook(book)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
}

enum AlertType: Identifiable {
    case newUpdateAvailable
    case upToDate
    case error(String)
    case softDelete(BookData)
    case permanentDelete(BookData)
    
    var id: String {
        switch self {
        case .newUpdateAvailable: return "newUpdateAvailable"
        case .upToDate: return "upToDate"
        case .error(let message): return "error-\(message)"
        case .softDelete(let book): return "softDelete-\(book.id)"
        case .permanentDelete(let book): return "permanentDelete-\(book.id)"
        }
    }
}

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
        case .noResults(_):
            return Alert(
                title: Text("No Results Found"),
                message: Text("No books found. Please check the details and try again."),
                dismissButton: .default(Text("OK"))
            )
            // Single Soft Delete
        case .softDeleteSingle(let book):
            return Alert(
                title: Text("Move to Deleted?"),
                message: Text("This will move the book '\(book.title)' to deleted."),
                primaryButton: .default(Text("Delete")) {
                    appState.viewModel?.softDeleteBook(book)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            // Single Permanent Delete
        case .permanentDeleteSingle(let book):
            return Alert(
                title: Text("Permanently Delete?"),
                message: Text("This will permanently delete the book '\(book.title)'. You can't undo this action."),
                primaryButton: .default(Text("Delete")) {
                    appState.viewModel?.permanentlyDeleteBook(book)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            // Multiple Soft Delete
        case .softDeleteMultiple(let books):
            return Alert(
                title: Text("Move to Deleted?"),
                message: Text("This will move \(books.count) selected books to deleted."),
                primaryButton: .default(Text("Delete")) {
                    for book in books {
                        appState.viewModel?.softDeleteBook(book)
                    }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            // Multiple Permanent Delete
        case .permanentDeleteMultiple(let books):
            return Alert(
                title: Text("Permanently Delete?"),
                message: Text("This will permanently delete \(books.count) selected books. You can't undo this action."),
                primaryButton: .default(Text("Delete")) {
                    for book in books {
                        appState.viewModel?.permanentlyDeleteBook(book)
                    }
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
    case noResults(String)
    case softDeleteSingle(BookData)
    case permanentDeleteSingle(BookData)
    case softDeleteMultiple([BookData])
    case permanentDeleteMultiple([BookData])
    
    var id: String {
        switch self {
        case .newUpdateAvailable: return "newUpdateAvailable"
        case .upToDate: return "upToDate"
        case .error(let message): return "error-\(message)"
        case .noResults(let message): return "noResults-\(message)"
        case .softDeleteSingle(let book): return "softDelete-\(book.id)"
        case .permanentDeleteSingle(let book): return "permanentDelete-\(book.id)"
        case .softDeleteMultiple(let books): return "softDelete-multiple-\(books.count)"
        case .permanentDeleteMultiple(let books): return "permanentDelete-multiple-\(books.count)"
        }
    }
}

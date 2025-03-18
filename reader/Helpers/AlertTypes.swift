import SwiftUI

// MARK: - Alert Types
enum AlertTypes: Identifiable {
    case newUpdateAvailable
    case upToDate
    case error(String)
    case noResults(String)
    case softDelete(books: [BookData])
    case permanentDelete(books: [BookData])
    case importSuccess
    case exportSuccess
    
    var id: String {
        switch self {
        case .newUpdateAvailable: return "newUpdateAvailable"
        case .upToDate: return "upToDate"
        case .error(let message): return "error-\(message)"
        case .noResults(let message): return "noResults-\(message)"
        case .softDelete(let books):
            return "softDelete-\(books.map { $0.id.uuidString }.joined(separator: ","))"
        case .permanentDelete(let books):
            return "permanentDelete-\(books.map { $0.id.uuidString }.joined(separator: ","))"
        case .importSuccess: return "importSuccess"
        case .exportSuccess: return "exportSuccess"
        }
    }
}

// MARK: - Alert Builder
@MainActor
class AlertBuilder {
    static func createAlert(for alertType: AlertTypes,
                            contentViewModel: ContentViewModel,
                            appState: AppState) -> Alert {
        switch alertType {
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
        case .softDelete(let books):
            let message = books.count == 1
            ? "This will move the book '\(books.first!.title)' to deleted."
            : "This will move \(books.count) selected books to deleted."
            
            return Alert(
                title: Text("Move to Deleted?"),
                message: Text(message),
                primaryButton: .default(Text("Delete")) {
                    contentViewModel.performSoftDelete(books: books, appState: appState)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
            
        case .permanentDelete(let books):
            let message = books.count == 1
            ? "This will permanently delete the book '\(books.first!.title)'. You can't undo this action."
            : "This will permanently delete \(books.count) selected books. You can't undo this action."
            
            return Alert(
                title: Text("Permanently Delete?"),
                message: Text(message),
                primaryButton: .destructive(Text("Delete")) {
                    contentViewModel.performPermanentDelete(books: books, appState: appState)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .importSuccess:
            return Alert(
                title: Text("Import Successful"),
                message: Text("Books have been imported successfully."),
                dismissButton: .default(Text("OK"))
            )
            
        case .exportSuccess:
            return Alert(
                title: Text("Export Successful"),
                message: Text("Books have been exported successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

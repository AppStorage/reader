import SwiftUI

struct BookActionButton: View {
    @EnvironmentObject var appState: AppState
    
    let books: [BookData]
    let dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 12) {
            if allSelectedBooksAreDeleted() {
                // Show recover and permanent delete buttons for deleted books
                recoverButton(for: books)
                deleteButton(for: books, isPermanent: true)
            } else {
                // Show soft delete for non-deleted books
                deleteButton(for: books, isPermanent: false)
            }
        }
    }
    
    // MARK: Recover Button
    private func recoverButton(for books: [BookData]) -> some View {
        let label = books.count == 1 ? "Recover Book" : "Recover Books"
        
        return Button(action: {
            for book in books {
                dataManager.updateBookStatus(book, to: .unread)
            }
        }) {
            Label("Recover", systemImage: "arrow.uturn.backward")
        }
        .help(label)
        .accessibilityLabel(label)
    }
    
    // MARK: Delete Button
    private func deleteButton(for books: [BookData], isPermanent: Bool) -> some View {
        let label = isPermanent
        ? (books.count == 1 ? "Permanently Delete Book" : "Permanently Delete Books")
        : (books.count == 1 ? "Move Book to Deleted" : "Move Books to Deleted")
        
        return Button(action: {
            if isPermanent {
                appState.showPermanentDeleteConfirmation(for: books)
            } else {
                appState.showSoftDeleteConfirmation(for: books)
            }
        }) {
            Label(isPermanent ? "Permanently Delete" : "Delete", systemImage: "trash")
        }
        .help(label)
        .accessibilityLabel(label)
    }
    
    // Check if all selected books are already deleted
    private func allSelectedBooksAreDeleted() -> Bool {
        books.allSatisfy { $0.status == .deleted }
    }
}

import SwiftUI

struct BookActionButton: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    var selectedBooks: [BookData] = []
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                if selectedBooks.isEmpty {
                    // No selection
                    Button(action: {}) {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(true)
                } else if allSelectedBooksAreDeleted() {
                    // Already deleted books - Show recover and permanent delete options
                    recoverButton(for: selectedBooks)
                    deleteButton(for: selectedBooks, isPermanent: true)
                } else {
                    // Not deleted - Show soft delete
                    deleteButton(for: selectedBooks, isPermanent: false)
                }
            }
        }
    }
    
    // Recover Button
    private func recoverButton(for books: [BookData]) -> some View {
        Button(action: {
            viewModel.updateBookStatus(for: books, to: .unread)
        }) {
            Label("Recover", systemImage: "arrow.uturn.backward")
        }
        .help("Recover Books")
        .accessibilityLabel("Recover Books")
    }
    
    // Delete Button
    private func deleteButton(for books: [BookData], isPermanent: Bool) -> some View {
        Button(action: {
            if isPermanent {
                appState.showPermanentDeleteConfirmation(for: books)
            } else {
                appState.showSoftDeleteConfirmation(for: books)
            }
        }) {
            Label(isPermanent ? "Permanently Delete" : "Delete", systemImage: "trash")
        }
        .help(isPermanent ? "Permanently Delete Books" : "Move Books to Deleted")
        .accessibilityLabel(isPermanent ? "Permanently Delete Books" : "Move Books to Deleted")
    }
    
    // Check if all selected books are already deleted
    private func allSelectedBooksAreDeleted() -> Bool {
        selectedBooks.allSatisfy { $0.status == .deleted }
    }
}

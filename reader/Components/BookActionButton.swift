import SwiftUI

struct BookActionButton: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    var selectedBooks: [BookData] = []
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                if selectedBooks.isEmpty {
                    Button(action: {}) {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(true)
                } else if allSelectedBooksAreDeleted() {
                    recoverButton(for: selectedBooks)
                    permanentDeleteButton(for: selectedBooks)
                } else {
                    softDeleteButton(for: selectedBooks)
                }
            }
        }
    }
    
    private func recoverButton(for books: [BookData]) -> some View {
        Button(action: {
            for book in books {
                viewModel.recoverBook(book)
            }
        }) {
            Label("Recover", systemImage: "return")
        }
        .help("Recover Books")
        .accessibilityLabel("Recover Books")
    }
    
    private func permanentDeleteButton(for books: [BookData]) -> some View {
        Button(action: {
            for book in books {
                appState.showPermanentDeleteConfirmation(for: book)
            }
        }) {
            Label("Permanently Delete", systemImage: "trash")
        }
        .help("Permanently Delete Books")
        .accessibilityLabel("Permanently Delete Books")
    }
    
    private func softDeleteButton(for books: [BookData]) -> some View {
        Button(action: {
            for book in books {
                appState.showSoftDeleteConfirmation(for: book)
            }
        }) {
            Label("Delete", systemImage: "trash")
        }
        .help("Delete")
        .accessibilityLabel("Move Books to Deleted")
    }
    
    private func allSelectedBooksAreDeleted() -> Bool {
        selectedBooks.allSatisfy { $0.status == .deleted }
    }
}

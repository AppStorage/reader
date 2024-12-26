import SwiftUI

struct BookActionButton: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                if let selectedBook = viewModel.selectedBook {
                    if selectedBook.status == .deleted {
                        recoverButton(for: selectedBook)
                        permanentDeleteButton(for: selectedBook)
                    } else {
                        softDeleteButton(for: selectedBook)
                    }
                } else {
                    Button(action: {}) {
                        Image(systemName: "trash")
                    }
                    .disabled(true)
                }
            }
        }
    }
    
    private func recoverButton(for book: BookData) -> some View {
        Button(action: {
            viewModel.recoverBook(book)
        }) {
            Image(systemName: "return")
        }
        .help("Recover Book")
        .accessibilityLabel("Recover Book")
    }
    
    private func permanentDeleteButton(for book: BookData) -> some View {
        Button(action: {
            appState.showPermanentDeleteConfirmation(for: book)
        }) {
            Image(systemName: "trash")
        }
        .help("Permanently Delete Book")
        .accessibilityLabel("Permanently Delete Book")
    }
    
    private func softDeleteButton(for book: BookData) -> some View {
        Button(action: {
            appState.showSoftDeleteConfirmation(for: book)
        }) {
            Image(systemName: "trash")
        }
        .help("Delete")
        .accessibilityLabel("Move Book to Deleted")
    }
}

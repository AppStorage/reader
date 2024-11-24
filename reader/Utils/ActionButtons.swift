import SwiftUI

struct ActionButtons: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState

    @State private var showSoftDeleteConfirmation = false
    @State private var showPermanentDeleteConfirmation = false
    @State private var bookToDelete: BookData?

    var body: some View {
        if let selectedBook = viewModel.selectedBook {
            HStack(spacing: 12) {
                if selectedBook.status == .deleted {
                    recoverButton(for: selectedBook)
                    permanentDeleteButton(for: selectedBook)
                } else {
                    softDeleteButton(for: selectedBook)
                }
            }
            .alert("This will move the book to deleted.", isPresented: $showSoftDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete") {
                    if let book = bookToDelete {
                        viewModel.softDeleteBook(book)
                    }
                }
            }
            .alert("This will permanently delete the book. You can't undo this action.", isPresented: $showPermanentDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete") {
                    if let book = bookToDelete {
                        viewModel.permanentlyDeleteBook(book)
                    }
                }
            }
        }
    }

    // Recover button for deleted books
    private func recoverButton(for book: BookData) -> some View {
        Button(action: {
            viewModel.recoverBook(book)
        }) {
            Image(systemName: "return")
        }
        .accessibilityLabel("Recover")
    }

    // Permanent delete button for deleted books
    private func permanentDeleteButton(for book: BookData) -> some View {
        Button(action: {
            bookToDelete = book
            showPermanentDeleteConfirmation = true
        }) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
    }

    // Soft delete button for active books
    private func softDeleteButton(for book: BookData) -> some View {
        Button(action: {
            bookToDelete = book
            showSoftDeleteConfirmation = true
        }) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
    }
}

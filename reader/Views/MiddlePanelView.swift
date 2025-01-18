import SwiftUI

struct MiddlePanelView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedBookIDs: Set<UUID>
    
    var body: some View {
        VStack(spacing: 0) {
            bookList
        }
        .navigationTitle(
            viewModel.selectedCollection?.name ?? viewModel.selectedStatus.rawValue
        )
        .navigationSubtitle(
            "\(viewModel.displayedBooks.count) " +
            (viewModel.displayedBooks.count == 1 ? "Book" : "Books")
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SortMenuButton(viewModel: viewModel)
                    .help("Sort Options")
                    .accessibilityLabel("Sort Options")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    openWindow(id: "addBookWindow")
                }) {
                    Label("Add Book", systemImage: "plus")
                }
                .help("Add Book")
                .accessibilityLabel("Add Book")
            }
        }
    }
    
    // MARK: Book List
    private var bookList: some View {
        List(viewModel.displayedBooks, id: \.id, selection: $selectedBookIDs) { book in
            bookListItem(for: book)
        }
        .scrollContentBackground(.hidden)
        .overlay {
            if viewModel.displayedBooks.isEmpty {
                emptyStateView
            }
        }
        .onAppear { resetSelectedBooks() }
        .onChange(of: selectedBookIDs) { _, newValue in
            updateSelectedBook(with: newValue)
        }
    }
    
    private struct BookRow: View {
        let book: BookData
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func bookListItem(for book: BookData) -> some View {
        BookRow(book: book)
            .contextMenu { bookContextMenu(for: book) }
            .draggable(makeTransferData(for: book))
    }
    
    private func resetSelectedBooks() {
        selectedBookIDs = []
    }
    
    private func updateSelectedBook(with newSelection: Set<UUID>) {
        if let selectedID = newSelection.first,
           let book = viewModel.displayedBooks.first(where: { $0.id == selectedID }) {
            viewModel.selectedBook = book
        } else {
            viewModel.selectedBook = nil
        }
    }
    
    // MARK: Context Menu
    private func bookContextMenu(for book: BookData) -> some View {
        Group {
            if let selectedCollection = viewModel.selectedCollection {
                // Actions when viewing a collection
                collectionActions(for: book, in: selectedCollection)
            } else if allSelectedBooksAreDeleted() {
                // Actions for deleted books
                deletedBookActions(for: selectedBooks)
            } else {
                // Actions for active books
                activeBookActions(for: selectedBooks)
            }
        }
    }
    
    // Collection Actions
    private func collectionActions(for book: BookData, in collection: BookCollection) -> some View {
        Button("Remove from Collection") {
            viewModel.removeBookFromSelectedCollection(book)
        }
    }
    
    // Deleted Book Actions
    private func deletedBookActions(for books: [BookData]) -> some View {
        Group {
            Button("Restore") {
                for book in books {
                    viewModel.recoverBook(book)
                }
            }
            Button("Permanently Delete") {
                appState.showPermanentDeleteConfirmation(for: books)
            }
        }
    }
    
    // Active Book Actions
    private func activeBookActions(for books: [BookData]) -> some View {
        Group {
            Button("Mark as Unread") {
                updateStatus(for: books, to: .unread)
            }
            Button("Mark as Reading") {
                updateStatus(for: books, to: .reading)
            }
            Button("Mark as Read") {
                updateStatus(for: books, to: .read)
            }
            
            Divider()
            
            Button("Delete") {
                appState.showSoftDeleteConfirmation(for: books)
            }
        }
    }
    
    // MARK: Status Update
    private func updateStatus(for books: [BookData], to status: ReadingStatus) {
        viewModel.updateBookStatus(for: books, to: status)
    }
    
    // MARK: Computed Property for Selected Books
    private var selectedBooks: [BookData] {
        viewModel.displayedBooks.filter { selectedBookIDs.contains($0.id) }
    }
    
    // MARK: Empty State Views
    private var emptyStateView: some View {
        EmptyStateView(type: emptyStateType, viewModel: viewModel)
    }
    
    private var emptyStateType: EmptyStateType {
        if viewModel.selectedCollection != nil {
            return .collection
        } else if viewModel.searchQuery.isEmpty {
            switch viewModel.selectedStatus {
            case .deleted: return .deleted
            case .unread: return .unread
            case .reading: return .reading
            case .read: return .read
            default: return .list
            }
        } else {
            // Show search empty state when there's a query
            return viewModel.selectedStatus == .deleted ? .deleted : .search
        }
    }
    
    // MARK: Helpers
    private func makeTransferData(for book: BookData) -> BookTransferData {
        BookTransferData(
            title: book.title,
            author: book.author,
            published: book.published,
            publisher: book.publisher,
            genre: book.genre,
            series: book.series,
            isbn: book.isbn,
            bookDescription: book.bookDescription
        )
    }
    
    private func allSelectedBooksAreDeleted() -> Bool {
        selectedBooks.allSatisfy { $0.status == .deleted }
    }
}

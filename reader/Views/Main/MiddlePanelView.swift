import SwiftUI
import Combine

struct MiddlePanelView: View {
    @Binding var selectedBookIDs: Set<UUID>
    
    @ObservedObject var contentViewModel: ContentViewModel
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject var overlayManager: OverlayManager
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            bookList
        }
        .navigationTitle(
            contentViewModel.selectedCollection?.name ?? contentViewModel.selectedStatus.rawValue
        )
        .navigationSubtitle(
            "\(contentViewModel.displayedBooks.count) " +
            (contentViewModel.displayedBooks.count == 1 ? "Book" : "Books")
        )
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                SortMenuButton(contentViewModel: contentViewModel)
                    .help("Sort Options")
                    .accessibilityLabel("Sort Options")
                
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
    
    // MARK: - Book List
    private var bookList: some View {
        List(contentViewModel.displayedBooks, id: \.id, selection: $selectedBookIDs) { book in
            bookListItem(for: book)
        }
        .scrollContentBackground(.hidden)
        .overlay {
            if contentViewModel.displayedBooks.isEmpty {
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
           let book = contentViewModel.displayedBooks.first(where: { $0.id == selectedID }) {
            contentViewModel.selectedBook = book
        } else {
            contentViewModel.selectedBook = nil
        }
    }
    
    // MARK: - Context Menu
    private func bookContextMenu(for book: BookData) -> some View {
        Group {
            if let selectedCollection = contentViewModel.selectedCollection {
                // Actions when viewing a collection
                collectionActions(for: book, in: selectedCollection)
            } else if book.status == .deleted {
                // Actions for deleted books
                deletedBookActions(for: [book])
            } else {
                // Actions for active books
                activeBookActions(for: [book])
            }
        }
    }
    
    private func collectionActions(for book: BookData, in collection: BookCollection) -> some View {
        Button("Remove from Collection") {
            overlayManager.showLoading(message: "Removing from collection...")
            
            contentViewModel.removeBookFromSelectedCollection(book)
                .sink(receiveValue: {
                    overlayManager.hideOverlay()
                    overlayManager.showToast(message: "Removed from collection")
                })
                .store(in: &cancellables)
        }
    }
    
    private func deletedBookActions(for books: [BookData]) -> some View {
        Group {
            Button("Restore") {
                if !books.isEmpty {
                    let loadingMessage = books.count == 1 ?
                    "Restoring book..." :
                    "Restoring \(books.count) books..."
                    overlayManager.showLoading(message: loadingMessage)
                    
                    let publishers = books.map { contentViewModel.recoverBook($0) }
                    
                    Publishers.MergeMany(publishers)
                        .collect()
                        .sink(receiveValue: { _ in
                            overlayManager.hideOverlay()
                            
                            let message = books.count == 1 ?
                            "Book restored" :
                            "\(books.count) books restored"
                            overlayManager.showToast(message: message)
                        })
                        .store(in: &cancellables)
                }
            }
            Button("Permanently Delete") {
                alertManager.showPermanentDeleteConfirmation(for: books)
            }
        }
    }
    
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
                alertManager.showSoftDeleteConfirmation(for: books)
            }
        }
    }
    
    // MARK: - Status Update
    private func updateStatus(for books: [BookData], to status: ReadingStatus) {
        if !books.isEmpty {
            let statusVerb: String
            switch status {
            case .unread: statusVerb = "Marking as unread"
            case .reading: statusVerb = "Marking as reading"
            case .read: statusVerb = "Marking as read"
            case .deleted: statusVerb = "Deleting"
            }
            
            let loadingMessage = books.count == 1 ?
            "\(statusVerb) book..." :
            "\(statusVerb) \(books.count) books..."
            
            overlayManager.showLoading(message: loadingMessage)
            
            contentViewModel.updateBookStatus(for: books, to: status)
                .sink(receiveValue: {
                    overlayManager.hideOverlay()
                    
                    let pastTenseVerb: String
                    switch status {
                    case .unread: pastTenseVerb = "marked as unread"
                    case .reading: pastTenseVerb = "marked as reading"
                    case .read: pastTenseVerb = "marked as read"
                    case .deleted: pastTenseVerb = "deleted"
                    }
                    
                    let message = books.count == 1 ?
                    "Book \(pastTenseVerb)" :
                    "\(books.count) books \(pastTenseVerb)"
                    
                    overlayManager.showToast(message: message)
                })
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Selected Books
    private var selectedBooks: [BookData] {
        contentViewModel.displayedBooks.filter { selectedBookIDs.contains($0.id) }
    }
    
    // MARK: - Empty State Views
    private var emptyStateView: some View {
        EmptyStateView(type: emptyStateTypes)
    }
    
    private var emptyStateTypes: EmptyStateTypes {
        if contentViewModel.selectedCollection != nil {
            return .collection
        } else if contentViewModel.searchQuery.isEmpty {
            switch contentViewModel.selectedStatus {
            case .deleted: return .deleted
            case .unread: return .unread
            case .reading: return .reading
            case .read: return .read
            default: return .list
            }
        } else {
            // Show search empty state when there's a query
            return contentViewModel.selectedStatus == .deleted ? .deleted : .search
        }
    }
    
    // MARK: - Helpers
    private func makeTransferData(for book: BookData) -> BookTransferData {
        BookTransferData(
            title: book.title,
            author: book.author,
            published: book.published,
            publisher: book.publisher,
            genre: book.genre,
            series: book.series,
            isbn: book.isbn,
            bookDescription: book.bookDescription,
            status: book.status.rawValue,
            dateStarted: book.dateStarted,
            dateFinished: book.dateFinished,
            quotes: book.quotes,
            notes: book.notes,
            tags: book.tags,
            rating: book.rating
        )
    }
    
    private func allSelectedBooksAreDeleted() -> Bool {
        selectedBooks.allSatisfy { $0.status == .deleted }
    }
}

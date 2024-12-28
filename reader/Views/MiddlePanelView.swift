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
        .navigationTitle("\(viewModel.selectedStatus.rawValue)")
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
    
    private var bookList: some View {
        List(viewModel.displayedBooks, id: \.id, selection: $selectedBookIDs) { book in
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
            .contextMenu { bookContextMenu() }
        }
        .scrollContentBackground(.hidden)
        .overlay {
            if viewModel.displayedBooks.isEmpty {
                emptyStateView
            }
        }
        .onAppear { selectedBookIDs = [] }
        .onChange(of: selectedBookIDs) { _, newValue in
            if let selectedID = newValue.first,
               let book = viewModel.displayedBooks.first(where: { $0.id == selectedID }) {
                viewModel.selectedBook = book
            } else {
                viewModel.selectedBook = nil
            }
        }
    }
    
    // MARK: Context Menu
    private func bookContextMenu() -> some View {
        Group {
            if selectedBooks.allSatisfy({ $0.status == .deleted }) {
                // Deleted Books: Restore and Permanently Delete
                Button("Restore") {
                    for book in selectedBooks {
                        viewModel.recoverBook(book)
                    }
                }
                Button("Permanently Delete") {
                    appState.showPermanentDeleteConfirmation(for: selectedBooks)
                }
            } else {
                // Active Books: Status Change Options
                Button("Mark as Unread") {
                    updateStatus(for: selectedBooks, to: .unread)
                }
                Button("Mark as Reading") {
                    updateStatus(for: selectedBooks, to: .reading)
                }
                Button("Mark as Read") {
                    updateStatus(for: selectedBooks, to: .read)
                }
                
                Divider()
                
                // Soft Delete
                Button("Delete") {
                    appState.showSoftDeleteConfirmation(for: selectedBooks)
                }
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
        if viewModel.searchQuery.isEmpty {
            switch viewModel.selectedStatus {
            case .deleted: return .deleted
            case .unread: return .unread
            case .reading: return .reading
            case .read: return .read
            default: return .list
            }
        } else {
            return viewModel.selectedStatus == .deleted ? .deleted : .search
        }
    }
}

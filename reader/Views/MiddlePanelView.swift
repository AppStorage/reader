import SwiftUI

struct MiddlePanelView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var localSelectedBook: BookData?
    
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
            // Sort button
            ToolbarItem(placement: .automatic) {
                SortMenuButton(viewModel: viewModel)
                    .help("Sort Options")
                    .accessibilityLabel("Sort Options")
            }
            
            // Add book button
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    openWindow(id: "addBookWindow")
                }) {
                    Image(systemName: "plus")
                }
                .help("Add Book")
                .accessibilityLabel("Add Book")
            }
        }
    }
    
    private var bookList: some View {
        Group {
            if viewModel.displayedBooks.isEmpty {
                emptyStateView
            } else {
                List(viewModel.displayedBooks, id: \.id, selection: $localSelectedBook) { book in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.headline)
                        Text(book.author)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    .tag(book)
                }
                .scrollContentBackground(.hidden)
                .onChange(of: localSelectedBook) { _, newValue in
                    DispatchQueue.main.async {
                        viewModel.selectedBook = newValue
                    }
                }
                .onAppear {
                    localSelectedBook = viewModel.selectedBook
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(type: emptyStateType)
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

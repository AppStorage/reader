import SwiftUI

struct MiddlePanelView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    @State private var localSelectedBook: BookData?
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            bookList
        }
        .navigationTitle("Library")
        .onChange(of: localSelectedBook) { oldValue, newSelectedBook in
            if let newSelectedBook = newSelectedBook {
                if newSelectedBook.status == .deleted {
                    viewModel.selectedBook = newSelectedBook
                } else {
                    viewModel.selectedBook = newSelectedBook
                }
            } else {
                viewModel.selectedBook = nil
            }
        }
        .onChange(of: viewModel.selectedBook) { oldValue, newSelectedBook in
            localSelectedBook = newSelectedBook
        }
        .onAppear {
            localSelectedBook = viewModel.selectedBook
        }
    }
    
    private var toolbar: some View {
        HStack {
            // Search bar on the left
            SearchBar(text: $viewModel.searchQuery)
                .frame(maxWidth: .infinity)
            
            // Buttons on the right
            HStack(spacing: 16) {
                // Sort Menu
                Menu {
                    sortOptions
                    Divider()
                    sortOrderOptions
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Sort")
                .help("Sort")

                // Add Book Button
                Button(action: {
                    openWindow(id: "addBookWindow")
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                        .brightness(isHovered ? 0.5 : 0)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add Book")
                .help("Add Book")
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var bookList: some View {
        Group {
            if viewModel.displayedBooks.isEmpty {
                if viewModel.searchQuery.isEmpty && viewModel.selectedStatus == .deleted {
                    EmptyDeletedListView()
                } else if viewModel.searchQuery.isEmpty {
                    EmptyListView()
                } else {
                    EmptySearchListView()
                }
            } else {
                List(viewModel.displayedBooks, id: \.id, selection: $localSelectedBook) { book in
                    BookRowView(book: book)
                        .tag(book)
                }
            }
        }
    }

    private var sortOptions: some View {
        Group {
            Button(action: { viewModel.sortOption = .title }) {
                HStack {
                    Text("Title")
                    if viewModel.sortOption == .title {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: { viewModel.sortOption = .author }) {
                HStack {
                    Text("Author")
                    if viewModel.sortOption == .author {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: { viewModel.sortOption = .published }) {
                HStack {
                    Text("Published")
                    if viewModel.sortOption == .published {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private var sortOrderOptions: some View {
        Group {
            Button(action: { viewModel.sortOrder = .ascending }) {
                HStack {
                    Text("Ascending")
                    if viewModel.sortOrder == .ascending {
                        Spacer()
                        Image(systemName: "arrow.up")
                    }
                }
            }
            Button(action: { viewModel.sortOrder = .descending }) {
                HStack {
                    Text("Descending")
                    if viewModel.sortOrder == .descending {
                        Spacer()
                        Image(systemName: "arrow.down")
                    }
                }
            }
        }
    }
}

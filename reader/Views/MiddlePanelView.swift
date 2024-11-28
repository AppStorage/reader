import SwiftUI

struct MiddlePanelView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isHovered = false
    @State private var localSelectedBook: BookData?
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            bookList
        }
        .navigationTitle("Library")
        .onChange(of: localSelectedBook) { oldValue, newSelectedBook in
            if let newSelectedBook = newSelectedBook {
                viewModel.selectedBook = newSelectedBook
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
    
    // MARK: - Toolbar
    private var toolbar: some View {
        HStack {
            SearchBar(text: $viewModel.searchQuery)
                .frame(maxWidth: .infinity)
            
            toolbarActions
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var toolbarActions: some View {
        HStack(spacing: 16) {
            sortMenu
            addBookButton
        }
    }
    
    private var sortMenu: some View {
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
    }
    
    private var addBookButton: some View {
        Button(action: {
            openWindow(id: "addBookWindow")
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .foregroundColor(buttonForegroundColor)
                .brightness(buttonBrightness)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Add Book")
        .help("Add Book")
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // Determine the button's foreground color based on hover state and color scheme
    private var buttonForegroundColor: Color {
        isHovered && colorScheme == .light ? .accentColor : .primary
    }
    
    // Determine the button's brightness based on hover state and color scheme
    private var buttonBrightness: Double {
        isHovered ? (colorScheme == .dark ? 0.5 : 0) : 0
    }
    
    // MARK: - Book List
    private var bookList: some View {
        Group {
            if viewModel.displayedBooks.isEmpty {
                emptyStateView
            } else {
                List(viewModel.displayedBooks, id: \.id, selection: $localSelectedBook) { book in
                    BookRowView(book: book)
                        .tag(book)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        Group {
            if viewModel.searchQuery.isEmpty && viewModel.selectedStatus == .deleted {
                EmptyDeletedListView()
            } else if viewModel.searchQuery.isEmpty {
                EmptyListView()
            } else {
                EmptySearchListView()
            }
        }
    }
    
    // MARK: - Sort Options
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

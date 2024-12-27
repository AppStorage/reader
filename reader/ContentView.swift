import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var viewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var searchText: String = ""
    @State private var selectedBookIDs: Set<UUID> = []
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .frame(width: 225)
        } content: {
            MiddlePanelView(viewModel: viewModel, selectedBookIDs: $selectedBookIDs)
                .frame(minWidth: 400, maxWidth: .infinity)
        } detail: {
            if selectedBookIDs.count > 1 {
                // Multiple Selection View
                let selectedBooks = viewModel.displayedBooks.filter { selectedBookIDs.contains($0.id) }
                MultipleSelectionView(
                    count: selectedBooks.count,
                    selectedBooks: selectedBooks,
                    viewModel: viewModel,
                    dataManager: dataManager
                )
                .frame(minWidth: 450, maxWidth: .infinity)
            } else if let selectedID = selectedBookIDs.first,
                      let selectedBook = viewModel.displayedBooks.first(where: { $0.id == selectedID }) {
                DetailView(book: selectedBook)
                    .frame(minWidth: 450, maxWidth: .infinity)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            StatusButtons(books: [selectedBook], dataManager: dataManager)
                        }
                        ToolbarItem(placement: .automatic) {
                            Spacer()
                        }
                        ToolbarItem(placement: .automatic) {
                            BookActionButton(viewModel: viewModel, selectedBooks: [selectedBook])
                        }
                    }
            } else {
                EmptyStateView(type: .detail)
                    .frame(minWidth: 450, maxWidth: .infinity)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Spacer()
                        }
                        ToolbarItem(placement: .automatic) {
                            BookActionButton(viewModel: viewModel, selectedBooks: [])
                        }
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $viewModel.searchQuery, placement: .sidebar)
    }
}

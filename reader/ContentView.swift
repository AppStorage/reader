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
                let selectedBooks = viewModel.displayedBooks.filter { selectedBookIDs.contains($0.id) }
                MultipleSelectionView(count: selectedBooks.count, selectedBooks: selectedBooks, viewModel: viewModel, dataManager: dataManager)
                    .frame(minWidth: 450, maxWidth: .infinity)
            } else if let selectedID = selectedBookIDs.first,
                      let selectedBook = viewModel.displayedBooks.first(where: { $0.id == selectedID }) {
                DetailView(book: selectedBook)
                    .frame(minWidth: 450, maxWidth: .infinity)
            } else {
                EmptyStateView(type: .detail, viewModel: viewModel)
                    .frame(minWidth: 450, maxWidth: .infinity)
            }
        }
        .onChange(of: selectedBookIDs) { _, newSelection in
            appState.selectedBooks = viewModel.displayedBooks.filter { newSelection.contains($0.id) }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $viewModel.searchQuery, placement: .sidebar)
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var viewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .frame(width: 225)
        } content: {
            MiddlePanelView(viewModel: viewModel)
                .frame(minWidth: 400, maxWidth: .infinity)
        } detail: {
            if let selectedBook = viewModel.selectedBook {
                DetailView(book: selectedBook)
                    .frame(minWidth: 450, maxWidth: .infinity)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            StatusButtons(
                                book: selectedBook,
                                updateStatus: { status in
                                    selectedBook.status = status
                                    StatusButtons.handleStatusChange(for: selectedBook, newStatus: status)
                                    StatusButtons.saveChanges(selectedBook, modelContext: modelContext)
                                }
                            )
                        }
                        ToolbarItem(placement: .automatic) {
                            Spacer()
                        }
                        ToolbarItem(placement: .automatic) {
                            BookActionButton(viewModel: viewModel)
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
                            BookActionButton(viewModel: viewModel)
                            
                        }
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $viewModel.searchQuery, placement: .sidebar)
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.openWindow) private var openWindow
    
    @ObservedObject var viewModel: ContentViewModel

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
        } content: {
            MiddlePanelView(viewModel: viewModel)
        } detail: {
            if let selectedBook = viewModel.selectedBook {
                DetailView(book: selectedBook)
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if viewModel.selectedBook != nil {
                    ActionButtons(viewModel: viewModel)
                }
            }
        }

    }
}

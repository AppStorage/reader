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
                .frame(width: 200)
                .layoutPriority(0)
        } content: {
            MiddlePanelView(viewModel: viewModel)
                .frame(minWidth: 400, maxWidth: .infinity)
        } detail: {
            if let selectedBook = viewModel.selectedBook {
                DetailView(book: selectedBook)
                    .frame(width: 450)
            } else {
                EmptyDetailView()
                    .frame(width: 450)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if viewModel.selectedBook != nil {
                    BookActionButton(viewModel: viewModel)
                }
            }
        }

    }
}

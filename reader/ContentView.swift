import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var alertManager: AlertManager
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var isSearching = false
    @State private var searchText: String = ""
    @State private var selectedBookIDs: Set<UUID> = []
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebarContent
            } content: {
                middleContent
            } detail: {
                detailContent
            }
            .onChange(of: selectedBookIDs) { oldValue, newValue in
                handleSelectedBooksChange(oldValue: oldValue, newValue: newValue)
            }
            .navigationSplitViewStyle(.balanced)
            .searchable(
                text: $contentViewModel.searchQuery,
                isPresented: $isSearching,
                placement: .sidebar,
                prompt: "Search books..."
            )
            .searchSuggestions {
                SearchSuggestionContainer(contentViewModel: contentViewModel)
            }
            .onSubmit(of: .search) {
                contentViewModel.submitSearch()
            }
            
            OverlayView()
        }
        .frame(minHeight: 475, maxHeight: .infinity)
        .alert(item: $alertManager.currentAlert) { alertType in
            AlertBuilder.createAlert(
                for: alertType,
                contentViewModel: contentViewModel,
                appState: appState
            )
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        SidebarView(contentViewModel: contentViewModel)
            .frame(width: 225)
    }
    
    // MARK: - Book List
    private var middleContent: some View {
        Group {
            if contentViewModel.showDashboard {
                ReadingDashboardView()
                    .frame(minWidth: 800, maxWidth: .infinity)
            } else {
                MiddlePanelView(
                    selectedBookIDs: $selectedBookIDs, contentViewModel: contentViewModel
                )
                .frame(minWidth: 350, maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Third Pane
    @ViewBuilder
    private var detailContent: some View {
        if contentViewModel.showDashboard {
            EmptyView()
        } else if selectedBookIDs.count > 1 {
            multipleSelectionView
        } else if let selectedBook = getSelectedBook() {
            SingleBookDetailView(book: selectedBook)
        } else {
            EmptyStateView(type: .detail)
                .frame(minWidth: 450, maxWidth: .infinity)
        }
    }
    
    // MARK: - Multiple Books Selected
    private var multipleSelectionView: some View {
        let selectedBooks = getSelectedBooks()
        return MultipleSelectionView(
            selectedBooks: selectedBooks
        )
        .environmentObject(dataManager)
        .environmentObject(contentViewModel)
        .frame(minWidth: 450, maxWidth: .infinity)
    }
    
    // MARK: - Book Details
    private func SingleBookDetailView(book: BookData) -> some View {
        DetailView(book: book)
            .frame(minWidth: 450, maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    private func getSelectedBook() -> BookData? {
        guard let selectedID = selectedBookIDs.first else { return nil }
        return contentViewModel.displayedBooks.first { $0.id == selectedID }
    }
    
    private func getSelectedBooks() -> [BookData] {
        return contentViewModel.displayedBooks.filter {
            selectedBookIDs.contains($0.id)
        }
    }
    
    private func handleSelectedBooksChange(oldValue: Set<UUID>, newValue: Set<UUID>) {
        if oldValue != newValue {
            appState.selectedBooks = contentViewModel.displayedBooks.filter {
                newValue.contains($0.id)
            }
        }
    }
}

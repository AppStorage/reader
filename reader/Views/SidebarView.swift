import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var overlayManager: OverlayManager
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var selectedSidebarItem: SidebarSelection?
    @State private var collectionToRename: BookCollection?
    @State private var isRenamingCollection = false
    @State private var isAddingCollection = false
    @State private var newCollectionName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedSidebarItem) {
                Section {
                    Label("Dashboard", systemImage: "chart.pie")
                        .tag(SidebarSelection.dashboard)
                }
                
                readingStatusSection
                collectionsSection
            }
            .listStyle(.sidebar)
            .onChange(of: selectedSidebarItem) { oldValue, newValue in
                handleSidebarSelection(newValue)
            }
            .onAppear {
                ensureSidebarSelection()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isAddingCollection = true
                    }) {
                        Label(
                            "New Collection", systemImage: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isRenamingCollection) {
                RenameCollectionSheet(
                    collectionName: $newCollectionName,
                    existingCollectionNames: dataManager.collections.map {
                        $0.name
                    },
                    onRename: {
                        guard collectionToRename != nil else { return }
                        viewModel.renameSelectedCollection(
                            to: newCollectionName)
                        isRenamingCollection = false
                    },
                    onCancel: {
                        isRenamingCollection = false
                    }
                )
            }
            .sheet(isPresented: $isAddingCollection) {
                AddCollectionSheet(
                    collectionName: $newCollectionName,
                    existingCollectionNames: dataManager.collections.map {
                        $0.name
                    },
                    onAdd: {
                        addNewCollection()
                    },
                    onCancel: {
                        isAddingCollection = false
                        newCollectionName = ""
                    }
                )
            }
            settingsButton
        }
    }
    
    // MARK: Sections
    private var readingStatusSection: some View {
        Section(header: Text("Reading Status")) {
            ForEach(StatusFilter.allCases) { status in
                Label(status.rawValue, systemImage: status.iconName)
                    .badge(viewModel.bookCount(for: status))
                    .tag(SidebarSelection.status(status))
                    .dropDestination(for: BookTransferData.self) { items, _ in
                        updateBookStatus(for: items, with: status)
                    }
            }
        }
    }
    
    private var collectionsSection: some View {
        Section(header: Text("Collections")) {
            ForEach(
                dataManager.collections.sorted(by: {
                    $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
                })
            ) { collection in
                Label(collection.name, systemImage: "folder")
                    .badge(viewModel.bookCount(for: collection))
                    .tag(SidebarSelection.collection(collection))
                    .dropDestination(for: BookTransferData.self) { items, _ in
                        addBookToCollection(items, collection: collection)
                    }
                    .contextMenu {
                        Button("Rename Collection") {
                            collectionToRename = collection
                            newCollectionName = collection.name
                            isRenamingCollection = true
                        }
                        Button("Delete Collection") {
                            deleteCollection(collection)
                        }
                    }
            }
        }
    }
    
    private var settingsButton: some View {
        HStack {
            SettingsButton {
                readerApp.showSettingsWindow(
                    appState: appState, dataManager: dataManager
                ) {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }
            }
            Spacer()
        }
    }
    
    // MARK: Collection Actions
    private func addNewCollection() {
        dataManager.addCollection(named: newCollectionName)
        overlayManager.showOverlay(
            message: "Added collection: \(newCollectionName)")
        newCollectionName = ""
        isAddingCollection = false
    }
    
    private func deleteCollection(_ collection: BookCollection) {
        dataManager.removeCollection(collection)
        selectedSidebarItem = nil
        overlayManager.showOverlay(message: "Deleted \(collection.name)")
    }
    
    private func addBookToCollection(
        _ items: [BookTransferData], collection: BookCollection
    ) -> Bool {
        guard
            let targetCollection = dataManager.collections.first(where: {
                $0.id == collection.id
            })
        else {
            overlayManager.showOverlay(message: "\(collection.name) not found")
            return false
        }
        
        let existingBooks = items.filter { item in
            targetCollection.books.contains { book in
                book.title == item.title && book.author == item.author
            }
        }
        
        if !existingBooks.isEmpty {
            if existingBooks.count == 1 {
                overlayManager.showOverlay(
                    message:
                        "\"\(existingBooks[0].title)\" is already in \(collection.name)"
                )
            } else {
                overlayManager.showOverlay(
                    message:
                        "\(existingBooks.count) books are already in \(collection.name)"
                )
            }
            return false
        }
        
        let booksToAdd = items.compactMap { item in
            viewModel.books.first {
                $0.title == item.title && $0.author == item.author
            }
        }
        
        dataManager.addBookToCollection(booksToAdd, to: targetCollection)
        
        if booksToAdd.count == 1, let firstBook = booksToAdd.first {
            overlayManager.showOverlay(
                message: "Added \"\(firstBook.title)\" to \(collection.name)")
        } else {
            overlayManager.showOverlay(
                message: "Added \(booksToAdd.count) books to \(collection.name)"
            )
        }
        
        return true
    }
    
    // MARK: Helpers
    private func handleSidebarSelection(_ selection: SidebarSelection?) {
        switch selection {
        case .dashboard:
            viewModel.selectedStatus = .all
            viewModel.selectedCollection = nil
            viewModel.showDashboard = true
        case .status(let status):
            viewModel.selectedStatus = status
            viewModel.selectedCollection = nil
            viewModel.showDashboard = false
        case .collection(let collection):
            viewModel.selectedCollection = collection
            viewModel.showDashboard = false
        case .none:
            viewModel.selectedCollection = nil
            viewModel.selectedStatus = .all
            viewModel.showDashboard = false
        }
    }
    
    private func ensureSidebarSelection() {
        if viewModel.showDashboard && selectedSidebarItem != .dashboard {
            selectedSidebarItem = .dashboard
        } else if viewModel.selectedStatus != .all && selectedSidebarItem == nil
        {
            selectedSidebarItem = .status(viewModel.selectedStatus)
        } else if let collection = viewModel.selectedCollection,
                  selectedSidebarItem == nil
        {
            selectedSidebarItem = .collection(collection)
        }
    }
    
    private func updateBookStatus(
        for items: [BookTransferData], with status: StatusFilter
    ) -> Bool {
        guard let newStatus = status.toReadingStatus() else {
            overlayManager.showOverlay(
                message: "Cannot change status to \"All\"")
            return false
        }
        
        let alreadyInStatus = items.filter { item in
            viewModel.books.contains { book in
                book.title == item.title && book.author == item.author
                && book.status == newStatus
            }
        }
        
        if !alreadyInStatus.isEmpty {
            if alreadyInStatus.count == 1 {
                overlayManager.showOverlay(
                    message:
                        "\"\(alreadyInStatus[0].title)\" is already marked as \(newStatus.displayText)"
                )
            } else {
                overlayManager.showOverlay(
                    message:
                        "\(alreadyInStatus.count) books are already marked as \(newStatus.displayText)"
                )
            }
            return false
        }
        
        let booksToUpdate = items.compactMap { item in
            viewModel.books.first {
                $0.title == item.title && $0.author == item.author
            }
        }
        
        viewModel.updateBookStatus(for: booksToUpdate, to: newStatus)
        
        if booksToUpdate.count == 1, let firstBook = booksToUpdate.first {
            overlayManager.showOverlay(
                message:
                    "Changed status of \"\(firstBook.title)\" to \(newStatus.displayText)"
            )
        } else {
            overlayManager.showOverlay(
                message:
                    "Changed status of \(booksToUpdate.count) books to \(newStatus.displayText)"
            )
        }
        
        return true
    }
}

enum SidebarSelection: Hashable {
    case dashboard
    case status(StatusFilter)
    case collection(BookCollection)
}

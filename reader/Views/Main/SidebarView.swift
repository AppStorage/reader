import SwiftUI
import Combine

// MARK: - Sidebar View Selection
private enum SidebarSelection: Hashable {
    case dashboard
    case status(StatusFilter)
    case collection(BookCollection)
}

// MARK: - Sidebar
struct SidebarView: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var overlayManager: OverlayManager
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var isAddingCollection = false
    @State private var isRenamingCollection = false
    @State private var newCollectionName: String = ""
    @State private var collectionToRename: BookCollection?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedSidebarItem: SidebarSelection?
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedSidebarItem) {
                Section {
                    Label("Dashboard", systemImage: "chart.pie")
                        .tag(SidebarSelection.dashboard)
                        .foregroundStyle(.primary)
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
                CollectionSheet(
                    mode: .rename,
                    collectionName: $newCollectionName,
                    existingCollectionNames: dataManager.collections.map { $0.name },
                    originalName: collectionToRename?.name,
                    onAction: {
                        guard collectionToRename != nil else { return }
                        dataManager.renameCollection(collectionToRename!, to: newCollectionName)
                            .sink(receiveCompletion: { _ in },
                                  receiveValue: {
                                overlayManager.showToast(message: "Renamed collection to \(newCollectionName)")
                                isRenamingCollection = false
                            })
                            .store(in: &cancellables)
                    },
                    onCancel: {
                        isRenamingCollection = false
                    }
                )
            }
            .sheet(isPresented: $isAddingCollection) {
                CollectionSheet(
                    mode: .add,
                    collectionName: $newCollectionName,
                    existingCollectionNames: dataManager.collections.map { $0.name },
                    onAction: {
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
    
    // MARK: - Reading Section
    private var readingStatusSection: some View {
        Section(header: Text("Reading Status")) {
            ForEach(StatusFilter.allCases) { status in
                Label(status.rawValue, systemImage: status.iconName)
                    .badge(contentViewModel.bookCount(for: status))
                    .tag(SidebarSelection.status(status))
                    .dropDestination(for: BookTransferData.self) { items, _ in
                        updateBookStatus(for: items, with: status)
                    }
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - Collection Section
    private var collectionsSection: some View {
        Section(header: Text("Collections")) {
            ForEach(
                dataManager.collections.sorted(by: {
                    $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
                })
            ) { collection in
                Label(collection.name, systemImage: "folder")
                    .badge(contentViewModel.bookCount(for: collection))
                    .tag(SidebarSelection.collection(collection))
                    .foregroundStyle(.primary)
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
    
    // MARK: - Settings Button
    private var settingsButton: some View {
        HStack {
            SettingsButton {
                openWindow(id: "preferencesWindow")
            }
            Spacer()
        }
    }
    
    // MARK: - Collection Actions
    private func addNewCollection() {
        dataManager.addCollection(named: newCollectionName)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                overlayManager.showToast(message: "Added collection: \(newCollectionName)")
                newCollectionName = ""
                isAddingCollection = false
            })
            .store(in: &cancellables)
    }
    
    private func deleteCollection(_ collection: BookCollection) {
        dataManager.removeCollection(collection)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                selectedSidebarItem = nil
                overlayManager.showToast(message: "Deleted \(collection.name)")
            })
            .store(in: &cancellables)
    }
    
    private func addBookToCollection(
        _ items: [BookTransferData], collection: BookCollection
    ) -> Bool {
        guard
            let targetCollection = dataManager.collections.first(where: {
                $0.id == collection.id
            })
        else {
            overlayManager.showToast(message: "\(collection.name) not found")
            return false
        }
        
        // Find the corresponding BookData objects
        let booksToAdd = items.compactMap { item in
            dataManager.books.first {
                $0.title == item.title && $0.author == item.author
            }
        }
        
        // Check which books are already in this collection
        let existingBooks = booksToAdd.filter { book in
            targetCollection.books.contains { existingBook in
                existingBook.id == book.id
            }
        }
        
        // Only add books that aren't already in the collection
        let newBooks = booksToAdd.filter { book in
            !existingBooks.contains { existingBook in
                existingBook.id == book.id
            }
        }
        
        if existingBooks.isEmpty && newBooks.isEmpty {
            overlayManager.showToast(message: "No books to add to \(collection.name)")
            return false
        }
        
        if !existingBooks.isEmpty {
            if existingBooks.count == 1 {
                overlayManager.showToast(
                    message: "\"\(existingBooks[0].title)\" is already in \(collection.name)"
                )
            } else {
                overlayManager.showToast(
                    message: "\(existingBooks.count) books are already in \(collection.name)"
                )
            }
        }
        
        // Only proceed if there are new books to add
        if !newBooks.isEmpty {
            dataManager.addBookToCollection(newBooks, to: targetCollection)
                .sink(receiveCompletion: { _ in },
                      receiveValue: {
                    if newBooks.count == 1 {
                        overlayManager.showToast(
                            message: "Added \"\(newBooks[0].title)\" to \(collection.name)"
                        )
                    } else {
                        overlayManager.showToast(
                            message: "Added \(newBooks.count) books to \(collection.name)"
                        )
                    }
                })
                .store(in: &cancellables)
            return true
        }
        
        return !existingBooks.isEmpty
    }
    
    // MARK: - Helpers
    private func handleSidebarSelection(_ selection: SidebarSelection?) {
        switch selection {
        case .dashboard:
            contentViewModel.selectedStatus = .all
            contentViewModel.selectedCollection = nil
            contentViewModel.showDashboard = true
        case .status(let status):
            contentViewModel.selectedStatus = status
            contentViewModel.selectedCollection = nil
            contentViewModel.showDashboard = false
        case .collection(let collection):
            contentViewModel.selectedCollection = collection
            contentViewModel.showDashboard = false
        case .none:
            contentViewModel.selectedCollection = nil
            contentViewModel.selectedStatus = .all
            contentViewModel.showDashboard = false
        }
    }
    
    private func ensureSidebarSelection() {
        if contentViewModel.showDashboard && selectedSidebarItem != .dashboard {
            selectedSidebarItem = .dashboard
        } else if contentViewModel.selectedStatus != .all && selectedSidebarItem == nil {
            selectedSidebarItem = .status(contentViewModel.selectedStatus)
        } else if let collection = contentViewModel.selectedCollection,
                  selectedSidebarItem == nil {
            selectedSidebarItem = .collection(collection)
        }
    }
    
    private func updateBookStatus(
        for items: [BookTransferData], with status: StatusFilter
    ) -> Bool {
        guard let newStatus = status.toReadingStatus() else {
            overlayManager.showToast(
                message: "Cannot change status to \"All\"")
            return false
        }
        
        let alreadyInStatus = items.filter { item in
            dataManager.books.contains { book in
                book.title == item.title && book.author == item.author
                && book.status == newStatus
            }
        }
        
        if !alreadyInStatus.isEmpty {
            if alreadyInStatus.count == 1 {
                overlayManager.showToast(
                    message:
                        "\"\(alreadyInStatus[0].title)\" is already marked as \(newStatus.displayText)"
                )
            } else {
                overlayManager.showToast(
                    message:
                        "\(alreadyInStatus.count) books are already marked as \(newStatus.displayText)"
                )
            }
            return false
        }
        
        let booksToUpdate = items.compactMap { item in
            dataManager.books.first {
                $0.title == item.title && $0.author == item.author
            }
        }
        
        contentViewModel.updateBookStatus(for: booksToUpdate, to: newStatus)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                if booksToUpdate.count == 1, let firstBook = booksToUpdate.first {
                    overlayManager.showToast(
                        message:
                            "Changed status of \"\(firstBook.title)\" to \(newStatus.displayText)"
                    )
                } else {
                    overlayManager.showToast(
                        message:
                            "Changed status of \(booksToUpdate.count) books to \(newStatus.displayText)"
                    )
                }
            })
            .store(in: &cancellables)
        
        return true
    }
}

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
        VStack {
            List(selection: $selectedSidebarItem) {
                readingStatusSection
                collectionsSection
            }
            .listStyle(.sidebar)
            .onChange(of: selectedSidebarItem) { _, newValue in
                handleSidebarSelection(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isAddingCollection = true
                    }) {
                        Label("New Collection", systemImage: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isRenamingCollection) {
                RenameCollectionSheet(
                    collectionName: $newCollectionName,
                    existingCollectionNames: dataManager.collections.map { $0.name },
                    onRename: {
                        guard let _ = collectionToRename else { return }
                        viewModel.renameSelectedCollection(to: newCollectionName)
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
                    existingCollectionNames: dataManager.collections.map { $0.name },
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
    
    private var settingsButton: some View {
        HStack {
            SettingsButton {
                readerApp.showSettingsWindow(appState: appState) {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }
            }
            Spacer()
        }
    }
    
    // MARK: Sections
    private var readingStatusSection: some View {
        Section(header: Text("Reading Status")) {
            ForEach(StatusFilter.allCases) { status in
                createSidebarLabel(
                    title: status.rawValue,
                    iconName: status.iconName,
                    tag: .status(status),
                    dropHandler: { items in
                        updateBookStatus(for: items, with: status)
                    }
                )
            }
        }
    }
    
    private var collectionsSection: some View {
        Section(header: Text("Collections")) {
            ForEach(dataManager.collections) { collection in
                createSidebarLabel(
                    title: collection.name,
                    iconName: "folder",
                    tag: .collection(collection),
                    dropHandler: { items in
                        addBookToCollection(items, collection: collection)
                    }
                )
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
    
    // MARK: Collection Actions
    private func addNewCollection() {
        overlayManager.showOverlay(message: "Adding collection...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dataManager.addCollection(named: newCollectionName)
            overlayManager.showOverlay(message: "Added collection: \(newCollectionName)")
            newCollectionName = ""
            isAddingCollection = false
        }
    }
    
    private func deleteCollection(_ collection: BookCollection) {
        overlayManager.showOverlay(message: "Deleting collection...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dataManager.removeCollection(collection)
            selectedSidebarItem = nil
            overlayManager.showOverlay(message: "Deleted \(collection.name)")
        }
    }
    
    private func addBookToCollection(_ items: [BookTransferData], collection: BookCollection) -> Bool {
        guard let targetCollection = dataManager.collections.first(where: { $0.id == collection.id }) else {
            overlayManager.showOverlay(message: "\(collection.name) not found")
            return false
        }
        
        let booksToAdd = items.compactMap { item in
            viewModel.books.first { $0.title == item.title && $0.author == item.author }
        }
        
        if booksToAdd.count == 1, let firstBook = booksToAdd.first {
            overlayManager.showOverlay(message: "Adding \"\(firstBook.title)\" to \(collection.name)...")
        } else {
            overlayManager.showOverlay(message: "Adding \(booksToAdd.count) books to \(collection.name)...")
        }
        
        dataManager.addBookToCollection(booksToAdd, to: targetCollection)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // 1.5-second delay
            if booksToAdd.count == 1, let firstBook = booksToAdd.first {
                overlayManager.showOverlay(message: "Added \"\(firstBook.title)\" to \(collection.name)")
            } else {
                overlayManager.showOverlay(message: "Added \(booksToAdd.count) books to \(collection.name)")
            }
        }
        
        return true
    }
    
    // MARK: Helpers
    private func createSidebarLabel(
        title: String,
        iconName: String,
        tag: SidebarSelection,
        dropHandler: @escaping ([BookTransferData]) -> Bool
    ) -> some View {
        Label(title, systemImage: iconName)
            .tag(tag)
            .dropDestination(for: BookTransferData.self) { items, _ in
                dropHandler(items)
            }
    }
    
    private func handleSidebarSelection(_ selection: SidebarSelection?) {
        switch selection {
        case .status(let status):
            viewModel.selectedStatus = status
            viewModel.selectedCollection = nil
        case .collection(let collection):
            viewModel.selectedCollection = collection
        case .none:
            viewModel.selectedCollection = nil
            viewModel.selectedStatus = .all
        }
    }
    
    private func updateBookStatus(for items: [BookTransferData], with status: StatusFilter) -> Bool {
        guard let newStatus = status.toReadingStatus() else {
            overlayManager.showOverlay(message: "Cannot change status to \"All\"")
            return false
        }
        
        let booksToUpdate = items.compactMap { item in
            viewModel.books.first { $0.title == item.title && $0.author == item.author }
        }
        
        if booksToUpdate.count == 1, let firstBook = booksToUpdate.first {
            overlayManager.showOverlay(message: "Changing status of \"\(firstBook.title)\" to \(newStatus.displayText)...")
        } else {
            overlayManager.showOverlay(message: "Changing status of \(booksToUpdate.count) books to \(newStatus.displayText)...")
        }
        
        viewModel.updateBookStatus(for: booksToUpdate, to: newStatus)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if booksToUpdate.count == 1, let firstBook = booksToUpdate.first {
                overlayManager.showOverlay(message: "Changed status of \"\(firstBook.title)\" to \(newStatus.displayText)")
            } else {
                overlayManager.showOverlay(message: "Changed status of \(booksToUpdate.count) books to \(newStatus.displayText)")
            }
        }
        
        return true
    }
}

enum SidebarSelection: Hashable {
    case status(StatusFilter)
    case collection(BookCollection)
}

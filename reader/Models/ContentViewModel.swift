import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @AppStorage("selectedStatus") var selectedStatus: StatusFilter = .all
    
    private(set) var books: [BookData] = [] {
        didSet {
            objectWillChange.send()
        }
    }
    
    var searchQuery: String = "" {
        didSet {
            // When search is started, switch from dashboard to books view
            if oldValue.isEmpty && !searchQuery.isEmpty && showDashboard {
                showDashboard = false
            }
            
            // When search is cleared, return to dashboard
            if !oldValue.isEmpty && searchQuery.isEmpty && !showDashboard {
                showDashboard = true
            }
            
            objectWillChange.send()
        }
    }
    
    var sortOption: SortOption = .title {
        didSet {
            objectWillChange.send()
        }
    }
    
    var sortOrder: SortOrder = .ascending {
        didSet {
            objectWillChange.send()
        }
    }
    
    var selectedBook: BookData? {
        didSet {
            objectWillChange.send()
        }
    }
    
    var selectedTags: Set<String> = [] {
        didSet {
            objectWillChange.send()
        }
    }
    
    var selectedCollection: BookCollection? {
        didSet {
            objectWillChange.send()
        }
    }
    
    var showDashboard: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    
    unowned let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        self.books = dataManager.books
    }
    
    func refreshData() {
        books = dataManager.books
    }
    
    func refreshAfterAction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refreshData()
        }
    }
    
    // Filters and sorting
    var displayedBooks: [BookData] {
        if let collection = selectedCollection {
            let collectionBooks = collection.books
            if !searchQuery.isEmpty {
                return collectionBooks.searched(with: searchQuery)
            }
            return collectionBooks.sorted(by: sortOption, order: sortOrder)
        } else {
            let filteredByStatus = books.filtered(by: selectedStatus)
            
            let filteredByTags = selectedTags.isEmpty
            ? filteredByStatus
            : filteredByStatus.filter { book in
                let bookTags = Set(book.tags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
                let selectedTagsLower = Set(selectedTags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
                return !selectedTagsLower.isDisjoint(with: bookTags)
            }
            
            if !searchQuery.isEmpty {
                return filteredByTags.searched(with: searchQuery)
            }
            
            return filteredByTags.sorted(by: sortOption, order: sortOrder)
        }
    }
    
    // Status count
    func bookCount(for status: StatusFilter) -> Int {
        return books.count(for: status)
    }
    
    // Collection count
    func bookCount(for collection: BookCollection?) -> Int {
        guard let collection = collection else { return 0 }
        return collection.books.count
    }
    
    func recoverBook(_ book: BookData) {
        dataManager.updateBookStatus(book, to: .unread)
        book.updateDates(for: .unread)
        refreshAfterAction()
    }
    
    func softDeleteBooks(_ books: [BookData]) {
        dataManager.softDeleteBooks(books)
        refreshAfterAction()
    }
    
    func permanentlyDeleteBooks(_ booksToDelete: [BookData]) {
        dataManager.permanentlyDeleteBooks(booksToDelete)
        refreshAfterAction()
    }
    
    func updateBookStatus(for books: [BookData], to status: ReadingStatus) {
        for book in books {
            dataManager.updateBookStatus(book, to: status)
        }
        refreshAfterAction()
    }
    
    // MARK: Tags
    func toggleTagSelection(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearTag(_ tag: String) {
        selectedTags.remove(tag)
    }
    
    // MARK: Collections
    func renameSelectedCollection(to newName: String) {
        guard let collection = selectedCollection else { return }
        dataManager.renameCollection(collection, to: newName)
        refreshAfterAction()
    }
    
    func removeCollection(_ collection: BookCollection) {
        dataManager.removeCollection(collection)
        refreshAfterAction()
    }
    
    func removeBookFromSelectedCollection(_ book: BookData) {
        if let collection = selectedCollection {
            dataManager.removeBookFromCollection(book, from: collection)
            refreshAfterAction()
        }
    }
}

import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @AppStorage("selectedStatus") var selectedStatus: StatusFilter = .all
    
    private(set) var books: [BookData] = [] {
        didSet {
            objectWillChange.send()
        }
    }
    
    private var wasShowingDashboardBeforeSearch: Bool = true
    
    var searchQuery: String = "" {
        didSet {
            // When search is started, remember the current dashboard state
            if oldValue.isEmpty && !searchQuery.isEmpty {
                wasShowingDashboardBeforeSearch = showDashboard
                if showDashboard {
                    showDashboard = false
                }
            }
            
            // When search is cleared, restore the previous state
            if !oldValue.isEmpty && searchQuery.isEmpty {
                showDashboard = wasShowingDashboardBeforeSearch
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
        
        // Listen for changes to data manager
        dataManager.onDataChanged = { [weak self] in
            self?.refreshData()
        }
    }
    
    func refreshData() {
        if Thread.isMainThread {
            books = dataManager.books
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.books = self?.dataManager.books ?? []
            }
        }
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

extension ContentViewModel {
    // MARK: Search Suggestions
    
    // Get top authors matching a prefix
    func getTopAuthors(matching prefix: String, limit: Int = 5) -> [String] {
        let allAuthors = Set(books.map { $0.author })
        return Array(allAuthors)
            .filter {
                prefix.isEmpty || $0.lowercased().contains(prefix.lowercased())
            }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    // Get top titles matching a prefix
    func getTopTitles(matching prefix: String, limit: Int = 5) -> [String] {
        let allTitles = Set(books.map { $0.title })
        return Array(allTitles)
            .filter {
                prefix.isEmpty || $0.lowercased().contains(prefix.lowercased())
            }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    // Get top tags matching a prefix
    func getTopTags(matching prefix: String, limit: Int = 5) -> [String] {
        let allTags = Set(books.flatMap { $0.tags })
        return Array(allTags)
            .filter {
                prefix.isEmpty || $0.lowercased().contains(prefix.lowercased())
            }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: Recent Searches
    
    // Storage key for UserDefaults
    private static let kRecentSearchesKey = "RecentSearches"
    private static let maxRecentSearches = 10
    
    // Get recent searches
    func getRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: Self.kRecentSearchesKey) ?? []
    }
    
    // Save a search query to recent searches
    func saveRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        
        var recentSearches = getRecentSearches()
        
        // Remove the query if it already exists to avoid duplicates
        recentSearches.removeAll { $0 == query }
        
        // Add the new query at the beginning
        recentSearches.insert(query, at: 0)
        
        // Limit the number of recent searches
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(recentSearches, forKey: Self.kRecentSearchesKey)
    }
    
    // Clear recent searches
    func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: Self.kRecentSearchesKey)
    }
    
    // Submit search to save to recent searches
    func submitSearch() {
        if !searchQuery.isEmpty {
            saveRecentSearch(searchQuery)
        }
    }
}

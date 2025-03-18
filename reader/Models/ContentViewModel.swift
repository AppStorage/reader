import SwiftUI
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @AppStorage("selectedStatus") var selectedStatus: StatusFilter = .all {
        didSet { invalidateDisplayedBooks() }
    }
    
    @Published var selectedBook: BookData?
    @Published var addBookForm = BookForm()
    @Published var searchQuery: String = ""
    @Published var isAddBookLoading = false
    @Published var canFetchBook: Bool = false
    @Published var showDashboard: Bool = true
    @Published var selectedTags: Set<String> = []
    @Published var sortOption: SortOption = .title
    @Published var isAddBookSheetPresented = false
    @Published var sortOrder: SortOrder = .ascending
    @Published var selectedCollection: BookCollection?
    @Published var bookSearchResults: [BookTransferData] = []
    @Published var selectedBookForAdd: BookTransferData? = nil
    
    private var books: [BookData] = []
    private var dataManager: DataManager
    private var cachedDisplayedBooks: [BookData]?
    private var needsDisplayedBooksRefresh = true
    private var cancellables = Set<AnyCancellable>()
    private var wasShowingDashboardBeforeSearch: Bool = true
    
    private static var maxRecentSearches = 10
    private static var kRecentSearchesKey = "RecentSearches"
    
    var displayedBooks: [BookData] {
        if let cachedResult = cachedDisplayedBooks, !needsDisplayedBooksRefresh {
            return cachedResult
        }
        
        let result = computeDisplayedBooks()
        cachedDisplayedBooks = result
        needsDisplayedBooksRefresh = false
        return result
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.books = dataManager.books
        
        setupSubscriptions()
    }
    
    // MARK: - Subscription Setup
    private func setupSubscriptions() {
        dataManager.booksPublisher
            .sink { [weak self] updatedBooks in
                guard let self = self else { return }
                self.books = updatedBooks
                self.invalidateDisplayedBooks()
            }
            .store(in: &cancellables)
        
        setupCollectionsSubscription()
        
        // Handle search query changes
        $searchQuery
            .removeDuplicates()
            .sink { [weak self] newQuery in
                guard let self = self else { return }
                
                // When search is started, remember the dashboard state
                if self.searchQuery.isEmpty && !newQuery.isEmpty {
                    self.wasShowingDashboardBeforeSearch = self.showDashboard
                    if self.showDashboard {
                        self.showDashboard = false
                    }
                }
                
                // When search is cleared, restore the previous state
                if !self.searchQuery.isEmpty && newQuery.isEmpty {
                    self.showDashboard = self.wasShowingDashboardBeforeSearch
                }
                
                self.invalidateDisplayedBooks()
            }
            .store(in: &cancellables)
        
        // Listen for changes in sorting and filtering
        Publishers.CombineLatest3($sortOption, $sortOrder, $selectedTags)
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.invalidateDisplayedBooks()
            }
            .store(in: &cancellables)
        
        $selectedCollection
            .sink { [weak self] _ in
                self?.invalidateDisplayedBooks()
            }
            .store(in: &cancellables)
        
        $addBookForm
            .map { form -> Bool in
                return !form.title.isEmpty && !form.author.isEmpty
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canFetchBook = value
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Add Book Subscription
    private func setupAddBookSubscriptions() {
        $addBookForm
            .map { form -> Bool in
                return !form.title.isEmpty && !form.author.isEmpty
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canFetchBook = value
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Collection Subscription
    private func setupCollectionsSubscription() {
        dataManager.collectionsPublisher
            .sink { [weak self] updatedCollections in
                guard let self = self else { return }
                
                if let currentSelectedCollection = self.selectedCollection {
                    if let updatedCollection = updatedCollections.first(where: { $0.id == currentSelectedCollection.id }) {
                        self.selectedCollection = updatedCollection
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func invalidateDisplayedBooks() {
        needsDisplayedBooksRefresh = true
        objectWillChange.send()
    }
    
    private func computeDisplayedBooks() -> [BookData] {
        if let collection = selectedCollection {
            let collectionBooks = collection.books
            if !searchQuery.isEmpty {
                return collectionBooks.searched(with: searchQuery)
            }
            return collectionBooks.sorted(by: sortOption, order: sortOrder)
        } else {
            let filteredByStatus = books.filtered(by: selectedStatus)
            
            let filteredByTags: [BookData]
            if selectedTags.isEmpty {
                filteredByTags = filteredByStatus
            } else {
                // Pre-process selectedTags once
                let selectedTagsLower = selectedTags.map {
                    $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let selectedTagsSet = Set(selectedTagsLower)
                
                filteredByTags = filteredByStatus.filter { book in
                    let bookTags = Set(book.tags.map {
                        $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    })
                    return !selectedTagsSet.isDisjoint(with: bookTags)
                }
            }
            
            if !searchQuery.isEmpty {
                return filteredByTags.searched(with: searchQuery)
            }
            
            return filteredByTags.sorted(by: sortOption, order: sortOrder)
        }
    }
    
    // MARK: - Add Book Fetching
    func fetchBooks() -> AnyPublisher<Void, Error> {
        guard canFetchBook else {
            return Fail(error: NSError(domain: "ContentViewModel", code: 0,
                                       userInfo: [NSLocalizedDescriptionKey: "Cannot fetch book without title and author"]))
            .eraseToAnyPublisher()
        }
        
        isAddBookLoading = true
        
        return dataManager.fetchBookData(
            title: addBookForm.title,
            author: addBookForm.author,
            isbn: addBookForm.isbn.isEmpty ? nil : addBookForm.isbn
        )
        .handleEvents(
            receiveOutput: { [weak self] results in
                guard let self = self else { return }
                self.bookSearchResults = results
                self.isAddBookSheetPresented = !results.isEmpty
            },
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isAddBookLoading = false
                if case .failure = completion {
                    // Error handling happens in the view
                }
            }
        )
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    func cancelAddBookFetch() {
        isAddBookLoading = false
    }
    
    func addBook(_ bookTransferData: BookTransferData) -> AnyPublisher<String, Never> {
        isAddBookLoading = true
        
        let book = BookData(
            title: bookTransferData.title,
            author: bookTransferData.author,
            published: bookTransferData.published,
            publisher: bookTransferData.publisher,
            genre: bookTransferData.genre,
            series: bookTransferData.series,
            isbn: bookTransferData.isbn,
            bookDescription: bookTransferData.bookDescription
        )
        
        return dataManager.addBook(book: book)
            .map { _ in "Added \"\(bookTransferData.title)\"" }
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.isAddBookLoading = false
                    self?.isAddBookSheetPresented = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    func addManualBook() -> AnyPublisher<String, Never> {
        isAddBookLoading = true
        
        let book = BookData(
            title: addBookForm.title,
            author: addBookForm.author,
            published: addBookForm.published,
            publisher: addBookForm.publisher,
            genre: addBookForm.genre,
            series: addBookForm.series,
            isbn: addBookForm.isbn,
            bookDescription: addBookForm.description
        )
        
        return dataManager.addBook(book: book)
            .map { _ in "Added \"\(self.addBookForm.title)\"" }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isAddBookLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func resetAddBookForm() {
        addBookForm = BookForm()
    }
    
    // MARK: - Book Actions
    func recoverBook(_ book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.updateBookStatus(book, to: .unread)
    }
    
    func softDeleteBooks(_ books: [BookData]) -> AnyPublisher<Void, Never> {
        dataManager.softDeleteBooks(books)
    }
    
    func performSoftDelete(books: [BookData], appState: AppState) {
        guard !books.isEmpty else { return }
        
        let overlayManager = appState.overlayManager
        
        let loadingMessage = books.count == 1 ? "Deleting book..." : "Deleting \(books.count) books..."
        overlayManager?.showLoading(message: loadingMessage)
        
        softDeleteBooks(books)
            .sink { [weak appState] _ in
                guard let appState = appState else { return }
                
                overlayManager?.hideOverlay()
                
                let toastMessage = books.count == 1 ? "Book deleted" : "\(books.count) books deleted"
                overlayManager?.showToast(message: toastMessage)
                
                appState.selectedBooks = []
                NSSound.beep()
            }
            .store(in: &cancellables)
    }
    
    func permanentlyDeleteBooks(_ booksToDelete: [BookData]) -> AnyPublisher<Void, Never> {
        dataManager.permanentlyDeleteBooks(booksToDelete)
    }
    
    func performPermanentDelete(books: [BookData], appState: AppState) {
        guard !books.isEmpty else { return }
        
        let overlayManager = appState.overlayManager
        
        let loadingMessage = books.count == 1 ?
            "Permanently deleting book..." :
            "Permanently deleting \(books.count) books..."
        overlayManager?.showLoading(message: loadingMessage)
        
        permanentlyDeleteBooks(books)
            .sink { [weak appState] _ in
                guard let appState = appState else { return }
                
                overlayManager?.hideOverlay()
                
                // Show success message
                let toastMessage = books.count == 1 ?
                    "Book permanently deleted" :
                    "\(books.count) books permanently deleted"
                overlayManager?.showLoading(message: toastMessage)
                
                // Clear selection and play sound
                appState.selectedBooks = []
                NSSound.beep()
                
                // Force view refresh
                DispatchQueue.main.async {
                    appState.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    func updateBookStatus(for books: [BookData], to status: ReadingStatus) -> AnyPublisher<Void, Never> {
        dataManager.batchUpdateBookStatus(books, to: status)
    }
    
    // MARK: - Status and Collection Counts
    func bookCount(for status: StatusFilter) -> Int {
        return books.count(for: status)
    }
    
    func bookCount(for collection: BookCollection?) -> Int {
        guard let collection = collection else { return 0 }
        return collection.books.count
    }
    
    // MARK: - Notes Management
    func addNote(_ text: String, pageNumber: String, to book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.addNote(text, pageNumber: pageNumber, to: book)
    }
    
    func removeNote(_ note: String, from book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.removeNote(note, from: book)
    }
    
    func updateNote(originalNote: String, newText: String, newPageNumber: String, in book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.updateNote(originalNote: originalNote, newText: newText, newPageNumber: newPageNumber, in: book)
    }
    
    // MARK: - Quotes Management
    func addQuote(_ text: String, pageNumber: String, attribution: String, to book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.addQuote(text, pageNumber: pageNumber, attribution: attribution, to: book)
    }
    
    func removeQuote(_ quote: String, from book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.removeQuote(quote, from: book)
    }
    
    func updateQuote(originalQuote: String, newText: String, newPageNumber: String, newAttribution: String, in book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.updateQuote(originalQuote: originalQuote, newText: newText, newPageNumber: newPageNumber, newAttribution: newAttribution, in: book)
    }
    
    // MARK: - Tag Management
    func addTag(_ tag: String, to book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.addTag(tag, to: book)
    }
    
    func removeTag(_ tag: String, from book: BookData) -> AnyPublisher<Void, Never> {
        dataManager.removeTag(tag, from: book)
    }
    
    func saveChanges() {
        dataManager.saveChanges()
    }
    
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
    
    // MARK: - Collection Management
    func renameSelectedCollection(to newName: String) -> AnyPublisher<Void, Never> {
        guard let collection = selectedCollection else {
            return Empty().eraseToAnyPublisher()
        }
        
        return dataManager.renameCollection(collection, to: newName)
    }
    
    func removeCollection(_ collection: BookCollection) -> AnyPublisher<Void, Never> {
        dataManager.removeCollection(collection)
    }
    
    func removeBookFromSelectedCollection(_ book: BookData) -> AnyPublisher<Void, Never> {
        guard let collection = selectedCollection else {
            return Empty().eraseToAnyPublisher()
        }
        
        return dataManager.removeBookFromCollection(book, from: collection)
    }
    
    // MARK: - Search Suggestions
    func getTopTitles(matching prefix: String, limit: Int = 5) -> [String] {
        let lowercasePrefix = prefix.lowercased()
        return Array(Set(books.map { $0.title }))
            .filter { lowercasePrefix.isEmpty || $0.lowercased().contains(lowercasePrefix) }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    func getTopAuthors(matching prefix: String, limit: Int = 5) -> [String] {
        let lowercasePrefix = prefix.lowercased()
        return Array(Set(books.map { $0.author }))
            .filter { lowercasePrefix.isEmpty || $0.lowercased().contains(lowercasePrefix) }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    func getTopTags(matching prefix: String, limit: Int = 5) -> [String] {
        let lowercasePrefix = prefix.lowercased()
        return Array(Set(books.flatMap { $0.tags }))
            .filter { lowercasePrefix.isEmpty || $0.lowercased().contains(lowercasePrefix) }
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Recent Searches
    func getRecentSearches() -> [String] {
        UserDefaults.standard.stringArray(forKey: Self.kRecentSearchesKey) ?? []
    }
    
    func saveRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        
        var recentSearches = getRecentSearches()
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }
        
        UserDefaults.standard.set(recentSearches, forKey: Self.kRecentSearchesKey)
    }
    
    func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: Self.kRecentSearchesKey)
    }
    
    func submitSearch() {
        if !searchQuery.isEmpty {
            saveRecentSearch(searchQuery)
        }
    }
}

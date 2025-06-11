import Foundation
import SwiftData
import Combine

@MainActor
final class DataManager: ObservableObject {
    private let apiService: BooksAPIService
    private let modelContainer: ModelContainer
    private let booksSubject = CurrentValueSubject<[BookData], Never>([])
    private let collectionsSubject = CurrentValueSubject<[BookCollection], Never>([])
    
    private var cancellables = Set<AnyCancellable>()
    
    var booksPublisher: AnyPublisher<[BookData], Never> {
        booksSubject.eraseToAnyPublisher()
    }
    
    var collectionsPublisher: AnyPublisher<[BookCollection], Never> {
        collectionsSubject.eraseToAnyPublisher()
    }
    
    var books: [BookData] {
        get { booksSubject.value }
        set { booksSubject.send(newValue) }
    }
    
    var collections: [BookCollection] {
        get { collectionsSubject.value }
        set { collectionsSubject.send(newValue) }
    }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.apiService = BooksAPIService()
        
        setupSubscriptions()
        fetchBooks()
        fetchCollections()
    }
    
    private func setupSubscriptions() {
        // Forward book updates to objectWillChange
        booksSubject
            .dropFirst() // Skip initial empty value
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Forward collection updates to objectWillChange
        collectionsSubject
            .dropFirst() // Skip initial empty value
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Operations
    func fetchBooks() {
        do {
            let fetchedBooks = try modelContainer.mainContext.fetch(
                FetchDescriptor<BookData>())
            books = fetchedBooks
        } catch {
            books = []
        }
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil) -> AnyPublisher<[BookTransferData], Error> {
        Future<[BookTransferData], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0,
                                         userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            Task {
                let results = await self.apiService.fetchBookData(title: title, author: author, isbn: isbn)
                promise(.success(results))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchCollections() {
        do {
            let fetchedCollections = try modelContainer.mainContext.fetch(
                FetchDescriptor<BookCollection>())
            collections = fetchedCollections
        } catch {
            collections = []
        }
    }
    
    // MARK: - Book Actions
    func addBook(book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.modelContainer.mainContext.insert(book)
                self.saveChanges(reloadBooks: true)
            })
            .eraseToAnyPublisher()
    }
    
    func softDeleteBooks(_ books: [BookData]) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                for book in books {
                    book.status = .deleted
                    book.dateStarted = nil
                    book.dateFinished = nil
                    book.deletionDate = Date()
                    
                    // Remove from all collections
                    for collection in self.collections {
                        collection.books.removeAll { $0.id == book.id }
                    }
                }
                self.saveChanges(reloadBooks: true, reloadCollections: true)
            })
            .eraseToAnyPublisher()
    }
    
    func purgeExpiredDeletedBooks(using intervalInDays: Int) {
        // If intervalInDays is 0, user has chosen "Never"
        guard intervalInDays > 0 else { return }
        let expirationInterval = TimeInterval(intervalInDays) * 24 * 60 * 60
        let now = Date()
        
        let expiredBooks = books.filter { book in
            book.status == .deleted &&
            book.deletionDate != nil &&
            now.timeIntervalSince(book.deletionDate!) >= expirationInterval
        }
        
        if !expiredBooks.isEmpty {
            permanentlyDeleteBooks(expiredBooks)
                .sink(receiveValue: { })
                .store(in: &cancellables)
        }
    }
    
    func permanentlyDeleteBooks(_ books: [BookData]) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                for book in books {
                    self.modelContainer.mainContext.delete(book)
                }
                self.saveChanges(reloadBooks: true)
            })
            .eraseToAnyPublisher()
    }
    
    // Batch status updates
    func batchUpdateBookStatus(_ books: [BookData], to status: ReadingStatus) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                for book in books {
                    self.updateBookStatusInternal(book, to: status)
                }
                self.saveChanges(reloadBooks: true)
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Edit Book Details
    func updateBookDetails(
        book: BookData,
        title: String,
        author: String,
        genre: String?,
        series: String?,
        isbn: String?,
        publisher: String?,
        publishedDate: Date?,
        description: String?
    ) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0,
                                         userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            do {
                book.title = title
                book.author = author
                book.genre = genre
                book.series = series
                book.isbn = isbn
                book.publisher = publisher
                book.published = publishedDate
                book.bookDescription = description
                
                try self.modelContainer.mainContext.save()
                
                self.objectWillChange.send()
                
                promise(.success(()))
            } catch {
                print("Failed to update book details: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Rating System
    func updateBookRating(_ book: BookData, to rating: Int) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                // Clamp the rating between 0 and 5
                book.rating = max(0, min(rating, 5))
                self.saveChanges(reloadBooks: true)
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Notes Management
    func addNote(_ text: String, pageNumber: String, quoteReference: String = "", to book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let formattedNote = RowItems.formatForStorage(
                    text: text,
                    pageNumber: pageNumber,
                    quoteReference: quoteReference
                )
                var updatedNotes = book.notes
                updatedNotes.append(formattedNote)
                book.notes = updatedNotes
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func removeNote(_ note: String, from book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                var updatedNotes = book.notes
                updatedNotes.removeAll { $0 == note }
                book.notes = updatedNotes
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func updateNote(originalNote: String, newText: String, newPageNumber: String, newQuoteReference: String = "", in book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let formattedNote = RowItems.formatForStorage(
                    text: newText,
                    pageNumber: newPageNumber,
                    quoteReference: newQuoteReference
                )
                var updatedNotes = book.notes
                if let index = updatedNotes.firstIndex(of: originalNote) {
                    updatedNotes[index] = formattedNote
                    book.notes = updatedNotes
                    self.saveChanges()
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Quotes Management
    func addQuote(_ text: String, pageNumber: String, attribution: String, to book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let formattedQuote = RowItems.formatForStorage(text: text, pageNumber: pageNumber, attribution: attribution)
                var updatedQuotes = book.quotes
                updatedQuotes.append(formattedQuote)
                book.quotes = updatedQuotes
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func removeQuote(_ quote: String, from book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                var updatedQuotes = book.quotes
                updatedQuotes.removeAll { $0 == quote }
                book.quotes = updatedQuotes
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func updateQuote(originalQuote: String, newText: String, newPageNumber: String, newAttribution: String, in book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let formattedQuote = RowItems.formatForStorage(text: newText, pageNumber: newPageNumber, attribution: newAttribution)
                var updatedQuotes = book.quotes
                if let index = updatedQuotes.firstIndex(of: originalQuote) {
                    updatedQuotes[index] = formattedQuote
                    book.quotes = updatedQuotes
                    self.saveChanges()
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Tag Management
    func addTag(_ tag: String, to book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                var updatedTags = book.tags
                // Check if tag already exists (case-insensitive)
                if !updatedTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                    updatedTags.append(tag) // Store with original case
                    book.tags = updatedTags
                    self.saveChanges()
                }
            })
            .eraseToAnyPublisher()
    }
    
    func removeTag(_ tag: String, from book: BookData) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                var updatedTags = book.tags
                updatedTags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
                book.tags = updatedTags
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func addTagToMultipleBooks(_ tag: String, books: [BookData]) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let tagLower = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                for book in books {
                    // Pre-compute lowercase tags for each book once
                    let bookTagsLower = book.tags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    if !bookTagsLower.contains(tagLower) {
                        var updatedTags = book.tags
                        updatedTags.append(tag)
                        book.tags = updatedTags
                    }
                }
                
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    func removeTagFromMultipleBooks(_ tag: String, books: [BookData]) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                for book in books {
                    var updatedTags = book.tags
                    updatedTags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
                    book.tags = updatedTags
                }
                
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Date Management
    func validateDates(for book: BookData) {
        let now = Date()

        if let startDate = book.dateStarted, startDate > now {
            book.dateStarted = now
        }

        if let finishDate = book.dateFinished, finishDate > now {
            book.dateFinished = now
        }

        if let startDate = book.dateStarted,
           let finishDate = book.dateFinished,
           finishDate < startDate {
            book.dateFinished = startDate
        }

        if book.status == .reading {
            book.dateFinished = nil
        }
    }
    
    // Status update method used by both single and batch operations
    private func updateBookStatusInternal(_ book: BookData, to status: ReadingStatus) {
        let oldStatus = book.status
        book.status = status

        // Only modify dates if status changed
        if oldStatus != status {
            switch status {
            case .reading:
                // Set dateStarted only if not already set
                if book.dateStarted == nil {
                    book.dateStarted = Date()
                }
                // Always clear dateFinished when switching to reading
                book.dateFinished = nil

            case .read:
                // Set missing dates only
                if book.dateStarted == nil {
                    book.dateStarted = Date()
                }
                if book.dateFinished == nil {
                    book.dateFinished = Date()
                }

            case .unread, .deleted:
                // Clear both dates
                book.dateStarted = nil
                book.dateFinished = nil

                // If book is being deleted, remove from all collections
                if status == .deleted {
                    removeBookFromAllCollections(book)
                }
            }
        }

        validateDates(for: book)
    }
    
    // Public method for updating a single book's status
    func updateBookStatus(_ book: BookData, to status: ReadingStatus) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.updateBookStatusInternal(book, to: status)
                self.saveChanges()
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Collection Actions
    func addCollection(named name: String) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                let newCollection = BookCollection(name: name)
                self.modelContainer.mainContext.insert(newCollection)
                self.saveChanges(reloadCollections: true)
            })
            .eraseToAnyPublisher()
    }
    
    func removeCollection(_ collection: BookCollection) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.modelContainer.mainContext.delete(collection)
                self.saveChanges(reloadCollections: true)
            })
            .eraseToAnyPublisher()
    }
    
    // When book status is deleted, it will also remove it from the collection
    private func removeBookFromAllCollections(_ book: BookData) {
        for collection in collections {
            collection.books.removeAll { $0.id == book.id }
        }
        
        DispatchQueue.main.async {
            self.saveChanges(reloadCollections: true)
        }
    }
    
    func addBookToCollection(_ books: [BookData], to collection: BookCollection) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                // Check for books already in the collection
                let existingBookIDs = Set(collection.books.map { $0.id })
                
                // Only add books that aren't already in the collection
                let booksToAdd = books.filter { !existingBookIDs.contains($0.id) }
                
                if !booksToAdd.isEmpty {
                    // Process each book before adding to collection
                    for book in booksToAdd {
                        // If book is deleted, change its status to unread before adding to collection
                        if book.status == .deleted {
                            book.status = .unread
                            
                            // Clear dates as per the existing behavior for unread status
                            book.dateStarted = nil
                            book.dateFinished = nil
                        }
                    }
                    
                    // Add the books to the collection
                    collection.books.append(contentsOf: booksToAdd)
                    
                    // Save changes and reload both books and collections
                    // Reload books since it might have changed book status
                    self.saveChanges(reloadBooks: true, reloadCollections: true)
                }
            })
            .eraseToAnyPublisher()
    }
    
    func removeBookFromCollection(_ book: BookData, from collection: BookCollection) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                collection.books.removeAll { $0.id == book.id }
                self.saveChanges(reloadCollections: true)
            })
            .eraseToAnyPublisher()
    }
    
    func renameCollection(_ collection: BookCollection, to newName: String) -> AnyPublisher<Void, Never> {
        Just(())
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                if let index = self.collections.firstIndex(where: { $0.id == collection.id }) {
                    self.collections[index].name = newName
                    self.saveChanges(reloadCollections: true)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - State Changes
    func saveChanges(reloadBooks: Bool = false, reloadCollections: Bool = false) {
        do {
            try modelContainer.mainContext.save()
            
            // Only reload data that has changed
            if reloadBooks {
                fetchBooks()
            }
            
            if reloadCollections {
                fetchCollections()
            }
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    // MARK: - Import Books
    func importBooks(from url: URL) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    promise(.failure(NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file permissions."])))
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let jsonData = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                guard let rawArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                    throw NSError(domain: "ImportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }

                let importedData: [BookTransferData] = rawArray.compactMap { dict in
                    guard let entryData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
                    return try? decoder.decode(BookTransferData.self, from: entryData)
                }

                
                // Batch insert books
                for book in importedData {
                    let newBook = DataConversion.toBookData(from: book)
                    self.modelContainer.mainContext.insert(newBook)
                }
                
                self.saveChanges(reloadBooks: true)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func importBooksFromCSV(from url: URL) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    promise(.failure(NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file permissions."])))
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let csvString = try String(contentsOf: url, encoding: .utf8)
                let importedData = DataConversion.fromCSV(csvString: csvString)
                
                // Batch processing
                for book in importedData {
                    let newBook = DataConversion.toBookData(from: book)
                    self.modelContainer.mainContext.insert(newBook)
                }
                
                self.saveChanges(reloadBooks: true)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Export Books
    func exportBooks(to url: URL) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            do {
                let books = self.books.filter { $0.status != .deleted }.map {
                    DataConversion.toTransferData(from: $0)
                }
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let jsonData = try encoder.encode(books)
                try jsonData.write(to: url)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func exportBooksToCSV(to url: URL) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DataManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "DataManager was deallocated"])))
                return
            }
            
            do {
                let books = self.books.filter { $0.status != .deleted }.map {
                    DataConversion.toTransferData(from: $0)
                }
                
                let csvString = DataConversion.toCSV(books: books)
                try csvString.write(to: url, atomically: true, encoding: .utf8)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}

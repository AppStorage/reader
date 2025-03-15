import Foundation
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    private var _books: [BookData] = []
    var books: [BookData] {
        get { _books }
        set {
            if _books != newValue {
                _books = newValue
                objectWillChange.send()
            }
        }
    }
    
    private var _collections: [BookCollection] = []
    var collections: [BookCollection] {
        get { _collections }
        set {
            if _collections != newValue {
                _collections = newValue
                objectWillChange.send()
            }
        }
    }
    
    var onDataChanged: (() -> Void)?
    
    private let modelContainer: ModelContainer
    private let apiService: BooksAPIService
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.apiService = BooksAPIService()
        fetchBooks()
        fetchCollections()
    }
    
    // MARK: Fetch
    func fetchBooks() {
        do {
            books = try modelContainer.mainContext.fetch(
                FetchDescriptor<BookData>())
        } catch {
            books = []
        }
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil) async
    -> [BookTransferData]
    {
        return await apiService.fetchBookData(
            title: title, author: author, isbn: isbn)
    }
    
    func fetchCollections() {
        do {
            let results = try modelContainer.mainContext.fetch(
                FetchDescriptor<BookCollection>())
            collections = results
        } catch {
            collections = []
        }
    }
    
    // MARK: Book Actions
    func addBook(book: BookData) {
        modelContainer.mainContext.insert(book)
        saveChanges()
        objectWillChange.send()
    }
    
    func softDeleteBooks(_ books: [BookData]) {
        for book in books {
            book.status = .deleted
        }
        saveChanges()
        objectWillChange.send()
    }
    
    func permanentlyDeleteBooks(_ books: [BookData]) {
        for book in books {
            modelContainer.mainContext.delete(book)
        }
        saveChanges()
    }
    
    // MARK: Collection Actions
    func addCollection(named name: String) {
        let newCollection = BookCollection(name: name)
        modelContainer.mainContext.insert(newCollection)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.saveChanges()
        }
        saveChanges()
    }
    
    func removeCollection(_ collection: BookCollection) {
        modelContainer.mainContext.delete(collection)
        saveChanges()
    }
    
    func addBookToCollection(_ books: [BookData], to collection: BookCollection) {
        // Check for books already in the collection
        let existingBookIDs = Set(collection.books.map { $0.id })
        
        // Only add books that aren't already in the collection
        let booksToAdd = books.filter { !existingBookIDs.contains($0.id) }
        
        if !booksToAdd.isEmpty {
            collection.books.append(contentsOf: booksToAdd)
            saveChanges()
        }
    }
    
    func removeBookFromCollection(_ book: BookData, from collection: BookCollection) {
        collection.books.removeAll { $0.id == book.id }
        saveChanges()
    }
    
    
    func renameCollection(_ collection: BookCollection, to newName: String) {
        if let index = collections.firstIndex(where: { $0.id == collection.id })
        {
            collections[index].name = newName
            saveChanges()
        }
    }
    
    // MARK: State Changes
    func updateBookStatus(_ book: BookData, to status: ReadingStatus) {
        book.status = status
        
        switch status {
        case .reading:
            if book.dateStarted == nil { book.dateStarted = Date() }
            book.dateFinished = nil  // Clear the finish date when marked as reading
        case .read:
            if book.dateStarted == nil { book.dateStarted = Date() }
            if book.dateFinished == nil { book.dateFinished = Date() }
        case .unread, .deleted:
            book.dateStarted = nil
            book.dateFinished = nil
        }
        
        // Additional validation if needed
        book.validateDates()
        
        saveChanges()
    }
    
    func saveChanges() {
        do {
            try modelContainer.mainContext.save()
            fetchBooks()
            fetchCollections()
            
            DispatchQueue.main.async { [weak self] in
                self?.onDataChanged?()
            }
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    // MARK: Import/Export
    func importBooks(
        from url: URL, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                completion(
                    .failure(
                        NSError(
                            domain: "ImportError", code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Failed to access file permissions."
                            ])))
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedData = try decoder.decode(
                [BookTransferData].self, from: jsonData)
            
            for book in importedData {
                let newBook = DataConversion.toBookData(from: book)
                addBook(book: newBook)
            }
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func exportBooks(
        to url: URL, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let books = self.books.filter { $0.status != .deleted }.map {
            DataConversion.toTransferData(from: $0)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(books)
            try jsonData.write(to: url)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func importBooksFromCSV(
        from url: URL, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                completion(
                    .failure(
                        NSError(
                            domain: "ImportError", code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Failed to access file permissions."
                            ])))
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let csvString = try String(contentsOf: url, encoding: .utf8)
            let importedData = DataConversion.fromCSV(csvString: csvString)
            
            for book in importedData {
                let newBook = DataConversion.toBookData(from: book)
                addBook(book: newBook)
            }
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func exportBooksToCSV(
        to url: URL, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let books = self.books.filter { $0.status != .deleted }.map {
            DataConversion.toTransferData(from: $0)
        }
        
        do {
            let csvString = DataConversion.toCSV(books: books)
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

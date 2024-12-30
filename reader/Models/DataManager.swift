import Foundation
import Combine
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    @Published var books: [BookData] = []
    @Published var collections: [BookCollection] = []
    
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
            books = try modelContainer.mainContext.fetch(FetchDescriptor<BookData>())
        } catch {
            books = []
        }
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil) async -> [BookTransferData] {
        return await apiService.fetchBookData(title: title, author: author, isbn: isbn)
    }
    
    func fetchCollections() {
        do {
            let results = try modelContainer.mainContext.fetch(FetchDescriptor<BookCollection>())
            collections = results
        } catch {
            collections = []
        }
    }
    
    // MARK: Book Actions
    func addBook(book: BookData) {
        modelContainer.mainContext.insert(book)
        saveChanges()
    }
    
    func softDeleteBooks(_ books: [BookData]) {
        for book in books {
            book.status = .deleted
        }
        saveChanges()
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
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].books.forEach { book in
                removeBookFromCollection(book, from: collection)
            }
        }
        modelContainer.mainContext.delete(collection)
        saveChanges()
    }
    
    func addBookToCollection(_ books: [BookData], to collection: BookCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].books.append(contentsOf: books)
            saveChanges()
        }
    }
    
    func removeBookFromCollection(_ book: BookData, from collection: BookCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].books.removeAll { $0.id == book.id }
            saveChanges()
        }
    }
    
    func renameCollection(_ collection: BookCollection, to newName: String) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
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
            book.dateFinished = nil
        case .read:
            if book.dateStarted == nil { book.dateStarted = Date() }
            book.dateFinished = Date()
        case .unread, .deleted:
            book.dateStarted = nil
            book.dateFinished = nil
        }
        saveChanges()
    }
    
    func saveChanges() {
        do {
            try modelContainer.mainContext.save()
            fetchBooks()
            fetchCollections()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

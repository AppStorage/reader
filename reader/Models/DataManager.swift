import Foundation
import Combine
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    @Published var books: [BookData] = []
    
    private let modelContainer: ModelContainer
    private let apiService: BooksAPIService
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.apiService = BooksAPIService()
        fetchBooks()
    }
    
    func fetchBooks() {
        do {
            books = try modelContainer.mainContext.fetch(FetchDescriptor<BookData>())
        } catch {
            books = []
        }
    }
    
    func addBook(book: BookData) {
        modelContainer.mainContext.insert(book)
        saveChanges()
    }
    
    func permanentlyDeleteBook(_ book: BookData) {
        modelContainer.mainContext.delete(book)
        saveChanges()
    }
    
    func updateBookStatus(_ book: BookData, to status: ReadingStatus) {
        book.status = status
        saveChanges()
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil) async -> [BookTransferData] {
        return await apiService.fetchBookData(title: title, author: author, isbn: isbn)
    }
    
    private func saveChanges() {
        do {
            try modelContainer.mainContext.save()
            fetchBooks()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

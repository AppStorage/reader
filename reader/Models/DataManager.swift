import Foundation
import Combine
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    @Published var books: [BookData] = []
    private let modelContainer: ModelContainer
    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String else {
            fatalError("API key not found in Info.plist")
        }
        return key
    }()

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        fetchBooks()
    }

    func fetchBooks() {
        do {
            books = try modelContainer.mainContext.fetch(FetchDescriptor<BookData>())
        } catch {
            books = []
        }
    }

    func fetchBookData(
        title: String,
        author: String,
        publishedDate: String? = nil,
        inputISBN: String? = nil,
        publisher: String? = nil
    ) async -> BookData? {
        let queryParameters: [String: String] = [
            "intitle": title,
            "inauthor": author,
            "inpublishedDate": publishedDate ?? "",
            "isbn": inputISBN ?? ""
        ]

        guard let url = constructQueryURL(apiKey: apiKey, queryParameters: queryParameters) else {
            print("Failed to construct query URL.")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("API Response: \(jsonResponse)")
            }

            let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            guard let items = result.items, !items.isEmpty else {
                print("No matching books found in the API response.")
                return nil
            }

            guard let matchedBook = items.first(where: {
                matchBook(
                    bookInfo: $0.volumeInfo,
                    title: title,
                    author: author,
                    publishedDate: publishedDate,
                    inputISBN: inputISBN,
                    publisher: publisher
                )
            }) else {
                print("No books matched all input parameters.")
                return nil
            }

            return constructBookData(from: matchedBook.volumeInfo)
        } catch {
            print("Failed to fetch or decode data: \(error)")
            return nil
        }
    }

    private func constructBookData(from bookInfo: VolumeInfo) -> BookData {
        return BookData(
            title: bookInfo.fullTitle,
            author: bookInfo.authors?.joined(separator: ", ") ?? "",
            published: bookInfo.parsedPublishedDate ?? Date(),
            publisher: bookInfo.publisher,
            genre: bookInfo.primaryCategory,
            series: bookInfo.series,
            isbn: bookInfo.primaryISBN,
            bookDescription: bookInfo.sanitizedDescription,
            status: .unread
        )
    }

    func sanitizeExistingDescriptions() {
        books.forEach { book in
            if let description = book.bookDescription {
                book.bookDescription = sanitizeDescription(description)
            }
        }
        saveChanges()
    }

    func addBook(
        title: String,
        author: String,
        genre: String? = nil,
        series: String? = nil,
        isbn: String? = nil,
        publisher: String? = nil,
        published: Date? = nil,
        description: String? = nil
    ) {
        let sanitizedDescription = sanitizeDescription(description)
        let newBook = BookData(
            title: title,
            author: author,
            published: published,
            publisher: publisher,
            genre: genre,
            series: series,
            isbn: isbn,
            bookDescription: sanitizedDescription,
            status: .unread
        )
        modelContainer.mainContext.insert(newBook)
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

    private func saveChanges() {
        do {
            try modelContainer.mainContext.save()
            fetchBooks()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

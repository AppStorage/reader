import Foundation
import SwiftData

actor BooksAPIService {
    private let apiKey: String
    
    init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String else {
            fatalError("API key not found in Info.plist")
        }
        self.apiKey = apiKey
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil) async -> BookDTO? {
        if let bookData = await fetchFromGoogleBooks(title: title, author: author, isbn: isbn) {
            return BookDTO(
                id: UUID(),
                title: bookData.title,
                author: bookData.author,
                published: bookData.published,
                publisher: bookData.publisher,
                genre: bookData.genre,
                series: bookData.series,
                isbn: bookData.isbn,
                bookDescription: bookData.bookDescription,
                status: bookData.status,
                quotes: bookData.quotes,
                notes: bookData.notes,
                tags: bookData.tags,
                dateStarted: bookData.dateStarted,
                dateFinished: bookData.dateFinished
            )
        }
        return nil
    }
    
    // MARK: Google Books API
    private func fetchFromGoogleBooks(
        title: String,
        author: String,
        isbn: String?,
        retries: Int = 3
    ) async -> BookData? {
        let parameters: [String: String] = [
            "intitle": title,
            "inauthor": author,
            "isbn": isbn ?? ""
        ]
        
        guard let url = URLBuilder.constructGoogleBooksURL(apiKey: apiKey, parameters: parameters) else {
            print("Invalid Google Books URL.")
            return nil
        }
        
        return await retryFetch(url: url, retries: retries) { data in
            try GoogleBooksParser.parseResponse(data, isbn: isbn)
        }
    }
    
    // MARK: Open Library API
    private func fetchFromOpenLibrary(
        title: String,
        author: String,
        isbn: String?
    ) async -> BookData? {
        guard let url = URLBuilder.constructOpenLibraryURL(title: title, author: author, isbn: isbn) else {
            print("Invalid Open Library URL.")
            return nil
        }
        
        return await retryFetch(url: url, retries: 1) { data in
            try OpenLibraryParser.parseResponse(data, isbn: isbn)
        }
    }
    
    private func retryFetch<T>(
        url: URL,
        retries: Int,
        parse: (Data) throws -> T?
    ) async -> T? {
        for attempt in 1...retries {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let result = try parse(data) {
                    return result
                }
            } catch {
                print("Attempt \(attempt) failed: \(error)")
                try? await Task.sleep(nanoseconds: UInt64(500_000_000 * attempt)) // Exponential backoff
            }
        }
        print("Request failed after \(retries) retries.")
        return nil
    }
}

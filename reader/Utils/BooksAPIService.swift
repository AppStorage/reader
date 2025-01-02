import Foundation
import SwiftData

actor BooksAPIService {
    static let shared = BooksAPIService()
    private let apiKey: String

    init() {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String, !apiKey.isEmpty {
            self.apiKey = apiKey
        } else {
            print("Warning: API key not found in Info.plist or is empty. Network requests may fail.")
            self.apiKey = ""
        }
    }

    func fetchBookData(title: String, author: String, isbn: String? = nil) async -> [BookTransferData] {
        // Fetch data in parallel
        async let googleBooks = fetchFromGoogleBooks(title: title, author: author, isbn: isbn)
        async let openLibrary = fetchFromOpenLibrary(title: title, author: author, isbn: isbn)

        let results = await [googleBooks, openLibrary].compactMap { $0 }.flatMap { $0 }

        // Deduplicate by a combination of ISBN and title-author pair
        let uniqueBooks = removeDuplicates(books: results)

        return uniqueBooks
    }

    // MARK: Google Books API
    private func fetchFromGoogleBooks(
        title: String,
        author: String,
        isbn: String?,
        retries: Int = 3
    ) async -> [BookTransferData]? {
        var query = "intitle:\(title)+inauthor:\(author)"

        if let isbn = isbn {
            query += "+isbn:\(isbn)"
        }

        let parameters: [String: String] = ["q": query, "maxResults": "10"]

        guard let url = URLBuilder.constructGoogleBooksURL(apiKey: apiKey, parameters: parameters) else {
            print("Invalid Google Books URL.")
            return nil
        }

        return await retryFetch(url: url, retries: retries) { data in
            try GoogleBooksParser.parseMultipleResponses(data)
        }
    }

    // MARK: Open Library API
    private func fetchFromOpenLibrary(
        title: String,
        author: String,
        isbn: String? = nil,
        retries: Int = 3
    ) async -> [BookTransferData]? {
        guard let url = URLBuilder.constructOpenLibraryURL(
            title: title,
            author: author,
            isbn: isbn
        ) else {
            print("Invalid Open Library URL.")
            return nil
        }

        return await retryFetch(url: url, retries: retries) { data in
            try await OpenLibraryParser.parseMultipleResponses(data, isbn: isbn)
        }
    }

    func fetchDescription(olid: String, retries: Int = 3) async -> String? {
        let urlString = "https://openlibrary.org\(olid).json"
        guard let url = URL(string: urlString) else { return nil }

        return await retryFetch(url: url, retries: retries) { data in
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let description = json?["description"] as? String {
                return description
            } else if let descriptionObject = json?["description"] as? [String: Any],
                      let value = descriptionObject["value"] as? String {
                return value
            }
            return nil
        }
    }

    private func retryFetch<T: Sendable>(
        url: URL,
        retries: Int,
        parse: (Data) async throws -> T?
    ) async -> T? {
        for attempt in 1...retries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }

                if let result = try await parse(data) {
                    return result
                }
            } catch {
                if attempt == retries {
                    print("Request failed after \(retries) retries: \(error)")
                }
                try? await Task.sleep(nanoseconds: UInt64(500_000_000 * attempt))
            }
        }
        return nil
    }

    private func removeDuplicates(books: [BookTransferData]) -> [BookTransferData] {
        var seenIdentifiers = Set<String>()
        var uniqueBooks = [BookTransferData]()

        for book in books {
            let identifier = [book.isbn, book.title.lowercased(), book.author.lowercased()].compactMap { $0 }.joined(separator: "-")
            if !seenIdentifiers.contains(identifier) {
                seenIdentifiers.insert(identifier)
                uniqueBooks.append(book)
            }
        }
        return uniqueBooks
    }

    private func convertToTransferData(book: BookData) -> BookTransferData {
        return BookTransferData(
            title: book.title,
            author: book.author,
            published: book.published,
            publisher: book.publisher,
            genre: book.genre,
            series: book.series,
            isbn: book.isbn,
            bookDescription: book.bookDescription,
            quotes: book.quotes,
            notes: book.notes,
            tags: book.tags,
            status: book.status
        )
    }
}

import Foundation
import SwiftData
import Fuse

actor BooksAPIService {
    static let shared = BooksAPIService()
    private let apiKey: String
    
    init() {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String, !apiKey.isEmpty {
            self.apiKey = apiKey
        } else {
            self.apiKey = ""
        }
    }
    
    // MARK: Fetch Books
    func fetchBookData(title: String, author: String, isbn: String? = nil, limit: Int = 10) async -> [BookTransferData] {
        let tasks: [Task<[BookTransferData]?, Never>] = [
            Task {
                if !apiKey.isEmpty {
                    return await fetchFromGoogleBooks(title: title, author: author, isbn: isbn, limit: limit)
                }
                return nil
            },
            Task {
                return await fetchFromOpenLibrary(title: title, author: author, isbn: isbn, limit: limit)
            }
        ]
        
        var results: [BookTransferData] = []
        for task in tasks {
            if Task.isCancelled { break }
            if let result = await task.value {
                results.append(contentsOf: result)
            }
        }
        
        let uniqueBooks = removeDuplicates(books: results)
        
        // Fuzzy search filtering
        let fuse = Fuse()
        let filteredBooks = await Task.detached {
            uniqueBooks.filter { book in
                let titleScore = fuse.search(title, in: book.title)?.score ?? 1.0
                let authorScore = fuse.search(author, in: book.author)?.score ?? 1.0
                return (titleScore < 0.3 || authorScore < 0.3)
            }
        }.value
        
        return Array(filteredBooks.prefix(limit))
    }
    
    // MARK: Google Books
    private func fetchFromGoogleBooks(
        title: String,
        author: String,
        isbn: String?,
        retries: Int = 3,
        limit: Int
    ) async -> [BookTransferData]? {
        guard !apiKey.isEmpty else {
            return nil
        }
        
        let query = [
            "intitle": title,
            "inauthor": author
        ].filter { !$0.value.isEmpty }
        
        let parameters = query.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey):\(encodedValue)"
        }.joined(separator: "+")
        
        let parametersDict = [
            "q": parameters,
            "maxResults": "\(limit)",
            "projection": "full"
        ]
        
        guard let url = URLBuilder.constructGoogleBooksURL(apiKey: apiKey, parameters: parametersDict) else {
            return nil
        }
        
        return await retryFetch(url: url, retries: retries) { data in
            guard !data.isEmpty else { throw URLError(.zeroByteResource) }
            return try GoogleBooksParser.parseMultipleResponses(data)
        }
    }
    
    // MARK: Open Library
    private func fetchFromOpenLibrary(
        title: String,
        author: String,
        isbn: String? = nil,
        retries: Int = 3,
        limit: Int
    ) async -> [BookTransferData]? {
        guard let url = URLBuilder.constructOpenLibraryURL(
            title: title,
            author: author,
            isbn: isbn
        ) else {
            return nil
        }
        
        return await retryFetch(url: url, retries: retries) { data in
            guard !data.isEmpty else { throw URLError(.zeroByteResource) }
            let results = try await OpenLibraryParser.parseMultipleResponses(data, isbn: isbn)
            return Array(results.prefix(limit))
        }
    }
    
    // MARK: Fetch Description
    func fetchDescription(olid: String, retries: Int = 3) async -> String? {
        let urlString = "https://openlibrary.org\(olid).json"
        guard let url = URL(string: urlString) else { return nil }
        
        return await retryFetch(url: url, retries: retries) { data in
            guard !data.isEmpty else { throw URLError(.zeroByteResource) }
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
    
    // MARK: Retry Fetch
    private func retryFetch<T: Sendable>(
        url: URL,
        retries: Int,
        parse: (Data) async throws -> T?
    ) async -> T? {
        for attempt in 1...retries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Check HTTP status codes and handle issues
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 429:
                        try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * attempt))
                        continue
                    default:
                        throw URLError(.badServerResponse)
                    }
                }
                
                // Parse the data
                guard !data.isEmpty else { throw URLError(.zeroByteResource) }
                if let result = try await parse(data) {
                    return result
                }
            } catch {
                if attempt == retries { return nil }
                try? await Task.sleep(nanoseconds: UInt64(500_000_000 * attempt))
            }
        }
        return nil
    }
    
    // MARK: Remove Duplicates
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
}

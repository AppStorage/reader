import Foundation
import SwiftData
import Fuse

actor BooksAPIService {
    static let shared = BooksAPIService()
    private let googleBooksProvider: GoogleBooksProvider
    private let openLibraryProvider: OpenLibraryProvider
    
    init() {
        let apiKey: String
        if let bundleApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String, !bundleApiKey.isEmpty {
            apiKey = bundleApiKey
        } else {
            apiKey = ""
        }
        
        self.googleBooksProvider = GoogleBooksProvider(apiKey: apiKey)
        self.openLibraryProvider = OpenLibraryProvider()
    }
    
    func fetchBookData(title: String, author: String, isbn: String? = nil, limit: Int = 10) async -> [BookTransferData] {
        // Validate required fields
        let hasISBN = isbn != nil && !(isbn?.isEmpty ?? true)
        let hasTitle = !title.isEmpty
        let hasAuthor = !author.isEmpty
        
        // If no search criteria provided, return empty result
        if !hasISBN && !hasTitle && !hasAuthor {
            return []
        }
        
        var results: [BookTransferData] = []
        
        // Execute both provider searches in parallel using task groups
        await withTaskGroup(of: [BookTransferData]?.self) { group in
            // Add Google Books search task
            group.addTask {
                let result = await self.googleBooksProvider.fetchBooks(
                    title: title, author: author, isbn: isbn, limit: limit)
                switch result {
                case .success(let books):
                    return books
                case .failure:
                    return []
                }
            }
            
            // Add Open Library search task
            group.addTask {
                let result = await self.openLibraryProvider.fetchBooks(
                    title: title, author: author, isbn: isbn, limit: limit)
                switch result {
                case .success(let books):
                    return books
                case .failure:
                    return []
                }
            }
            
            // Collect results
            for await providerBooks in group {
                if let books = providerBooks {
                    results.append(contentsOf: books)
                }
            }
        }
        
        // Process results by merging and removing duplicates
        let uniqueBooks = mergeAndDeduplicate(books: results)
        
        // Apply fuzzy matching if we have search terms
        if hasTitle || hasAuthor {
            return await filterBooksByRelevance(books: uniqueBooks, title: title, author: author, limit: limit)
        }
        
        return Array(uniqueBooks.prefix(limit))
    }
    
    private func mergeAndDeduplicate(books: [BookTransferData]) -> [BookTransferData] {
        // Group books by a normalized identifier
        var booksByIdentifier = [String: [BookTransferData]]()
        
        for book in books {
            let normalizedTitle = book.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedAuthor = book.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create a composite key for grouping similar books
            var identifiers = [String]()
            
            // ISBN is most reliable if available
            if let isbn = book.isbn, !isbn.isEmpty {
                identifiers.append(isbn)
            }
            
            // Use title+author as fallback
            if !normalizedTitle.isEmpty && !normalizedAuthor.isEmpty {
                identifiers.append("\(normalizedTitle)|\(normalizedAuthor)")
            } else if !normalizedTitle.isEmpty {
                identifiers.append(normalizedTitle)
            }
            
            // Skip books with no usable identifier
            guard !identifiers.isEmpty else { continue }
            
            // Use the most specific identifier available
            let identifier = identifiers.first!
            
            // Add to the appropriate group
            if booksByIdentifier[identifier] == nil {
                booksByIdentifier[identifier] = []
            }
            booksByIdentifier[identifier]!.append(book)
        }
        
        // Merge books from each group
        return booksByIdentifier.values.map { similarBooks -> BookTransferData in
            // If only one book in the group, return it directly
            guard similarBooks.count > 1 else {
                return similarBooks.first!
            }
            
            // Find the "best" book by looking at completeness of data
            return similarBooks.reduce(similarBooks[0]) { best, current in
                let bestScore = scoreBookCompleteness(best)
                let currentScore = scoreBookCompleteness(current)
                return currentScore > bestScore ? current : best
            }
        }
    }
    
    // Scores a book's data completeness to help choose between duplicates
    private func scoreBookCompleteness(_ book: BookTransferData) -> Int {
        var score = 0
        
        // Award points for each field that has data
        if !book.title.isEmpty { score += 1 }
        if !book.author.isEmpty { score += 1 }
        if book.published != nil { score += 1 }
        if let publisher = book.publisher, !publisher.isEmpty { score += 1 }
        if let genre = book.genre, !genre.isEmpty { score += 1 }
        if let series = book.series, !series.isEmpty { score += 1 }
        if let isbn = book.isbn, !isbn.isEmpty { score += 1 }
        if let description = book.bookDescription, !description.isEmpty {
            // Description is weighted higher as it's important content
            score += 2
            // Longer descriptions generally indicate more complete data
            score += min(3, description.count / 100)
        }
        
        return score
    }
    
    private func filterBooksByRelevance(books: [BookTransferData], title: String, author: String, limit: Int) async -> [BookTransferData] {
        return await Task.detached {
            let fuse = Fuse()
            
            // Filter books based on relevance to search terms
            let scoredBooks = books.map { book -> (book: BookTransferData, score: Double) in
                let titleScore = title.isEmpty ? 0.0 : fuse.search(title, in: book.title)?.score ?? 1.0
                let authorScore = author.isEmpty ? 0.0 : fuse.search(author, in: book.author)?.score ?? 1.0
                
                // Calculate combined score, weighting title and author equally
                let combinedScore = (title.isEmpty && author.isEmpty) ? 0.0 :
                (title.isEmpty ? authorScore : (author.isEmpty ? titleScore : (titleScore + authorScore) / 2))
                
                return (book, combinedScore)
            }
            
            // Sort by relevance score (lower is better)
            let sortedBooks = scoredBooks.sorted { $0.score < $1.score }
            
            // Keep only books with reasonable match score (threshold of 0.4)
            let filteredBooks = sortedBooks.filter { $0.score < 0.4 || (title.isEmpty && author.isEmpty) }
            
            // Take the most relevant books up to the limit
            return filteredBooks.prefix(limit).map { $0.book }
        }.value
    }
    
    private func removeDuplicates(books: [BookTransferData]) -> [BookTransferData] {
        var seenIdentifiers = Set<String>()
        var uniqueBooks = [BookTransferData]()
        
        for book in books {
            // Create a unique identifier for each book
            let identifier = [
                book.isbn,
                book.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                book.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ].compactMap { $0 }.joined(separator: "-")
            
            if !seenIdentifiers.contains(identifier) {
                seenIdentifiers.insert(identifier)
                uniqueBooks.append(book)
            }
        }
        
        return uniqueBooks
    }
}

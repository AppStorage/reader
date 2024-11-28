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
        // Build query parameters for Google Books
        var queryParameters: [String: String] = [
            "intitle": title,
            "inauthor": author
        ]
        
        if let inputISBN = inputISBN?.trimmingCharacters(in: .whitespacesAndNewlines), !inputISBN.isEmpty {
            queryParameters["isbn"] = inputISBN
        }
        if let publisher = publisher?.trimmingCharacters(in: .whitespacesAndNewlines), !publisher.isEmpty {
            queryParameters["publisher"] = publisher
        }
        
        // Try Google Books API first
        if let url = constructQueryURL(apiKey: apiKey, queryParameters: queryParameters) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                if let items = result.items, !items.isEmpty {
                    // Find the most relevant match
                    let exactMatches = items.filter {
                        matchBook(
                            bookInfo: $0.volumeInfo,
                            title: title,
                            author: author,
                            publishedDate: publishedDate,
                            inputISBN: inputISBN,
                            publisher: publisher
                        )
                    }
                    
                    // Return the best match or the first result
                    if let bestMatch = exactMatches.first ?? items.first {
                        return constructBookData(from: bestMatch.volumeInfo, userInputISBN: inputISBN)
                    }
                }
            } catch {
                print("Failed to fetch or parse Google Books data: \(error)")
            }
        }
        
        // Fallback to Open Library if Google Books fails
        return await fetchBookFromOpenLibrary(title: title, author: author, inputISBN: inputISBN)
    }
    
    func fetchBookFromOpenLibrary(
        title: String? = nil,
        author: String? = nil,
        inputISBN: String? = nil
    ) async -> BookData? {
        // Construct the query for Open Library
        var query = ""
        if let isbn = inputISBN {
            query = "bibkeys=ISBN:\(isbn)"
        } else if let title = title, let author = author {
            query = "q=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        } else {
            print("Open Library requires at least a title or an ISBN.")
            return nil
        }
        
        let urlString = inputISBN != nil
        ? "https://openlibrary.org/api/books?\(query)&format=json&jscmd=data"
        : "https://openlibrary.org/search.json?\(query)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid Open Library URL.")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if inputISBN != nil {
                // Parse the response for ISBN queries
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                   let bookData = jsonResponse["ISBN:\(inputISBN!)"] as? [String: Any] {
                    return parseOpenLibraryBookData(bookData, isbn: inputISBN)
                }
            } else {
                // Parse the response for title/author queries
                let result = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
                if let doc = result.docs.first {
                    return parseOpenLibrarySearchResult(doc)
                }
            }
        } catch {
            print("Failed to fetch or parse Open Library data: \(error)")
        }
        return nil
    }
    
    private func constructBookData(from bookInfo: VolumeInfo, userInputISBN: String?) -> BookData {
        let selectedISBN = bookInfo.industryIdentifiers?.first(where: { $0.identifier == userInputISBN })?.identifier
        ?? bookInfo.primaryISBN(userInputISBN: userInputISBN)
        
        return BookData(
            title: bookInfo.fullTitle,
            author: bookInfo.authors?.joined(separator: ", ") ?? "",
            published: bookInfo.parsedPublishedDate,
            publisher: bookInfo.publisher,
            genre: bookInfo.primaryCategory,
            series: bookInfo.series,
            isbn: selectedISBN,
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

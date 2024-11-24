import Foundation
import Combine
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    @Published var books: [BookData] = []
    let modelContainer: ModelContainer
    private let apiKey = "GOOGLE_BOOKS_API_KEY"
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        fetchBooks()  // Initial fetch to populate the books list
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
        var query = "intitle:\(title) inauthor:\(author)"
        if let publishedDate = publishedDate, !publishedDate.isEmpty {
            query += " inpublishedDate:\(publishedDate)"
        }
        if let inputISBN = inputISBN, !inputISBN.isEmpty {
            query += " isbn:\(inputISBN)"
        }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&key=\(apiKey)") else {
            print("Failed to construct query URL.")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Log the raw JSON response for debugging
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("API Response: \(jsonResponse)")
            }
            
            let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            // Check if `items` exists and is not empty
            guard let items = result.items, !items.isEmpty else {
                print("No matching books found in the API response.")
                return nil
            }

            // Validate against all input parameters
            let matchedBook = items.first(where: { book in
                let bookInfo = book.volumeInfo
                
                let titleMatches = bookInfo.title.localizedCaseInsensitiveContains(title)
                
                let authorMatches = bookInfo.authors?.contains(where: { $0.localizedCaseInsensitiveContains(author) }) ?? false
                
                let publishedDateMatches = publishedDate == nil || bookInfo.publishedDate == publishedDate
                
                let isbnMatches = inputISBN == nil || (bookInfo.industryIdentifiers?.contains(where: { $0.identifier == inputISBN }) ?? false)
                
                let publisherMatches = publisher == nil || (bookInfo.publisher?.localizedCaseInsensitiveContains(publisher!) ?? false)
                
                return titleMatches && authorMatches && publishedDateMatches && isbnMatches && publisherMatches
            })

            // If no match, return nil
            guard let validBook = matchedBook else {
                print("No books matched all input parameters.")
                return nil
            }

            return constructBookData(from: validBook.volumeInfo)
        } catch {
            print("Failed to fetch or decode data: \(error)")
            return nil
        }
    }

    private func constructBookData(from bookInfo: VolumeInfo) -> BookData {
        let isbn = bookInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier
        let series = bookInfo.subtitle ?? bookInfo.series
        let sanitizedDescription = sanitizeDescription(bookInfo.description)
        let formattedPublishedDate = DateFormatter()
        formattedPublishedDate.dateFormat = "yyyy-MM-dd"
        let publishedDateParsed = formattedPublishedDate.date(from: bookInfo.publishedDate) ?? Date()

        return BookData(
            title: bookInfo.title,
            author: bookInfo.authors?.joined(separator: ", ") ?? "",
            published: publishedDateParsed,
            publisher: bookInfo.publisher,
            genre: bookInfo.categories?.first,
            series: series,
            isbn: isbn,
            bookDescription: sanitizedDescription,
            status: .unread
        )
    }
    
    // Sanitize the description for line breaks and HTML
    private func sanitizeDescription(_ description: String?) -> String? {
        guard let description = description else { return nil }
        return description
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
    }
    
    func sanitizeExistingDescriptions() {
        for book in books where book.bookDescription != nil {
            book.bookDescription = sanitizeDescription(book.bookDescription)
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
        saveChanges() // Save and refresh the list
    }
    
    func permanentlyDeleteBook(_ book: BookData) {
        modelContainer.mainContext.delete(book)  // Remove book from the context
        saveChanges()  // Persist changes and refresh the books list
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

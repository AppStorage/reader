import Foundation

struct OpenLibraryParser {
    static func parseMultipleResponses(_ data: Data, isbn: String?) async throws -> [BookTransferData] {
        let result = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        
        guard !result.docs.isEmpty else {
            print("No results found in Open Library response.")
            return []
        }
        
        // Process documents asynchronously
        var books = [BookTransferData]()
        for doc in result.docs {
            let book = await constructBookTransferData(from: doc, isbn: isbn) // Updated function call
            books.append(book)
        }
        return books
    }
    
    static func constructBookTransferData(from doc: OpenLibraryDoc, isbn: String?) async -> BookTransferData {
        let description: String? = if let olid = doc.key {
            await BooksAPIService.shared.fetchDescription(olid: olid)
        } else {
            nil
        }
        
        return BookTransferData(
            title: doc.title,
            author: doc.author_name?.joined(separator: ", ") ?? "Unknown Author",
            published: doc.first_publish_year != nil
            ? Calendar.current.date(from: DateComponents(year: doc.first_publish_year!))
            : nil,
            publisher: doc.publisher?.first,
            genre: doc.subject?.joined(separator: ", "),
            series: nil,
            isbn: doc.isbn?.first ?? isbn,
            bookDescription: description,
            quotes: [],
            notes: [],
            tags: [],
            status: .unread
        )
    }
}

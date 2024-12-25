import Foundation

struct OpenLibraryParser {
    // Parses Open Library API response into BookData
    static func parseResponse(_ data: Data, isbn: String?) throws -> BookData? {
        let result = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        
        // Ensure we have at least one result
        guard let doc = result.docs.first else {
            return nil
        }
        
        // Construct and return the BookData object
        return constructBookData(from: doc, isbn: isbn)
    }
    
    // Constructs BookData from Open Library API response
    private static func constructBookData(from doc: OpenLibraryDoc, isbn: String?) -> BookData {
        return BookData(
            title: doc.title,
            author: doc.author_name?.joined(separator: ", ") ?? "Unknown Author",
            published: doc.first_publish_year != nil
            ? DateFormatter().date(from: "\(doc.first_publish_year!)")
            : nil,
            publisher: doc.publisher?.first,
            genre: doc.subject?.joined(separator: ", "),
            series: nil,
            isbn: doc.isbn?.first ?? isbn,
            bookDescription: nil,
            status: .unread
        )
    }
}

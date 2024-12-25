import Foundation

struct GoogleBooksParser {
    // Parses Google Books API response into BookData
    static func parseResponse(_ data: Data, isbn: String?) throws -> BookData? {
        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        // Ensure we have at least one item
        guard let bookInfo = result.items?.first?.volumeInfo else {
            return nil
        }
        
        // Construct and return the BookData object
        return constructBookData(from: bookInfo, isbn: isbn)
    }
    
    // Constructs BookData from Google Books API response
    private static func constructBookData(from bookInfo: VolumeInfo, isbn: String?) -> BookData {
        let selectedISBN = bookInfo.industryIdentifiers?.first(where: { $0.identifier == isbn })?.identifier
        ?? bookInfo.primaryISBN(userInputISBN: isbn)
        
        return BookData(
            title: bookInfo.fullTitle,
            author: bookInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            published: bookInfo.parsedPublishedDate,
            publisher: bookInfo.publisher,
            genre: bookInfo.primaryCategory,
            series: bookInfo.series,
            isbn: selectedISBN,
            bookDescription: bookInfo.sanitizedDescription,
            status: .unread
        )
    }
}

import Foundation

struct GoogleBooksParser {
    static func parseMultipleResponses(_ data: Data) throws -> [BookTransferData] {
        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return result.items?.compactMap { item in
            constructBookTransferData(from: item.volumeInfo, isbn: nil)
        } ?? []
    }
    
    private static func constructBookTransferData(from bookInfo: VolumeInfo, isbn: String?) -> BookTransferData {
        return BookTransferData(
            title: bookInfo.fullTitle,
            author: bookInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            published: bookInfo.parsedPublishedDate,
            publisher: bookInfo.publisher,
            genre: bookInfo.primaryCategory,
            series: bookInfo.series,
            isbn: bookInfo.industryIdentifiers?.first?.identifier,
            bookDescription: bookInfo.sanitizedDescription,
            quotes: [],
            notes: [],
            tags: [],
            status: .unread
        )
    }
}

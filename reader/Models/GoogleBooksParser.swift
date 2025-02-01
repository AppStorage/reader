import Foundation

struct GoogleBooksParser {
    static func parseMultipleResponses(_ data: Data) throws -> [BookTransferData] {
        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        return result.items?.compactMap { item in
            constructBookTransferData(from: item.volumeInfo)
        } ?? []
    }
    
    private static func constructBookTransferData(from bookInfo: VolumeInfo) -> BookTransferData {
        let isbn = bookInfo.industryIdentifiers?.first { $0.type == "ISBN_13" || $0.type == "ISBN_10" }?.identifier
        return BookTransferData(
            title: bookInfo.title,
            author: bookInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            published: parseDate(bookInfo.publishedDate),
            publisher: bookInfo.publisher ?? "Unknown Publisher",
            genre: bookInfo.categories?.first ?? "Unknown Genre",
            series: nil, // Google Books doesn't provide series info
            isbn: isbn,
            bookDescription: bookInfo.description ?? "",
            status: "unread",
            dateStarted: nil,
            dateFinished: nil,
            quotes: [],
            notes: [],
            tags: []
        )
    }
}

import Foundation

struct DataConversion {
    
    static func toTransferData(from book: BookData) -> BookTransferData {
        return BookTransferData(
            id: book.id,
            title: book.title,
            author: book.author,
            published: book.published,
            publisher: book.publisher,
            genre: book.genre,
            series: book.series,
            isbn: book.isbn,
            bookDescription: book.bookDescription,
            status: book.status.rawValue,
            dateStarted: book.dateStarted,
            dateFinished: book.dateFinished,
            quotes: book.quotes,
            notes: book.notes,
            tags: book.tags
        )
    }
    
    static func toBookData(from transferData: BookTransferData) -> BookData {
        return BookData(
            title: transferData.title,
            author: transferData.author,
            published: transferData.published,
            publisher: transferData.publisher,
            genre: transferData.genre,
            series: transferData.series,
            isbn: transferData.isbn,
            bookDescription: transferData.bookDescription,
            status: ReadingStatus(rawValue: transferData.status) ?? .unread,
            dateStarted: transferData.dateStarted,
            dateFinished: transferData.dateFinished,
            quotes: transferData.quotes,
            notes: transferData.notes,
            tags: transferData.tags
        )
    }
    
    static func encodeToJSON(_ transferData: BookTransferData) -> Data? {
        return try? JSONEncoder().encode(transferData)
    }
    
    static func decodeFromJSON(_ jsonData: Data) -> BookTransferData? {
        return try? JSONDecoder().decode(BookTransferData.self, from: jsonData)
    }
}

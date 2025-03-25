import Foundation
import SwiftCSV

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
            tags: book.tags,
            rating: book.rating
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
            rating: transferData.rating ?? 0,
            status: ReadingStatus(rawValue: transferData.status) ?? .unread,
            dateStarted: transferData.dateStarted,
            dateFinished: transferData.dateFinished,
            quotes: transferData.quotes,
            notes: transferData.notes,
            tags: transferData.tags
        )
    }

    // MARK: - JSON
    static func encodeToJSON(_ transferData: BookTransferData) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(transferData)
    }

    static func decodeFromJSON(_ jsonData: Data) -> BookTransferData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BookTransferData.self, from: jsonData)
    }

    // MARK: - CSV
    static let csvHeaders = [
        "title", "author", "published", "publisher", "genre", "series",
        "isbn", "description", "status", "dateStarted", "dateFinished",
        "tags", "quotes", "notes", "rating"
    ]

    static func toCSV(books: [BookTransferData]) -> String {
        var csvString = csvHeaders.joined(separator: ",") + "\n"

        for book in books {
            let row = [
                escapeCsvField(book.title),
                escapeCsvField(book.author),
                book.published != nil ? formatDateForCSV(book.published!) : "",
                escapeCsvField(book.publisher ?? ""),
                escapeCsvField(book.genre ?? ""),
                escapeCsvField(book.series ?? ""),
                escapeCsvField(book.isbn ?? ""),
                escapeCsvField(book.bookDescription ?? ""),
                book.status,
                book.dateStarted != nil ? formatDateForCSV(book.dateStarted!) : "",
                book.dateFinished != nil ? formatDateForCSV(book.dateFinished!) : "",
                escapeCsvField(formatArrayField(book.tags)),
                escapeCsvField(formatArrayField(book.quotes)),
                escapeCsvField(formatArrayField(book.notes)),
                String(book.rating ?? 0)
            ].joined(separator: ",")

            csvString += row + "\n"
        }

        return csvString
    }

    static func fromCSV(csvString: String) -> [BookTransferData] {
        do {
            let csv = try NamedCSV(string: csvString, delimiter: ",")
            var books: [BookTransferData] = []

            for row in csv.rows {
                let title = row["title"] ?? ""
                let author = row["author"] ?? ""
                let published = DateFormatterUtils.parseDate(row["published"])
                let publisher = row["publisher"]
                let genre = row["genre"]
                let series = row["series"]
                let isbn = row["isbn"]
                let description = row["description"]
                let status = row["status"] ?? "unread"
                let dateStarted = DateFormatterUtils.parseDate(row["dateStarted"])
                let dateFinished = DateFormatterUtils.parseDate(row["dateFinished"])

                let tags = parseArrayField(row["tags"] ?? "")
                let quotes = parseArrayField(row["quotes"] ?? "")
                let notes = parseArrayField(row["notes"] ?? "")
                let rating = Int(row["rating"] ?? "") ?? 0

                books.append(BookTransferData(
                    title: title,
                    author: author,
                    published: published,
                    publisher: publisher,
                    genre: genre,
                    series: series,
                    isbn: isbn,
                    bookDescription: description,
                    status: status,
                    dateStarted: dateStarted,
                    dateFinished: dateFinished,
                    quotes: quotes,
                    notes: notes,
                    tags: tags,
                    rating: rating
                ))
            }

            return books
        } catch {
            print("Failed to parse CSV: \(error)")
            return []
        }
    }

    // MARK: - Helpers
    private static func formatDateForCSV(_ date: Date) -> String {
        return DateFormatterUtils.cachedCSVFormatter.string(from: date)
    }

    private static func getStringOrNil(_ str: String) -> String? {
        return str.isEmpty ? nil : str
    }

    private static func parseArrayField(_ field: String) -> [String] {
        return field.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func formatArrayField(_ array: [String]) -> String {
        return array.joined(separator: ";")
    }

    private static func escapeCsvField(_ field: String) -> String {
        var escaped = field

        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }

        return escaped
    }
}

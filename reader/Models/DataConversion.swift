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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(transferData)
    }
    
    static func decodeFromJSON(_ jsonData: Data) -> BookTransferData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BookTransferData.self, from: jsonData)
    }
    
    static let csvHeaders = [
        "title", "author", "published", "publisher", "genre", "series",
        "isbn", "description", "status", "dateStarted", "dateFinished",
        "tags", "quotes", "notes",
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
                book.dateStarted != nil
                ? formatDateForCSV(book.dateStarted!) : "",
                book.dateFinished != nil
                ? formatDateForCSV(book.dateFinished!) : "",
                escapeCsvField(formatArrayField(book.tags)),
                escapeCsvField(formatArrayField(book.quotes)),
                escapeCsvField(formatArrayField(book.notes)),
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString
    }
    
    static func fromCSV(csvString: String) -> [BookTransferData] {
        var books: [BookTransferData] = []
        
        let rows = csvString.components(separatedBy: "\n")
        guard rows.count > 1 else { return [] }
        
        for i in 1..<rows.count {
            let row = rows[i]
            if row.isEmpty { continue }
            
            let fields = parseCSVRow(row)
            if fields.count < csvHeaders.count { continue }
            
            books.append(createBookFromCSVFields(fields))
        }
        
        return books
    }
    
    // MARK: Helpers
    private static func createBookFromCSVFields(_ fields: [String])
    -> BookTransferData
    {
        var fieldIndex = 0
        
        let title = fields[fieldIndex]
        fieldIndex += 1
        let author = fields[fieldIndex]
        fieldIndex += 1
        
        let publishedStr = fields[fieldIndex]
        fieldIndex += 1
        let published = parseDate(publishedStr.isEmpty ? nil : publishedStr)
        
        let publisher = getStringOrNil(fields[fieldIndex])
        fieldIndex += 1
        let genre = getStringOrNil(fields[fieldIndex])
        fieldIndex += 1
        let series = getStringOrNil(fields[fieldIndex])
        fieldIndex += 1
        let isbn = getStringOrNil(fields[fieldIndex])
        fieldIndex += 1
        let description = getStringOrNil(fields[fieldIndex])
        fieldIndex += 1
        
        let statusStr = fields[fieldIndex]
        fieldIndex += 1
        
        let dateStartedStr = fields[fieldIndex]
        fieldIndex += 1
        let dateStarted = parseDate(
            dateStartedStr.isEmpty ? nil : dateStartedStr)
        
        let dateFinishedStr = fields[fieldIndex]
        fieldIndex += 1
        let dateFinished = parseDate(
            dateFinishedStr.isEmpty ? nil : dateFinishedStr)
        
        let tagsStr = fields[fieldIndex]
        fieldIndex += 1
        let tags = tagsStr.isEmpty ? [] : parseArrayField(tagsStr)
        
        let quotesStr = fields[fieldIndex]
        fieldIndex += 1
        let quotes = quotesStr.isEmpty ? [] : parseArrayField(quotesStr)
        
        let notesStr = fields[fieldIndex]
        let notes = notesStr.isEmpty ? [] : parseArrayField(notesStr)
        
        return BookTransferData(
            title: title,
            author: author,
            published: published,
            publisher: publisher,
            genre: genre,
            series: series,
            isbn: isbn,
            bookDescription: description,
            status: statusStr,
            dateStarted: dateStarted,
            dateFinished: dateFinished,
            quotes: quotes,
            notes: notes,
            tags: tags
        )
    }
    
    private static func formatDateForCSV(_ date: Date) -> String {
        var dateString: String = ""
        DateFormatterUtils.formatterQueue.sync {
            let formatter = DateFormatterUtils.sharedFormatter
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        }
        return dateString
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
        
        if escaped.contains(",") || escaped.contains("\"")
            || escaped.contains("\n")
        {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        
        return escaped
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        var i = 0
        let characters = Array(row)
        
        while i < characters.count {
            let char = characters[i]
            
            if char == "\"" {
                if inQuotes && i + 1 < characters.count
                    && characters[i + 1] == "\""
                {
                    currentField.append("\"")
                    i += 2
                    continue
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i += 1
        }
        
        fields.append(currentField)
        
        return fields
    }
}

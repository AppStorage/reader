import SwiftData
import Foundation

@Model
class BookData: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    
    var title: String
    var author: String
    var published: Date?
    var publisher: String?
    var genre: String?
    var series: String?
    var isbn: String?
    var dateStarted: Date?
    var dateFinished: Date?
    var bookDescription: String?
    
    @Attribute private var statusRawValue: String
    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .unread }
        set { statusRawValue = newValue.rawValue }
    }
    
    @Attribute private var tagsData: Data?
    var tags: [String] {
        get {
            decodeTags() ?? []
        }
        set {
            tagsData = encodeTags(newValue)
        }
    }
    
    @Attribute private var quotesData: Data?
    @Attribute private var notesData: Data?
    
    var quotes: [String] {
        get { decodeTextArray(from: quotesData) ?? [] }
        set { quotesData = encodeTextArray(newValue) }
    }
    
    var notes: [String] {
        get { decodeTextArray(from: notesData) ?? [] }
        set { notesData = encodeTextArray(newValue) }
    }
    
    init(
        title: String,
        author: String,
        published: Date? = nil,
        publisher: String? = nil,
        genre: String? = nil,
        series: String? = nil,
        isbn: String? = nil,
        bookDescription: String? = nil,
        status: ReadingStatus = .unread,
        quotes: [String] = [],
        notes: [String] = [],
        tags: [String] = []
    ) {
        self.title = title
        self.author = author
        self.published = published
        self.publisher = publisher
        self.genre = genre
        self.series = series
        self.isbn = isbn
        self.bookDescription = bookDescription
        self.statusRawValue = status.rawValue
        self.quotes = quotes
        self.notes = notes
        self.tags = tags
    }
    
    func updateDates(for newStatus: ReadingStatus) {
        switch newStatus {
        case .reading:
            if dateStarted == nil { dateStarted = Date() }
            dateFinished = nil
        case .read:
            if dateStarted == nil { dateStarted = Date() }
            dateFinished = Date()
        case .unread, .deleted:
            dateStarted = nil
            dateFinished = nil
        }
    }
    
    // Encodes tags into JSON
    private func encodeTags(_ tags: [String]) -> Data? {
        try? JSONEncoder().encode(tags)
    }
    
    // Decodes tags from JSON
    private func decodeTags() -> [String]? {
        guard let data = tagsData else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    // Encodes text arrays into JSON
    private func encodeTextArray(_ texts: [String]) -> Data? {
        try? JSONEncoder().encode(texts)
    }
    
    // Decodes text arrays from JSON
    private func decodeTextArray(from data: Data?) -> [String]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    // Formats dates consistently
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Checks if the book has any notes or quotes
    var hasNotesOrQuotes: Bool {
        !notes.isEmpty || !quotes.isEmpty
    }
    
    func addTag(_ tag: String) {
        var updatedTags = tags
        if !updatedTags.contains(tag) {
            updatedTags.append(tag)
        }
        tags = updatedTags
    }
}

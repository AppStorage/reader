import Foundation
import SwiftData

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
            guard let data = tagsData else { return [] }
            let decodedTags = (try? JSONDecoder().decode([String].self, from: data)) ?? []
            return decodedTags
        }
        set {
            let encodedData = try? JSONEncoder().encode(newValue)
            tagsData = encodedData
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
        dateStarted: Date? = nil,
        dateFinished: Date? = nil,
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
        self.dateStarted = dateStarted
        self.dateFinished = dateFinished
        self.quotes = quotes
        self.notes = notes
        self.tags = tags
    }
    
    func updateDates(for newStatus: ReadingStatus) {
        switch newStatus {
        case .reading:
            if dateStarted == nil { dateStarted = Date() }
            if let startDate = dateStarted, let finishDate = dateFinished, finishDate < startDate {
                dateFinished = nil
            }
        case .read:
            if dateStarted == nil { dateStarted = Date() }
            if dateFinished == nil { dateFinished = Date() }
            if let startDate = dateStarted, let finishDate = dateFinished, finishDate < startDate {
                dateFinished = startDate
            }
        case .unread, .deleted:
            dateStarted = nil
            dateFinished = nil
        }
        validateDates()
    }
    
    func validateDates() {
        if let startDate = dateStarted, let finishDate = dateFinished, finishDate < startDate {
            dateFinished = startDate
        }
    }
    
    private func encodeTags(_ tags: [String]) -> Data? {
        try? JSONEncoder().encode(tags)
    }
    
    private func decodeTags() -> [String]? {
        guard let data = tagsData else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    private func encodeTextArray(_ texts: [String]) -> Data? {
        try? JSONEncoder().encode(texts)
    }
    
    private func decodeTextArray(from data: Data?) -> [String]? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
        
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

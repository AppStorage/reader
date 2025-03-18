import Foundation
import SwiftData

@Model
class BookData: Identifiable {
    @Relationship(inverse: \BookCollection.books) var collections: [BookCollection] = []
    
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute private var statusRawValue: String
    @Attribute private var tagsData: Data?
    @Attribute private var quotesData: Data?
    @Attribute private var notesData: Data?
    
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
    
    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .unread }
        set { statusRawValue = newValue.rawValue }
    }
    
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            let decodedTags = (try? JSONDecoder().decode([String].self, from: data)) ?? []
            return decodedTags
        }
        set {
            // Normalize tags by eliminating case duplicates
            let normalizedTags = normalizeTags(newValue)
            let encodedData = try? JSONEncoder().encode(normalizedTags)
            tagsData = encodedData
        }
    }
    
    var quotes: [String] {
        get { decodeTextArray(from: quotesData) ?? [] }
        set { quotesData = encodeTextArray(newValue) }
    }
    
    var notes: [String] {
        get { decodeTextArray(from: notesData) ?? [] }
        set { notesData = encodeTextArray(newValue) }
    }
    
    var hasNotesOrQuotes: Bool {
        !notes.isEmpty || !quotes.isEmpty
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
        self.tags = normalizeTags(tags)
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
    
    // Normalize tags array by removing case duplicates
    private static func normalizeTags(_ inputTags: [String]) -> [String] {
        var normalizedTags: [String] = []
        var seenTagsLowercase: Set<String> = []
        
        for tag in inputTags {
            let lowercaseTag = tag.lowercased()
            if !seenTagsLowercase.contains(lowercaseTag) {
                normalizedTags.append(tag) // Keep original case
                seenTagsLowercase.insert(lowercaseTag)
            }
        }
        
        return normalizedTags
    }
    
    // Instance method wrapper for the static function
    private func normalizeTags(_ inputTags: [String]) -> [String] {
        return BookData.normalizeTags(inputTags)
    }
}

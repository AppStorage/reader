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
    var quotes: String
    var notes: String = ""
    var bookDescription: String?
    
    @Attribute private var statusRawValue: String
    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .unread }
        set { statusRawValue = newValue.rawValue }
    }
    
    @Attribute private var tagsData: Data?

    // Computed property for working with tags as [String]
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
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
        quotes: String = "",
        notes: String = "",
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
}

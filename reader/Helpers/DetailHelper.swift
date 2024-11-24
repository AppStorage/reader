import SwiftUI
import SwiftData

struct DetailHelper {
    struct BookDetails {
        var title: String
        var author: String
        var genre: String
        var series: String
        var isbn: String
        var publisher: String
        var status: ReadingStatus
        var month: String
        var day: String
        var year: String
    }
    
    // Load current book details
    static func loadCurrentValues(for book: BookData) -> BookDetails {
        var details = BookDetails(
            title: book.title,
            author: book.author,
            genre: book.genre ?? "",
            series: book.series ?? "",
            isbn: book.isbn ?? "",
            publisher: book.publisher ?? "",
            status: book.status,
            month: "",
            day: "",
            year: ""
        )

        if let publishedDate = book.published {
            let components = Calendar.current.dateComponents([.month, .day, .year], from: publishedDate)
            details.month = String(format: "%02d", components.month ?? 0)
            details.day = String(format: "%02d", components.day ?? 0)
            details.year = components.year.map { String($0) } ?? ""
        }

        return details
    }
    
    // Date formatting
    static func formattedMonth(from book: BookData) -> String {
        guard let published = book.published else { return "" }
        if let month = Calendar.current.dateComponents([.month], from: published).month {
            return String(format: "%02d", month)
        }
        return ""
    }

    static func formattedDay(from book: BookData) -> String {
        guard let published = book.published else { return "" }
        if let day = Calendar.current.dateComponents([.day], from: published).day {
            return String(format: "%02d", day)
        }
        return ""
    }

    static func formattedYear(from book: BookData) -> String {
        guard let published = book.published else { return "" }
        if let year = Calendar.current.dateComponents([.year], from: published).year {
            return String(year)
        }
        return ""
    }
}

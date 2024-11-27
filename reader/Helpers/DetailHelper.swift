import SwiftUI
import SwiftData

struct DetailHelper {
    
    // MARK: - Date formatting
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
    
    // MARK: - Status Color
    static func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .unread: return .gray
        case .reading: return .blue
        case .read: return .green
        case .deleted: return .red
        }
    }
}

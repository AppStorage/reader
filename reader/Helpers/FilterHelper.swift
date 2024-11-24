import SwiftUI

struct FilterHelper {
    static func applyStatusFilter(to books: [BookData], status: StatusFilter) -> [BookData] {
        books.filter { book in
            switch status {
            case .all:
                // Include all books except those with a `deleted` status
                return book.status != .deleted
            case .unread:
                return book.status == .unread
            case .reading:
                return book.status == .reading
            case .read:
                return book.status == .read
            case .deleted:
                return book.status == .deleted
            }
        }
    }
    
    static func applySearchFilter(to books: [BookData], query: String) -> [BookData] {
        // Return all books if the search query is empty
        guard !query.isEmpty else { return books }
        
        // Filter books by title or author using localized case-insensitive search
        return books.filter { book in
            book.title.localizedCaseInsensitiveContains(query) ||
            book.author.localizedCaseInsensitiveContains(query)
        }
    }
    
    static func applySorting(to books: [BookData], option: SortOption, order: SortOrder) -> [BookData] {
        // Sort books based on the selected sort option and order
        books.sorted { book1, book2 in
            switch option {
            case .title:
                // Compare titles using localized comparison
                let titleComparison = book1.title.localizedCompare(book2.title)
                return order == .ascending ? titleComparison == .orderedAscending : titleComparison == .orderedDescending
            case .author:
                // Compare authors using localized comparison
                let authorComparison = book1.author.localizedCompare(book2.author)
                return order == .ascending ? authorComparison == .orderedAscending : authorComparison == .orderedDescending
            case .published:
                // Use distant past as a fallback for missing publication dates
                let date1 = book1.published ?? Date.distantPast
                let date2 = book2.published ?? Date.distantPast
                return order == .ascending ? date1 < date2 : date1 > date2
            }
        }
    }
    
    static func countBooks(for status: StatusFilter, in books: [BookData]) -> Int {
        return applyStatusFilter(to: books, status: status).count
    }
}

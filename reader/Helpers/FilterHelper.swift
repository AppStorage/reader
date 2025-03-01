import Foundation
import Fuse

extension Array where Element == BookData {
    
    // Filter books by status
    func filtered(by status: StatusFilter) -> [BookData] {
        self.filter { book in
            switch status {
            case .all:
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
    
    // Filter books by search query
    func searched(with query: String) -> [BookData] {
        guard !query.isEmpty else { return self }
        
        let fuse = Fuse()
        
        return self.filter { book in
            let titleResult = fuse.search(query, in: book.title)
            let authorResult = fuse.search(query, in: book.author)
            
            return titleResult != nil || authorResult != nil
        }
    }
    
    // Sort books based on selected option and order
    func sorted(by option: SortOption, order: SortOrder) -> [BookData] {
        self.sorted { book1, book2 in
            switch option {
            case .title:
                let comparison = book1.title.localizedCompare(book2.title)
                return order == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            case .author:
                let comparison = book1.author.localizedCompare(book2.author)
                return order == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            case .published:
                let date1 = book1.published ?? Date.distantPast
                let date2 = book2.published ?? Date.distantPast
                return order == .ascending ? date1 < date2 : date1 > date2
            }
        }
    }
    
    // Count books based on status
    func count(for status: StatusFilter) -> Int {
        self.filtered(by: status).count
    }
    
    // Filter by tags
    func filtered(byTags tags: Set<String>) -> [BookData] {
        guard !tags.isEmpty else { return self }
        return self.filter { book in
            !tags.isDisjoint(with: book.tags)
        }
    }
}

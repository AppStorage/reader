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
        
        let queryLowercase = query.lowercased()
        let queryTerms = queryLowercase.split(separator: " ").map(String.init)
        let fuse = Fuse()
        
        // Calculate a score for each book
        var bookScores: [(book: BookData, score: Int)] = []
        
        for book in self {
            var score = 0
            let titleLower = book.title.lowercased()
            let authorLower = book.author.lowercased()
            
            if titleLower == queryLowercase {
                score += 100000
            }
            
            else if titleLower.hasPrefix(queryLowercase) {
                score += 50000
            }
            
            else {
                var allTermsFound = true
                var lastPos = 0
                
                for term in queryTerms {
                    if let range = titleLower.range(of: term, range: titleLower.index(titleLower.startIndex, offsetBy: lastPos)..<titleLower.endIndex) {
                        lastPos = titleLower.distance(from: titleLower.startIndex, to: range.upperBound)
                    } else {
                        allTermsFound = false
                        break
                    }
                }
                
                if allTermsFound {
                    score += 10000
                }
            }
            
            if authorLower == queryLowercase {
                score += 9000
            }
            
            for term in queryTerms {
                if titleLower.contains(term) {
                    score += 1000
                }
            }
            
            if authorLower.contains(queryLowercase) {
                score += 800
            }
            
            for term in queryTerms {
                if authorLower.contains(term) {
                    score += 500
                }
            }
            
            if fuse.search(query, in: book.title) != nil {
                score += 300
            }
            
            if fuse.search(query, in: book.author) != nil {
                score += 200
            }
            
            if let description = book.bookDescription {
                if description.lowercased().contains(queryLowercase) {
                    score += 100
                }
                if fuse.search(query, in: description) != nil {
                    score += 50
                }
            }
            
            if let publisher = book.publisher {
                if publisher.lowercased().contains(queryLowercase) {
                    score += 100
                }
                if fuse.search(query, in: publisher) != nil {
                    score += 50
                }
            }
            
            if let series = book.series {
                if series.lowercased().contains(queryLowercase) {
                    score += 150
                }
                if fuse.search(query, in: series) != nil {
                    score += 75
                }
            }
            
            if let genre = book.genre {
                if genre.lowercased().contains(queryLowercase) {
                    score += 100
                }
                if fuse.search(query, in: genre) != nil {
                    score += 50
                }
            }
            
            if let isbn = book.isbn {
                if isbn.contains(query) {
                    score += 300
                }
                
                if fuse.search(query, in: isbn) != nil {
                    score += 150
                }
                
                let strippedQuery = query.replacingOccurrences(of: "-", with: "")
                let strippedISBN = isbn.replacingOccurrences(of: "-", with: "")
                if strippedISBN.contains(strippedQuery) {
                    score += 250
                }
            }
            
            for tag in book.tags {
                if tag.lowercased().contains(queryLowercase) {
                    score += 100
                }
                if fuse.search(query, in: tag) != nil {
                    score += 50
                }
            }
            
            // Only include books with a positive score
            if score > 0 {
                bookScores.append((book, score))
            }
        }
        
        // Sort by score (higher is better)
        let sortedBooks = bookScores.sorted { $0.score > $1.score }
        
        return sortedBooks.map { $0.book }
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

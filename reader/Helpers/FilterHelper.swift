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
    
    private enum SearchType {
        case general(String)
        case title(String)
        case author(String)
        case tag(String)
    }
    
    // Filter books by search query
    func searched(with query: String) -> [BookData] {
        guard !query.isEmpty else { return self }
        
        // Parse the query into the appropriate search type
        let searchType: SearchType
        
        if query.lowercased().hasPrefix("title:") {
            let titleQuery = query.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
            searchType = .title(titleQuery)
        } else if query.lowercased().hasPrefix("author:") {
            let authorQuery = query.dropFirst(7).trimmingCharacters(in: .whitespacesAndNewlines)
            searchType = .author(authorQuery)
        } else if query.hasPrefix("#") {
            let tagQuery = query.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
            searchType = .tag(tagQuery)
        } else {
            searchType = .general(query)
        }
        
        let fuse = Fuse()
        var bookScores: [(book: BookData, score: Int)] = []
        
        for book in self {
            var score = 0
            
            switch searchType {
            case .general(let query):
                let queryLowercase = query.lowercased()
                let queryTerms = queryLowercase.split(separator: " ").map(String.init)
                let titleLower = book.title.lowercased()
                let authorLower = book.author.lowercased()
                
                // Title exact match
                if titleLower == queryLowercase {
                    score += 100000
                } else if titleLower.hasPrefix(queryLowercase) {
                    score += 50000
                } else {
                    // Sequential terms in title
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
                
                // Author exact match
                if authorLower == queryLowercase {
                    score += 9000
                }
                
                // Title contains terms
                for term in queryTerms {
                    if titleLower.contains(term) {
                        score += 1000
                    }
                }
                
                // Author contains query
                if authorLower.contains(queryLowercase) {
                    score += 800
                }
                
                // Author contains terms
                for term in queryTerms {
                    if authorLower.contains(term) {
                        score += 500
                    }
                }
                
                // Fuzzy matching
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
                
            case .title(let titleQuery):
                // Search only in title
                if titleQuery.isEmpty { break }
                
                let titleLower = book.title.lowercased()
                let queryLowercase = titleQuery.lowercased()
                let queryTerms = queryLowercase.split(separator: " ").map(String.init)
                
                if titleLower == queryLowercase {
                    score += 100000
                } else if titleLower.hasPrefix(queryLowercase) {
                    score += 50000
                } else {
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
                    
                    for term in queryTerms {
                        if titleLower.contains(term) {
                            score += 1000
                        }
                    }
                    
                    if fuse.search(titleQuery, in: book.title) != nil {
                        score += 300
                    }
                }
                
            case .author(let authorQuery):
                // Search only in author
                if authorQuery.isEmpty { break }
                
                let authorLower = book.author.lowercased()
                let queryLowercase = authorQuery.lowercased()
                let queryTerms = queryLowercase.split(separator: " ").map(String.init)
                
                if authorLower == queryLowercase {
                    score += 9000
                } else if authorLower.hasPrefix(queryLowercase) {
                    score += 4500
                } else {
                    for term in queryTerms {
                        if authorLower.contains(term) {
                            score += 500
                        }
                    }
                    
                    if fuse.search(authorQuery, in: book.author) != nil {
                        score += 200
                    }
                }
                
            case .tag(let tagQuery):
                // Search only in tags
                if tagQuery.isEmpty { break }
                
                let queryLowercase = tagQuery.lowercased()
                
                for tag in book.tags {
                    let tagLower = tag.lowercased()
                    if tagLower == queryLowercase {
                        score += 1000
                        break
                    } else if tagLower.hasPrefix(queryLowercase) {
                        score += 500
                    } else if tagLower.contains(queryLowercase) {
                        score += 100
                    } else if fuse.search(queryLowercase, in: tag) != nil {
                        score += 50
                    }
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

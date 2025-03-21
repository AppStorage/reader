import Foundation
import Fuse

// Calculates similarity between two strings using Levenshtein distance
// Returns a value between 0.0 (completely different) and 1.0 (identical)
private func calculateSimilarity(between str1: String, and str2: String) -> Double {
    let maxLength = max(str1.count, str2.count)
    if maxLength == 0 { return 1.0 }  // Both strings are empty
    
    let editDistance = levenshteinDistance(str1, str2)
    return 1.0 - (Double(editDistance) / Double(maxLength))
}

// Calculates the Levenshtein distance between two strings
// Lower values indicate more similar strings
private func levenshteinDistance(_ a: String, _ b: String) -> Int {
    let aChars = Array(a)
    let bChars = Array(b)
    
    var dist = [[Int]](repeating: [Int](repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
    
    for i in 0...aChars.count {
        dist[i][0] = i
    }
    
    for j in 0...bChars.count {
        dist[0][j] = j
    }
    
    for i in 1...aChars.count {
        for j in 1...bChars.count {
            if aChars[i-1] == bChars[j-1] {
                dist[i][j] = dist[i-1][j-1]
            } else {
                dist[i][j] = min(
                    dist[i-1][j] + 1,   // deletion
                    dist[i][j-1] + 1,   // insertion
                    dist[i-1][j-1] + 1  // substitution
                )
            }
        }
    }
    
    return dist[aChars.count][bChars.count]
}

// MARK: - Search Types
private enum SearchType {
    case general(String)
    case title(String)
    case author(String)
    case tag(String)
    
    static func from(query: String) -> SearchType {
        if query.lowercased().hasPrefix("title:") {
            let titleQuery = query.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
            return .title(titleQuery)
        } else if query.lowercased().hasPrefix("author:") {
            let authorQuery = query.dropFirst(7).trimmingCharacters(in: .whitespacesAndNewlines)
            return .author(authorQuery)
        } else if query.hasPrefix("#") {
            let tagQuery = query.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
            return .tag(tagQuery)
        } else {
            return .general(query)
        }
    }
}

// MARK: - Scoring Constants
private enum ScoreWeight {
    static let titleExactMatch = 100000
    static let titlePrefixMatch = 50000
    static let titleSequentialTerms = 10000
    static let authorExactMatch = 9000
    static let authorPrefixMatch = 4500
    static let titleContainsTerm = 1000
    static let authorContainsQuery = 800
    static let authorContainsTerm = 500
    static let titleFuzzyMatch = 300
    static let isbnMatch = 300
    static let isbnStrippedMatch = 250
    static let authorFuzzyMatch = 200
    static let seriesContains = 150
    static let seriesFuzzy = 75
    static let descriptionContains = 100
    static let publisherContains = 100
    static let genreContains = 100
    static let tagContains = 100
    static let descriptionFuzzy = 50
    static let publisherFuzzy = 50
    static let genreFuzzy = 50
    static let tagFuzzy = 50
    static let isbnFuzzy = 150
    static let tagExactMatch = 1000
    static let tagPrefixMatch = 500
    static let tagContainsQuery = 100
    static let tagSimilarityMatch = 25
}

// MARK: - BookData Array Extension
extension Array where Element == BookData {
    // Filter books by status
    func filtered(by status: StatusFilter) -> [BookData] {
        filter { book in
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
        
        let searchType = SearchType.from(query: query)
        let fuse = Fuse()
        var bookScores: [(book: BookData, score: Int)] = []
        
        for book in self {
            let score = calculateSearchScore(for: book, searchType: searchType, fuse: fuse)
            if score > 0 {
                bookScores.append((book, score))
            }
        }
        
        // Sort by score, higher is better
        return bookScores.sorted { $0.score > $1.score }.map { $0.book }
    }
    
    // Filter books by tags
    func filtered(byTags tags: Set<String>) -> [BookData] {
        guard !tags.isEmpty else { return self }
        return filter { book in
            !tags.isDisjoint(with: book.tags)
        }
    }
    
    // Sort books based on selected option and order
    func sorted(by option: SortOption, order: SortOrder) -> [BookData] {
        sorted { book1, book2 in
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
        filtered(by: status).count
    }
    
    // Calculate a search score for a single book based on the search type
    private func calculateSearchScore(for book: BookData, searchType: SearchType, fuse: Fuse) -> Int {
        switch searchType {
        case .general(let query):
            return calculateGeneralSearchScore(for: book, query: query, fuse: fuse)
        case .title(let titleQuery):
            return calculateTitleSearchScore(for: book, query: titleQuery, fuse: fuse)
        case .author(let authorQuery):
            return calculateAuthorSearchScore(for: book, query: authorQuery, fuse: fuse)
        case .tag(let tagQuery):
            return calculateTagSearchScore(for: book, query: tagQuery, fuse: fuse)
        }
    }
    
    // Calculate a score for general search across all book fields
    private func calculateGeneralSearchScore(for book: BookData, query: String, fuse: Fuse) -> Int {
        var score = 0
        let queryLowercase = query.lowercased()
        let queryTerms = queryLowercase.split(separator: " ").map(String.init)
        let titleLower = book.title.lowercased()
        let authorLower = book.author.lowercased()
        
        // Title matching
        if titleLower == queryLowercase {
            score += ScoreWeight.titleExactMatch
        } else if titleLower.hasPrefix(queryLowercase) {
            score += ScoreWeight.titlePrefixMatch
        } else if hasSequentialTerms(queryTerms: queryTerms, in: titleLower) {
            score += ScoreWeight.titleSequentialTerms
        }
        
        // Author matching
        if authorLower == queryLowercase {
            score += ScoreWeight.authorExactMatch
        }
        
        // Title contains terms
        for term in queryTerms where titleLower.contains(term) {
            score += ScoreWeight.titleContainsTerm
        }
        
        // Author contains query/terms
        if authorLower.contains(queryLowercase) {
            score += ScoreWeight.authorContainsQuery
        }
        
        for term in queryTerms where authorLower.contains(term) {
            score += ScoreWeight.authorContainsTerm
        }
        
        // Fuzzy matching
        if fuse.search(query, in: book.title) != nil {
            score += ScoreWeight.titleFuzzyMatch
        }
        
        if fuse.search(query, in: book.author) != nil {
            score += ScoreWeight.authorFuzzyMatch
        }
        
        // Additional fields matching
        score += scoreForDescription(book.bookDescription, query: query, queryLowercase: queryLowercase, fuse: fuse)
        score += scoreForPublisher(book.publisher, query: query, queryLowercase: queryLowercase, fuse: fuse)
        score += scoreForSeries(book.series, query: query, queryLowercase: queryLowercase, fuse: fuse)
        score += scoreForGenre(book.genre, query: query, queryLowercase: queryLowercase, fuse: fuse)
        score += scoreForISBN(book.isbn, query: query, fuse: fuse)
        
        // Tag matching
        for tag in book.tags {
            if tag.lowercased().contains(queryLowercase) {
                score += ScoreWeight.tagContains
            }
            if fuse.search(query, in: tag) != nil {
                score += ScoreWeight.tagFuzzy
            }
        }
        
        return score
    }
    
    // Calculate a score for title search
    private func calculateTitleSearchScore(for book: BookData, query: String, fuse: Fuse) -> Int {
        guard !query.isEmpty else { return 0 }
        
        var score = 0
        let titleLower = book.title.lowercased()
        let queryLowercase = query.lowercased()
        let queryTerms = queryLowercase.split(separator: " ").map(String.init)
        
        // Exact title match gets highest priority
        if titleLower == queryLowercase {
            score += ScoreWeight.titleExactMatch * 2
        } else if titleLower.hasPrefix(queryLowercase) {
            score += ScoreWeight.titlePrefixMatch
        } else {
            // For non-exact matches
            // Check if all terms appear in sequence
            if hasSequentialTerms(queryTerms: queryTerms, in: titleLower) {
                score += ScoreWeight.titleSequentialTerms
            }
            
            // Check if all terms appear anywhere in the title
            let allTermsMatch = queryTerms.allSatisfy { term in
                titleLower.contains(term)
            }
            if allTermsMatch {
                score += ScoreWeight.titleContainsTerm * 2
            }
            
            // Fuzzy matching as last resort
            if fuse.search(query, in: book.title) != nil {
                score += ScoreWeight.titleFuzzyMatch
            }
        }
        
        return score
    }
    
    // Calculate a score for author search
    private func calculateAuthorSearchScore(for book: BookData, query: String, fuse: Fuse) -> Int {
        guard !query.isEmpty else { return 0 }
        
        var score = 0
        let authorLower = book.author.lowercased()
        let queryLowercase = query.lowercased()
        let queryTerms = queryLowercase.split(separator: " ").map(String.init)
        
        if authorLower == queryLowercase {
            score += ScoreWeight.authorExactMatch
        } else if authorLower.hasPrefix(queryLowercase) {
            score += ScoreWeight.authorPrefixMatch
        } else {
            for term in queryTerms where authorLower.contains(term) {
                score += ScoreWeight.authorContainsTerm
            }
            
            if fuse.search(query, in: book.author) != nil {
                score += ScoreWeight.authorFuzzyMatch
            }
        }
        
        return score
    }
    
    // Calculate a score for tag search
    private func calculateTagSearchScore(for book: BookData, query: String, fuse: Fuse) -> Int {
        guard !query.isEmpty else { return 0 }
        
        var score = 0
        let queryLowercase = query.lowercased()
        var hasExactOrPrefixMatch = false
        
        for tag in book.tags {
            let tagLower = tag.lowercased()
            if tagLower == queryLowercase {
                score += ScoreWeight.tagExactMatch
                hasExactOrPrefixMatch = true
                break
            } else if tagLower.hasPrefix(queryLowercase) {
                score += ScoreWeight.tagPrefixMatch
                hasExactOrPrefixMatch = true
            } else if tagLower.contains(queryLowercase) {
                score += ScoreWeight.tagContainsQuery
                hasExactOrPrefixMatch = true
            }
        }
        
        // Only use fuzzy matching if no exact/prefix/contains matches were found
        if !hasExactOrPrefixMatch {
            for tag in book.tags {
                let tagLower = tag.lowercased()
                
                if tagLower.count > 0 && queryLowercase.count > 0 {
                    if fuse.search(queryLowercase, in: tag) != nil &&
                        calculateSimilarity(between: queryLowercase, and: tagLower) > 0.5 {
                        score += ScoreWeight.tagSimilarityMatch
                    }
                }
            }
        }
        
        return score
    }
    
    // MARK: - Search Scoring Helpers
    // Check if all query terms appear sequentially in the text
    private func hasSequentialTerms(queryTerms: [String], in text: String) -> Bool {
        var lastPos = 0
        
        for term in queryTerms {
            if let range = text.range(of: term, range: text.index(text.startIndex, offsetBy: lastPos)..<text.endIndex) {
                lastPos = text.distance(from: text.startIndex, to: range.upperBound)
            } else {
                return false
            }
        }
        
        return true
    }
    
    // Score for book description
    private func scoreForDescription(_ description: String?, query: String, queryLowercase: String, fuse: Fuse) -> Int {
        guard let description = description else { return 0 }
        
        var score = 0
        let descriptionLower = description.lowercased()
        
        if descriptionLower.contains(queryLowercase) {
            score += ScoreWeight.descriptionContains
        }
        
        if fuse.search(query, in: description) != nil {
            score += ScoreWeight.descriptionFuzzy
        }
        
        return score
    }
    
    // Score for book publisher
    private func scoreForPublisher(_ publisher: String?, query: String, queryLowercase: String, fuse: Fuse) -> Int {
        guard let publisher = publisher else { return 0 }
        
        var score = 0
        let publisherLower = publisher.lowercased()
        
        if publisherLower.contains(queryLowercase) {
            score += ScoreWeight.publisherContains
        }
        
        if fuse.search(query, in: publisher) != nil {
            score += ScoreWeight.publisherFuzzy
        }
        
        return score
    }
    
    // Score for book series
    private func scoreForSeries(_ series: String?, query: String, queryLowercase: String, fuse: Fuse) -> Int {
        guard let series = series else { return 0 }
        
        var score = 0
        let seriesLower = series.lowercased()
        
        if seriesLower.contains(queryLowercase) {
            score += ScoreWeight.seriesContains
        }
        
        if fuse.search(query, in: series) != nil {
            score += ScoreWeight.seriesFuzzy
        }
        
        return score
    }
    
    // Score for book genre
    private func scoreForGenre(_ genre: String?, query: String, queryLowercase: String, fuse: Fuse) -> Int {
        guard let genre = genre else { return 0 }
        
        var score = 0
        let genreLower = genre.lowercased()
        
        if genreLower.contains(queryLowercase) {
            score += ScoreWeight.genreContains
        }
        
        if fuse.search(query, in: genre) != nil {
            score += ScoreWeight.genreFuzzy
        }
        
        return score
    }
    
    // Score for ISBN
    private func scoreForISBN(_ isbn: String?, query: String, fuse: Fuse) -> Int {
        guard let isbn = isbn else { return 0 }
        
        var score = 0
        
        if isbn.contains(query) {
            score += ScoreWeight.isbnMatch
        }
        
        if fuse.search(query, in: isbn) != nil {
            score += ScoreWeight.isbnFuzzy
        }
        
        let strippedQuery = query.replacingOccurrences(of: "-", with: "")
        let strippedISBN = isbn.replacingOccurrences(of: "-", with: "")
        if strippedISBN.contains(strippedQuery) {
            score += ScoreWeight.isbnStrippedMatch
        }
        
        return score
    }
}

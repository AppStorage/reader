import Foundation

// Top-level response from the Google Books API
struct GoogleBooksResponse: Codable {
    let items: [BookItem]?
}

// Each book item in the API response
struct BookItem: Codable {
    let volumeInfo: VolumeInfo
}

// Identifiers (e.g., ISBN)
struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

// Volume information about a book
struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publishedDate: String
    let description: String?
    let publisher: String?
    let categories: [String]?
    let industryIdentifiers: [IndustryIdentifier]?
    let subtitle: String?
    let series: String?
    
    // Sanitizes the description by removing basic HTML-like tags
    var sanitizedDescription: String? {
        description?.replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
    }
    
    // Attempts to parse the published date in different formats (full date, year-month, year)
    var parsedPublishedDate: Date? {
        guard !publishedDate.isEmpty else { return nil }
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let fullDate = dateFormatter.date(from: publishedDate) {
            return fullDate
        }
        
        dateFormatter.dateFormat = "yyyy-MM"
        if let yearMonthDate = dateFormatter.date(from: publishedDate) {
            return yearMonthDate
        }
        
        dateFormatter.dateFormat = "yyyy"
        if let yearDate = dateFormatter.date(from: publishedDate) {
            return yearDate
        }
        
        return nil
    }
    
    // Combines title and subtitle for a more descriptive full title
    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }
    
    // Returns the first category if available, as the primary genre/category
    var primaryCategory: String? {
        categories?.first
    }
    
    // Selects the most relevant ISBN, prioritizing user input or ISBN-13 over ISBN-10
    func primaryISBN(userInputISBN: String? = nil) -> String? {
        if let inputISBN = userInputISBN,
           let matchingISBN = industryIdentifiers?.first(where: { $0.identifier == inputISBN }) {
            return matchingISBN.identifier
        }
        return industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier
    }
}

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

    // Sanitized description (removes HTML-like elements)
    var sanitizedDescription: String? {
        description?.replacingOccurrences(of: "<br>", with: "\n")
                    .replacingOccurrences(of: "</p>", with: "\n")
                    .replacingOccurrences(of: "<p>", with: "")
    }

    // Parsed published date
    var parsedPublishedDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: publishedDate)
    }

    // Combined title and subtitle
    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }

    // Fetches primary category if available
    var primaryCategory: String? {
        categories?.first
    }

    // Finds primary ISBN (prefers ISBN-13 over ISBN-10)
    var primaryISBN: String? {
        industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier
    }
}

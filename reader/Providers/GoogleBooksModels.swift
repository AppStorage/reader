import Foundation

// Top-level response from the Google Books API
struct GoogleBooksResponse: Codable {
    let items: [BookItem]?
}

// Each book item in the API response
struct BookItem: Codable {
    let volumeInfo: VolumeInfo
}

// Book volume information from the API
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
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

extension VolumeInfo {
    // Returns a sanitized description, stripping HTML or invalid content
    var sanitizedDescription: String? {
        sanitizeDescription(description)
    }
    
    // Parses and converts the published date to a Date object
    var parsedPublishedDate: Date? {
        parseDate(publishedDate)
    }
    
    // Combines the title and subtitle, if available
    var fullTitle: String {
        subtitle?.isEmpty == false ? "\(title): \(subtitle!)" : title
    }
    
    // Returns the first available category
    var primaryCategory: String? {
        categories?.first
    }
    
    // Determines the primary ISBN based on input or available identifiers
    func primaryISBN(userInputISBN: String? = nil) -> String? {
        if let inputISBN = userInputISBN,
           let match = industryIdentifiers?.first(where: { $0.identifier == inputISBN }) {
            return match.identifier
        }
        return industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier
    }
}

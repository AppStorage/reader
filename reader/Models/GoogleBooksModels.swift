import Foundation

// Top-level response from the Google Books API
struct GoogleBooksResponse: Codable {
    let items: [BookItem]?
}

// Each book item in the API response
struct BookItem: Codable {
    let volumeInfo: VolumeInfo
}

// Identifiers (e.g., ISBN) for books
struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

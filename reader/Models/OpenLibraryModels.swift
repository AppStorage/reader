import Foundation

// Open Library API Search Response
struct OpenLibrarySearchResponse: Codable {
    let docs: [OpenLibraryDoc]
}

// Represents a single book document in the Open Library API
struct OpenLibraryDoc: Codable {
    let title: String
    let author_name: [String]?
    let publisher: [String]?
    let first_publish_year: Int?
    let isbn: [String]?
    let subject: [String]?
    let key: String?
}

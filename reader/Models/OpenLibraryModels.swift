import Foundation

struct OpenLibrarySearchResponse: Codable {
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Codable {
    let title: String
    let author_name: [String]?
    let publisher: [String]?
    let first_publish_year: Int?
    let isbn: [String]?
    let subject: [String]?
}

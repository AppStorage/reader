import Foundation

struct BookDTO: Sendable {
    let id: UUID
    let title: String
    let author: String
    let published: Date?
    let publisher: String?
    let genre: String?
    let series: String?
    let isbn: String?
    let bookDescription: String?
    let status: ReadingStatus
    let quotes: String
    let notes: String
    let tags: [String]
    let dateStarted: Date?
    let dateFinished: Date?
}

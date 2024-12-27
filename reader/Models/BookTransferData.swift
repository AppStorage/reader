import Foundation

struct BookTransferData: Sendable, Equatable {
    let title: String
    let author: String
    let published: Date?
    let publisher: String?
    let genre: String?
    let series: String?
    let isbn: String?
    let bookDescription: String?
    let quotes: String
    let notes: String
    let tags: [String]
    let status: ReadingStatus
}

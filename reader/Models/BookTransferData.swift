import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let bookTransferData = UTType.json
}

struct BookTransferData: Codable, Transferable, Sendable, Equatable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let author: String
    let published: Date?
    let publisher: String?
    let genre: String?
    let series: String?
    let isbn: String?
    let bookDescription: String?
    let quotes: [String]
    let notes: [String]
    let tags: [String]
    let status: ReadingStatus
    
    // MARK: - Transferable Conformance
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: BookTransferData.self, contentType: .bookTransferData)
    }
}

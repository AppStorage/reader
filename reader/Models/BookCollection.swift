import Foundation
import SwiftData

@Model
class BookCollection: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    
    @Relationship(deleteRule: .nullify) var books: [BookData] = []
    
    var name: String
    
    init(name: String, books: [BookData] = []) {
        self.name = name
        self.books = books
    }
}

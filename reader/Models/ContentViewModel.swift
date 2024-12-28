import Foundation
import SwiftUI
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @AppStorage("selectedStatus") var selectedStatus: StatusFilter = .all
    
    @Published var searchQuery: String = ""
    @Published var sortOption: SortOption = .title
    @Published var sortOrder: SortOrder = .ascending
    @Published var selectedBook: BookData?
    @Published var selectedTags: Set<String> = []
    @Published private(set) var books: [BookData] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        // Observe books in DataManager and update local books property
        dataManager.$books
            .receive(on: DispatchQueue.main)
            .assign(to: &$books)
    }
    
    // Computed property to apply filters and sorting
    var displayedBooks: [BookData] {
        // Filter by status first
        let filteredByStatus = books.filtered(by: selectedStatus)
        
        // Filter by search query
        let filteredBySearch = filteredByStatus.searched(with: searchQuery)
        
        // Filter by tags
        let filteredByTags = selectedTags.isEmpty
        ? filteredBySearch
        : filteredBySearch.filter { book in
            !selectedTags.isDisjoint(with: book.tags)
        }
        
        // Sort and return
        return filteredByTags.sorted(by: sortOption, order: sortOrder)
    }
    
    func bookCount(for status: StatusFilter) -> Int {
        return books.count(for: status)
    }
    
    func recoverBook(_ book: BookData) {
        dataManager.updateBookStatus(book, to: .unread)
        book.updateDates(for: .unread)
    }
    
    func softDeleteBooks(_ books: [BookData]) {
        for book in books {
            dataManager.updateBookStatus(book, to: .deleted)
            book.updateDates(for: .deleted)
        }
    }
    
    func permanentlyDeleteBooks(_ booksToDelete: [BookData]) {
        for book in booksToDelete {
            dataManager.permanentlyDeleteBook(book)
        }
        self.books.removeAll { book in
            booksToDelete.contains(where: { $0.id == book.id })
        }
    }
    
    func updateBookStatus(for books: [BookData], to status: ReadingStatus) {
        for book in books {
            dataManager.updateBookStatus(book, to: status)
        }
    }
}

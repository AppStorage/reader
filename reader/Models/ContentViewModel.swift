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
        let filteredByStatus = FilterHelper.applyStatusFilter(to: books, status: selectedStatus)
        let filteredBySearch = FilterHelper.applySearchFilter(to: filteredByStatus, query: searchQuery)
        
        // Filter by selected tags
        let filteredByTags = selectedTags.isEmpty
        ? filteredBySearch
        : filteredBySearch.filter { book in
            !selectedTags.isDisjoint(with: book.tags)
        }
        
        return FilterHelper.applySorting(to: filteredByTags, option: sortOption, order: sortOrder)
    }
    
    func bookCount(for status: StatusFilter) -> Int {
        return FilterHelper.countBooks(for: status, in: books)
    }
    
    func softDeleteBook(_ book: BookData) {
        dataManager.updateBookStatus(book, to: .deleted)
        book.updateDates(for: .deleted)
    }
    
    func recoverBook(_ book: BookData) {
        dataManager.updateBookStatus(book, to: .unread)
        book.updateDates(for: .unread)
    }
    
    func permanentlyDeleteBook(_ book: BookData) {
        let wasDeletedFilter = selectedStatus == .deleted  // Check if current filter is deleted
        
        // Remove the book from the local list (update the in-memory collection)
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books.remove(at: index)
        }
        
        // Call DataManager to handle permanent deletion from storage
        dataManager.permanentlyDeleteBook(book)
        
        // Reapply the deleted filter if it was previously selected
        if wasDeletedFilter {
            selectedStatus = .deleted
        }
        
        // Clear the selection if the book was being viewed in DetailView
        if let selectedBook = self.selectedBook, selectedBook.id == book.id {
            self.selectedBook = nil
        }
    }
}

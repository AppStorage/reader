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
    @Published var selectedCollection: BookCollection?
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
        if let collection = selectedCollection {
            // Return only books in the selected collection
            return collection.books.sorted(by: sortOption, order: sortOrder)
        } else {
            // Filter by status if no collection is selected
            let filteredByStatus = books.filtered(by: selectedStatus)
            
            // Filter by search query
            let filteredBySearch = filteredByStatus.searched(with: searchQuery)
            
            // Filter by tags
            let filteredByTags = selectedTags.isEmpty
            ? filteredBySearch
            : filteredBySearch.filter { book in
                !selectedTags.isDisjoint(with: book.tags)
            }
            
            // Return sorted results
            return filteredByTags.sorted(by: sortOption, order: sortOrder)
        }
    }
    
    func bookCount(for status: StatusFilter) -> Int {
        return books.count(for: status)
    }
    
    func recoverBook(_ book: BookData) {
        dataManager.updateBookStatus(book, to: .unread)
        book.updateDates(for: .unread)
    }
    
    func softDeleteBooks(_ books: [BookData]) {
        dataManager.softDeleteBooks(books)
    }
    
    func permanentlyDeleteBooks(_ booksToDelete: [BookData]) {
        dataManager.permanentlyDeleteBooks(booksToDelete)
    }
    
    func updateBookStatus(for books: [BookData], to status: ReadingStatus) {
        for book in books {
            dataManager.updateBookStatus(book, to: status)
        }
    }
    
    // MARK: Tags
    func toggleTagSelection(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearTag(_ tag: String) {
        selectedTags.remove(tag)
    }
    
    // MARK: Collections
    func renameSelectedCollection(to newName: String) {
        guard let collection = selectedCollection else { return }
        dataManager.renameCollection(collection, to: newName)
    }
    
    func removeCollection(_ collection: BookCollection) {
        dataManager.removeCollection(collection)
    }
    
    func removeBookFromSelectedCollection(_ book: BookData) {
        if let collection = selectedCollection {
            dataManager.removeBookFromCollection(book, from: collection)
        }
    }
}

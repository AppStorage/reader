import SwiftUI
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @AppStorage("selectedStatus") var selectedStatus: StatusFilter = .all
    
    @Published var books: [BookData] = []
    @Published var searchQuery: String = ""
    @Published var sortOption: SortOption = .title
    @Published var sortOrder: SortOrder = .ascending
    @Published var selectedBook: BookData?
    @Published var selectedTags: Set<String> = []
    @Published var selectedCollection: BookCollection?
    @Published var showDashboard: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private var dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        dataManager.$books
            .receive(on: DispatchQueue.main)
            .assign(to: &$books)
    }
    
    // Filters and sorting
    var displayedBooks: [BookData] {
        if let collection = selectedCollection {
            return collection.books.sorted(by: sortOption, order: sortOrder)
        } else {
            let filteredByStatus = books.filtered(by: selectedStatus)
            
            let filteredBySearch = filteredByStatus.searched(with: searchQuery)
            
            let filteredByTags = selectedTags.isEmpty
            ? filteredBySearch
            : filteredBySearch.filter { book in
                let bookTags = Set(book.tags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
                let selectedTagsLower = Set(selectedTags.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
                return !selectedTagsLower.isDisjoint(with: bookTags)
            }
            
            return filteredByTags.sorted(by: sortOption, order: sortOrder)
        }
    }
    
    // Status count
    func bookCount(for status: StatusFilter) -> Int {
        return books.count(for: status)
    }
    
    // Collection count
    func bookCount(for collection: BookCollection?) -> Int {
        guard let collection = collection else { return 0 }
        return collection.books.count
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

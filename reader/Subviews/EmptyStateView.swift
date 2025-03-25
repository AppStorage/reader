import SwiftUI

enum EmptyStateTypes {
    case list // Generic list (default)
    case search // No search results
    case deleted // No deleted books
    case detail // No book selected in detail view
    case unread // No unread books
    case reading // No currently reading books
    case read // No completed books
    case collection // No books in collection
    case tags // No tags
    case notes // No notes
    case quotes // No quotes
    case chart // No chart
    
    // Icons
    var imageName: String {
        switch self {
        case .list: return "questionmark"
        case .search: return "text.page.badge.magnifyingglass"
        case .deleted: return "trash.slash"
        case .detail: return "book.pages"
        case .unread: return "questionmark"
        case .reading: return "questionmark"
        case .read: return "questionmark"
        case .collection: return "questionmark.folder"
        case .tags: return "tag.slash.fill"
        case .notes: return "note"
        case .quotes: return "quote.opening"
        case .chart: return "chart.bar.xaxis"
        }
    }
    
    // Title
    var title: String {
        switch self {
        case .list: return "No books found"
        case .search: return "No books found"
        case .deleted: return "No deleted books"
        case .detail: return "Select a book to view details"
        case .unread: return "No unread books"
        case .reading: return "No books currently being read"
        case .read: return "No completed books"
        case .collection: return "No books in your collection"
        case .tags: return "No tags exist here yet."
        case .notes: return "No notes exist here yet."
        case .quotes: return "No quotes exist here yet."
        case .chart: return "No chart data"
            
        }
    }
    
    // Message
    var message: String? {
        switch self {
        case .list: return "It's empty here. Add a new book to get started."
        case .search: return "Try adjusting your search or add a new book."
        case .deleted: return "Looks like you haven't deleted any books yet."
        case .detail: return nil
        case .unread: return "It's empty here. Add a new book to get started."
        case .reading: return "Start reading a book to track it here."
        case .read: return "No books read yet? Maybe it's time to change that."
        case .collection: return "It's empty here. Add some books into your collection."
        case .tags, .notes, .quotes: return nil
        case .chart: return "There isn’t enough data to display a chart yet."
        }
    }
    
    // Spacing
    var spacing: CGFloat {
        switch self {
        case .detail: return 10
        case .tags, .notes, .quotes: return 8
        default: return 16
        }
    }
}

struct EmptyStateView: View {
    let type: EmptyStateTypes
    var minWidth: CGFloat? = nil
    var selectedBooks: [BookData] = []
    var viewModel: ContentViewModel? = nil
    var isCompact: Bool = false
    var icon: String? = nil
    var titleOverride: String? = nil
    var messageOverride: String? = nil
    
    var body: some View {
        VStack(spacing: type.spacing) {
            if !isCompact {
                Spacer()
            }
            
            VStack {
                Image(systemName: icon ?? type.imageName)
                    .foregroundColor(.secondary)
                    .imageScale(isCompact ? .large : .large)
                    .font(isCompact ? nil : .system(size: 40))
                    .padding(.bottom, 8)

                Text(titleOverride ?? type.title)
                    .foregroundColor(.secondary)
                    .font(isCompact ? .callout : .headline)

                if let message = messageOverride ?? type.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            if !isCompact {
                Spacer()
            }
        }
        .frame(minWidth: minWidth)
        .padding(isCompact ? 16 : 0)
        .toolbar {
            if !isCompact {
                ToolbarItem(placement: .automatic) {
                    Spacer()
                }
            }
        }
    }
}

import SwiftUI
import Foundation

enum SortOption {
    case title
    case author
    case published
}

enum SortOrder {
    case ascending
    case descending
}

enum ToolbarMode {
    case standardMode
    case editMode
}

enum Field: Hashable {
    case title
    case author
    case genre
    case series
    case isbn
    case publisher
    case published
}

enum AlertType: Identifiable {
    case newUpdateAvailable
    case upToDate
    
    var id: Int {
        switch self {
        case .newUpdateAvailable: return 1
        case .upToDate: return 2
        }
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { rawValue }
}

enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case reading = "Reading"
    case read = "Read"
    case deleted = "Deleted"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all:
            return "books.vertical"
        case .unread:
            return "book.closed"
        case .reading:
            return "book"
        case .read:
            return "book.closed"
        case .deleted:
            return "trash"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .all:
            return .purple.opacity(0.8)
        case .unread:
            return .gray
        case .reading:
            return .blue.opacity(0.7)
        case .read:
            return .green.opacity(0.7)
        case .deleted:
            return .red.opacity(0.7)
        }
    }
}

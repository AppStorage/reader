import SwiftUI

enum ReadingStatus: String, CaseIterable, Codable {
    case unread
    case reading
    case read
    case deleted
    
    var displayText: String {
        switch self {
        case .unread: return "Unread"
        case .reading: return "Reading"
        case .read: return "Read"
        case .deleted: return "Deleted"
        }
    }
}

protocol StatusDisplayable {
    var iconName: String { get }
    var statusColor: Color { get }
}

extension ReadingStatus: StatusDisplayable {
    // Convert to StatusFilter
    func toStatusFilter() -> StatusFilter {
        switch self {
        case .unread: return .unread
        case .reading: return .reading
        case .read: return .read
        case .deleted: return .deleted
        }
    }
    var iconName: String {
        switch self {
        case .unread: return "book.closed"
        case .reading: return "book"
        case .read: return "checkmark.circle"
        case .deleted: return "trash"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .unread: return .gray
        case .reading: return .blue
        case .read: return .green
        case .deleted: return .red
        }
    }
}

enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case reading = "Reading"
    case read = "Read"
    case deleted = "Deleted"
    
    var id: String { rawValue }
    
    func toReadingStatus() -> ReadingStatus? {
        switch self {
        case .all: return nil
        case .unread: return .unread
        case .reading: return .reading
        case .read: return .read
        case .deleted: return .deleted
        }
    }
    
    var readingStatus: ReadingStatus? {
        return toReadingStatus()
    }
}

extension StatusFilter: StatusDisplayable {
    var iconName: String {
        switch self {
        case .all: return "books.vertical"
        default: return readingStatus!.iconName
        }
    }
    
    var statusColor: Color {
        switch self {
        case .all: return .purple.opacity(0.8)
        case .unread: return readingStatus!.statusColor.opacity(0.7)
        case .reading: return readingStatus!.statusColor.opacity(0.7)
        case .read: return readingStatus!.statusColor.opacity(0.7)
        case .deleted: return readingStatus!.statusColor.opacity(0.7)
        }
    }
}

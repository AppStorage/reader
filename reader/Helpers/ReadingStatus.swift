import SwiftUI

enum ReadingStatus: String, CaseIterable, Codable {
    case unread
    case reading
    case read
    case deleted
    
    // Display Text
    var displayText: String {
        switch self {
        case .unread: return "Unread"
        case .reading: return "Reading"
        case .read: return "Read"
        case .deleted: return "Deleted"
        }
    }
    
    // Display Colors
    var statusColor: Color {
        switch self {
        case .unread: return .gray
        case .reading: return .blue
        case .read: return .green
        case .deleted: return .red
        }
    }
    
    // Status Icons
    var iconName: String {
        switch self {
        case .unread: return "book.closed"
        case .reading: return "book"
        case .read: return "checkmark.circle"
        case .deleted: return "trash"
        }
    }
}

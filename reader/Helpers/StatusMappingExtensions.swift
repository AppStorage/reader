import SwiftUI

extension ReadingStatus {
    func toStatusFilter() -> StatusFilter {
        switch self {
        case .unread: return .unread
        case .reading: return .reading
        case .read: return .read
        case .deleted: return .deleted
        }
    }
}

extension StatusFilter {
    func toReadingStatus() -> ReadingStatus? {
        switch self {
        case .unread: return .unread
        case .reading: return .reading
        case .read: return .read
        case .deleted: return .deleted
        case .all: return nil
        }
    }
}


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

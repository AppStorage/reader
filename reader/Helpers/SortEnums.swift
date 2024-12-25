import SwiftUI

enum SortOption: String, CaseIterable {
    case title = "Title"
    case author = "Author"
    case published = "Published"
}

enum SortOrder {
    case ascending
    case descending
}

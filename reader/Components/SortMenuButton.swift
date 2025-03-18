import SwiftUI

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case title = "Title"
    case author = "Author"
    case published = "Published"
}

// MARK: - Sort Order
enum SortOrder {
    case ascending
    case descending
}

// MARK: - Sort Button
struct SortMenuButton: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        Menu {
            Section(header: Text("Sort By")) {
                sortOptionButton(label: "Title", option: .title)
                sortOptionButton(label: "Author", option: .author)
                sortOptionButton(label: "Published", option: .published)
            }
            
            Divider()
            
            Section(header: Text("Order")) {
                sortOrderButton(label: "Ascending", order: .ascending, icon: "arrow.up")
                sortOrderButton(label: "Descending", order: .descending, icon: "arrow.down")
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
    
    private func sortOptionButton(label: String, option: SortOption) -> some View {
        Button(action: { contentViewModel.sortOption = option }) {
            HStack {
                Text(label)
                Spacer()
                if contentViewModel.sortOption == option {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    private func sortOrderButton(label: String, order: SortOrder, icon: String) -> some View {
        Button(action: { contentViewModel.sortOrder = order }) {
            HStack {
                Text(label)
                Spacer()
                if contentViewModel.sortOrder == order {
                    Image(systemName: icon)
                }
            }
        }
    }
}

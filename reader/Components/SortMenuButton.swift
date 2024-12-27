import SwiftUI

struct SortMenuButton: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Menu {
            // Section: Sort By
            Section(header: Text("Sort By")) {
                sortOptionButton(label: "Title", option: .title)
                sortOptionButton(label: "Author", option: .author)
                sortOptionButton(label: "Published", option: .published)
            }
            
            Divider()
            
            // Section: Order
            Section(header: Text("Order")) {
                sortOrderButton(label: "Ascending", order: .ascending, icon: "arrow.up")
                sortOrderButton(label: "Descending", order: .descending, icon: "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    // Sort Option Button
    private func sortOptionButton(label: String, option: SortOption) -> some View {
        Button(action: { viewModel.sortOption = option }) {
            HStack {
                Text(label)
                Spacer()
                if viewModel.sortOption == option {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // Sort Order Button
    private func sortOrderButton(label: String, order: SortOrder, icon: String) -> some View {
        Button(action: { viewModel.sortOrder = order }) {
            HStack {
                Text(label)
                Spacer()
                if viewModel.sortOrder == order {
                    Image(systemName: icon)
                }
            }
        }
    }
}

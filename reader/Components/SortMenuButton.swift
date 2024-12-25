import SwiftUI

struct SortMenuButton: View {
    @ObservedObject var viewModel: ContentViewModel
    
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
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    private func sortOptionButton(label: String, option: SortOption) -> some View {
        Button(action: { viewModel.sortOption = option }) {
            Label(label, systemImage: viewModel.sortOption == option ? "checkmark" : "")
        }
    }
    
    private func sortOrderButton(label: String, order: SortOrder, icon: String) -> some View {
        Button(action: { viewModel.sortOrder = order }) {
            Label(label, systemImage: viewModel.sortOrder == order ? icon : "")
        }
    }
}

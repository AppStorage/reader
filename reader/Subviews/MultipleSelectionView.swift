import SwiftUI

struct MultipleSelectionView: View {
    let count: Int
    let selectedBooks: [BookData]
    let viewModel: ContentViewModel
    let dataManager: DataManager
    let selectedCollection: BookCollection?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("\(count) Books Selected")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                StatusButtons(books: selectedBooks, dataManager: dataManager)
            }
            ToolbarItem(placement: .automatic) {
                Spacer()
            }
            ToolbarItem(placement: .automatic) {
                BookActionButton(books: selectedBooks, dataManager: dataManager)
            }
        }
    }
}

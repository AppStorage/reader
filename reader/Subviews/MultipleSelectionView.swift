import SwiftUI

struct MultipleSelectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    let selectedBooks: [BookData]
    
    var count: Int { selectedBooks.count }
    var selectedCollection: BookCollection? { contentViewModel.selectedCollection }
    
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

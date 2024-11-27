import SwiftUI

struct BookRowView: View {
    let book: BookData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

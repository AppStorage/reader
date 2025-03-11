import SwiftUI

struct QuoteShareButton: View {
    let book: BookData
    @State private var isShowingShareSheet = false
    
    var body: some View {
        Button(action: {
            if !book.quotes.isEmpty {
                isShowingShareSheet = true
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .help("Share Quote")
        }
        .disabled(book.quotes.isEmpty)
        .sheet(isPresented: $isShowingShareSheet) {
            QuoteShareView(book: book, isPresented: $isShowingShareSheet)
        }
    }
}

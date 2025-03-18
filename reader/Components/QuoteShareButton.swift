import SwiftUI

struct QuoteShareButton: View {
    @State private var isShowingShareSheet = false
    let book: BookData
    
    var body: some View {
        Button(action: {
            if !book.quotes.isEmpty {
                isShowingShareSheet = true
            }
        }) {
            Label("Share", systemImage: "square.and.arrow.up")
                .help("Share Quote")
                .accessibilityLabel("Share Quote")
        }
        .disabled(book.quotes.isEmpty)
        .sheet(isPresented: $isShowingShareSheet) {
            QuoteShareView(isPresented: $isShowingShareSheet, book: book)
        }
    }
}

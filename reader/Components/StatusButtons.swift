import SwiftUI

struct StatusButtons: View {
    let books: [BookData]
    let dataManager: DataManager
    
    var body: some View {
        Button(action: {
            for book in books {
                dataManager.updateBookStatus(book, to: .unread)
            }
        }) {
            Label("Unread", systemImage: "book.closed")
        }
        .help("Mark as Unread")
        .accessibilityLabel("Mark as Unread")
        
        Button(action: {
            for book in books {
                dataManager.updateBookStatus(book, to: .reading)
            }
        }) {
            Label("Reading", systemImage: "book")
        }
        .help("Mark as Reading")
        .accessibilityLabel("Mark as Reading")
        
        Button(action: {
            for book in books {
                dataManager.updateBookStatus(book, to: .read)
            }
        }) {
            Label("Read", systemImage: "checkmark.circle")
        }
        .help("Mark as Read")
        .accessibilityLabel("Mark as Read")
    }
}

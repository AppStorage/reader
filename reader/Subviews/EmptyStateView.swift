import SwiftUI

struct EmptyStateView: View {
    let imageName: String
    let title: String
    let message: String?
    var spacing: CGFloat = 16
    var minWidth: CGFloat? = nil
    
    var body: some View {
        VStack(spacing: spacing) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(minWidth: minWidth)
    }
}

struct EmptyListView: View {
    var body: some View {
        EmptyStateView(
            imageName: "questionmark",
            title: "No books found",
            message: "It's empty here."
        )
    }
}

struct EmptySearchListView: View {
    var body: some View {
        EmptyStateView(
            imageName: "text.page.badge.magnifyingglass",
            title: "No books found",
            message: "Try adjusting your search or add a new book."
        )
    }
}

struct EmptyDeletedListView: View {
    var body: some View {
        EmptyStateView(
            imageName: "trash.slash",
            title: "No deleted books",
            message: "Looks like you haven’t deleted any books yet."
        )
    }
}

struct EmptyDetailView: View {
    var body: some View {
        EmptyStateView(
            imageName: "book.pages",
            title: "Select a book to view details",
            message: nil, // No additional message
            spacing: 10,
            minWidth: 375
        )
    }
}

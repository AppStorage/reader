import SwiftUI

struct RecentActivityView: View {
    let books: [BookData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Recently Finished Books")
            
            let recentBooks = getRecentlyFinishedBooks()
            
            if !recentBooks.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(recentBooks.prefix(5), id: \.id) { book in
                            RecentBookRow(book: book)
                        }
                    }
                }
                .frame(height: 180)
            } else {
                EmptyChartPlaceholder(
                    icon: "book.closed",
                    message: "No recently finished books"
                )
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
    
    private func getRecentlyFinishedBooks() -> [BookData] {
        books
            .filter { $0.dateFinished != nil }
            .sorted {
                ($0.dateFinished ?? Date.distantPast) > ($1.dateFinished ?? Date.distantPast)
            }
    }
}

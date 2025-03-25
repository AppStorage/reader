import SwiftUI

struct RecentBooks: View {
    let books: [BookData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Recently Finished Books")
            
            let recentBooks = BookStatisticsService.getRecentlyFinishedBooks(from: books, limit: 5)
            
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
                EmptyStateView(
                    type: .chart,
                    isCompact: true,
                    icon: "book.closed",
                    titleOverride: "No recently finished books"
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
}

// MARK: - Recent Book Row
private struct RecentBookRow: View {
    let book: BookData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("by \(book.author)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let finishedDate = book.dateFinished {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(DateFormatterUtils.formatDate(finishedDate))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    if let genre = book.genre, !genre.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if let startDate = book.dateStarted, let finishedDate = book.dateFinished,
               let durationText = BookStatisticsService.readingDurationString(start: startDate, end: finishedDate) {
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(durationText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}


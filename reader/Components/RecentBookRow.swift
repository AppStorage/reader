import SwiftUI

struct RecentBookRow: View {
    let book: BookData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.accentColor.opacity(0.9))
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
                    
                    if let dateFinished = book.dateFinished {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(dateFinished))
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
            
            if let dateStarted = book.dateStarted, let dateFinished = book.dateFinished {
                let days = Calendar.current.dateComponents([.day], from: dateStarted, to: dateFinished).day ?? 0
                if days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(days) day\(days == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

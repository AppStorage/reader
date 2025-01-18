import SwiftUI
import SwiftData

struct StatusSection: View {
    let book: BookData
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status Display
            HStack(spacing: 8) {
                Text("Status:")
                    .font(.headline)
                
                Label {
                    Text(book.status.displayText)
                        .font(.subheadline)
                        .bold()
                } icon: {
                    Image(systemName: book.status.iconName)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(height: 30)
                .background(book.status.statusColor.opacity(0.2))
                .foregroundColor(book.status.statusColor)
                .clipShape(Capsule())
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            // Date Information
            if let dateStarted = book.dateStarted {
                StatusSection.dateTextView(label: "Date Started", date: dateStarted)
            }
            
            if let dateFinished = book.dateFinished {
                StatusSection.dateTextView(label: "Date Finished", date: dateFinished)
            }
        }
    }
}

// MARK: Helpers
extension StatusSection {
    // Display
    static func dateTextView(label: String, date: Date) -> some View {
        Text("\(label): \(formatDate(date))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatter.cachedMediumFormatter.string(from: date)
    }
    
    // Handlers
    static func handleStatusChange(for book: BookData, to newStatus: ReadingStatus, modelContext: ModelContext) {
        DispatchQueue.main.async {
            updateBookDates(for: book, newStatus: newStatus)
            saveBookStatusChange(for: book, modelContext: modelContext)
        }
    }
    
    static func updateBookDates(for book: BookData, newStatus: ReadingStatus) {
        switch newStatus {
        case .unread:
            resetBookDates(for: book)
        case .reading:
            startReading(for: book)
        case .read:
            finishReading(for: book)
        case .deleted:
            resetBookDates(for: book)
        }
    }
    
    static func resetBookDates(for book: BookData) {
        book.dateStarted = nil
        book.dateFinished = nil
    }
    
    static func startReading(for book: BookData) {
        book.dateStarted = book.dateStarted ?? Date()
        book.dateFinished = nil
    }
    
    static func finishReading(for book: BookData) {
        if book.dateStarted == nil {
            book.dateStarted = Date()
        }
        book.dateFinished = Date()
    }
    
    static func saveBookStatusChange(for book: BookData, modelContext: ModelContext) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            do {
                try await MainActor.run {
                    try modelContext.save()
                    print("Book status change saved successfully.")
                }
            } catch {
                print("Failed to save book status change: \(error)")
            }
        }
    }
}

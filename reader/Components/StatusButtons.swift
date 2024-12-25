import SwiftUI
import SwiftData

struct StatusButtons: View {
    let book: BookData
    let updateStatus: (ReadingStatus) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            statusButton(for: .unread, icon: "book.closed", label: "Mark as Unread")
            statusButton(for: .reading, icon: "book", label: "Mark as Reading")
            statusButton(for: .read, icon: "checkmark.circle", label: "Mark as Read")
        }
    }
    
    private func statusButton(for status: ReadingStatus, icon: String, label: String) -> some View {
        Button(action: {
            updateStatus(status)
        }) {
            Image(systemName: icon)
        }
        .help(label)
        .accessibilityLabel(label)
    }
    
    // MARK: Helpers
    static func handleStatusChange(for book: BookData, newStatus: ReadingStatus) {
        if newStatus == .unread {
            book.dateStarted = nil
            book.dateFinished = nil
        } else if newStatus == .reading {
            book.dateStarted = book.dateStarted ?? Date()
            book.dateFinished = nil
        } else if newStatus == .read {
            if book.dateStarted == nil {
                book.dateStarted = Date()
            }
            book.dateFinished = Date()
        }
    }
    
    static func saveChanges(_ book: BookData, modelContext: ModelContext) {
        do {
            try modelContext.save()
            print("Status updated successfully")
        } catch {
            print("Failed to save status change: \(error)")
        }
    }
}

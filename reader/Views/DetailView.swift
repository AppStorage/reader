import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var book: BookData
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var newQuote: String = ""
    @State private var newNote: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                bookDetailsSection
                bookStatusSection
                bookDateInfoSection
                Divider()
                tagsSection
                Divider()
                quotesSection
                Divider()
                notesSection
            }
            .padding()
        }
    }
    
    // MARK: - Details Section
    private var bookDetailsSection: some View {
        DetailsSection(
            title: .constant(book.title),
            author: .constant(book.author),
            genre: .constant(book.genre ?? ""),
            series: .constant(book.series ?? ""),
            isbn: .constant(book.isbn ?? ""),
            publisher: .constant(book.publisher ?? ""),
            formattedDate: .constant(formatDate(book.published)),
            description: Binding(
                get: { sanitizeDescription(book.bookDescription) ?? "" },
                set: { newDescription in
                    book.bookDescription = sanitizeDescription(newDescription)
                }
            )
        )
    }
    
    // MARK: - Status Section
    private var bookStatusSection: some View {
        StatusSection(
            status: Binding<ReadingStatus>(
                get: { book.status },
                set: { newStatus in
                    book.status = newStatus
                    handleStatusChange(newStatus)
                }
            ),
            statusColor: statusColor(for: book.status)
        )
    }
    
    private var bookDateInfoSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let dateStarted = book.dateStarted {
                dateTextView(label: "Date Started", date: dateStarted)
            }
            
            if let dateFinished = book.dateFinished {
                dateTextView(label: "Date Finished", date: dateFinished)
            }
        }
    }
    
    private func dateTextView(label: String, date: Date) -> some View {
        Text("\(label): \(formatDate(date))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        TagsSection(book: book)
    }
    
    // MARK: - Quotes Section
    private var quotesSection: some View {
        QuotesSection(
            book: book,
            newQuote: $newQuote,
            modelContext: modelContext
        )
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        NotesSection(
            book: book,
            newNote: $newNote,
            modelContext: modelContext
        )
    }
    
    // MARK: - Helper Functions
    private func handleStatusChange(_ newStatus: ReadingStatus) {
        DispatchQueue.main.async {
            updateBookDates(for: newStatus)
            saveBookStatusChange()
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .unread: return .gray
        case .reading: return .blue
        case .read: return .green
        case .deleted: return .red
        }
    }
    
    private func updateBookDates(for newStatus: ReadingStatus) {
        switch newStatus {
        case .unread:
            resetBookDates()
        case .reading:
            startReading()
        case .read:
            finishReading()
        case .deleted:
            resetBookDates()
        }
    }
    
    private func resetBookDates() {
        book.dateStarted = nil
        book.dateFinished = nil
    }
    
    private func startReading() {
        book.dateStarted = book.dateStarted ?? Date()
        book.dateFinished = nil
    }
    
    private func finishReading() {
        if book.dateStarted == nil {
            book.dateStarted = Date()
        }
        book.dateFinished = Date()
    }
    
    private func saveBookStatusChange() {
        do {
            try modelContext.save()
            print("Book status change saved successfully.")
        } catch {
            print("Failed to save book status change: \(error)")
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date)
    }
}

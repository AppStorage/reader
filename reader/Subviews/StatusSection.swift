import SwiftUI
import SwiftData

struct StatusSection: View {
    @Bindable var book: BookData
    let modelContext: ModelContext
    
    @State private var isEditingStartDate = false
    @State private var isEditingFinishDate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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
                .background(book.status.statusColor.opacity(0.2))
                .foregroundColor(book.status.statusColor)
                .clipShape(Capsule())
                
                Spacer()
            }
            .padding(.bottom, 6)
            
            DateEditorView(label: "Date Started", date: $book.dateStarted, isEditing: $isEditingStartDate)
            DateEditorView(label: "Date Finished", date: $book.dateFinished, isEditing: $isEditingFinishDate)
        }
        .padding(.vertical, 10)
        .onChange(of: [book.dateStarted, book.dateFinished]) { validateDates() }
    }
    
    private func validateDates() {
        if let start = book.dateStarted, let finish = book.dateFinished, finish < start {
            book.dateFinished = start
        }
    }
}

struct DateEditorView: View {
    let label: String
    @Binding var date: Date?
    @Binding var isEditing: Bool
    @State private var tempDate: Date? = nil
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.secondary)
            
            if let unwrappedDate = date {
                if isEditing {
                    DatePicker("", selection: Binding(
                        get: { tempDate ?? unwrappedDate },
                        set: { newDate in tempDate = newDate }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                    
                    Button(action: {
                        date = tempDate
                        isEditing = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        date = nil
                        isEditing = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    
                } else {
                    HStack {
                        Text(StatusSection.formatDate(unwrappedDate))
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            tempDate = date
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                }
            } else {
                Button("Add Date") {
                    tempDate = Date()
                    date = tempDate
                    isEditing = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

extension StatusSection {
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatter.cachedMediumFormatter.string(from: date)
    }
    
    static func handleStatusChange(for book: BookData, to newStatus: ReadingStatus, modelContext: ModelContext) {
        DispatchQueue.main.async {
            updateBookDates(for: book, newStatus: newStatus)
            saveBookStatusChange(for: book, modelContext: modelContext)
        }
    }
    
    static func updateBookDates(for book: BookData, newStatus: ReadingStatus) {
        switch newStatus {
        case .unread, .deleted:
            resetBookDates(for: book)
        case .reading:
            startReading(for: book)
        case .read:
            finishReading(for: book)
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

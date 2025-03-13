import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var book: BookData
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var dataManager: DataManager
    
    @Environment(\.modelContext) var modelContext
    
    @State private var newQuote: String = ""
    @State private var newNote: String = ""
    @State private var descriptionText: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var currentStatus: ReadingStatus
    @State private var isEditingDetails = false
    
    init(book: BookData) {
        self.book = book
        _currentStatus = State(initialValue: book.status)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                bookDetailsSection
                StatusSection(book: book, modelContext: modelContext)
                Divider()
                tagsSection
                Divider()
                quotesSection
                Divider()
                notesSection
            }
            .padding()
        }
        .onAppear {
            currentStatus = book.status
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                StatusButtons(books: [book], dataManager: dataManager)
            }
            ToolbarItem(placement: .automatic) {
                Spacer()
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isEditingDetails = true
                }) {
                    Label("Edit", systemImage: "square.and.pencil")
                        .help("Edit Book Details")
                        .accessibilityLabel("Edit Book Details")
                }
            }
            ToolbarItem(placement: .automatic) {
                BookActionButton(books: [book], dataManager: dataManager)
            }
            ToolbarItem(placement: .automatic) {
                QuoteShareButton(book: book)
            }
        }
        .sheet(isPresented: $isEditingDetails) {
            EditBookDetails(book: book)
        }
    }
    
    private var bookDetailsSection: some View {
        DetailsSection(
            title: book.title,
            author: book.author,
            genre: book.genre ?? "",
            series: book.series ?? "",
            isbn: book.isbn ?? "",
            publisher: book.publisher ?? "",
            formattedDate: formatDate(book.published),
            description: sanitizeDescription(book.bookDescription) ?? ""
        )
    }
    
    private func dateTextView(label: String, date: Date) -> some View {
        Text("\(label): \(formatDate(date))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var tagsSection: some View {
        TagsSection(book: book)
    }
    
    private var quotesSection: some View {
        QuotesSection(
            book: book,
            newQuote: $newQuote,
            modelContext: modelContext
        )
    }
    
    private var notesSection: some View {
        NotesSection(
            book: book,
            newNote: $newNote,
            modelContext: modelContext
        )
    }
    
    // MARK: Helpers
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatterUtils.cachedMediumFormatter.string(from: date)
    }
}

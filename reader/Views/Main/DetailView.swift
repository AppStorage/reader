import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var book: BookData
    
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var overlayManager: OverlayManager
    
    @State private var newNote: String = ""
    @State private var newQuote: String = ""
    @State private var isEditingDetails = false
    @State private var descriptionText: String = ""
    @State private var saveTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    bookDetailsSection
                    StatusSection(book: book)
                }
                .modifier(SectionCard())
                
                tagsSection
                    .modifier(SectionCard())
                
                quotesSection
                    .modifier(SectionCard())
                
                notesSection
                    .modifier(SectionCard())
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                StatusButtons(books: [book], dataManager: dataManager)
                
                Spacer()
                
                Button(action: {
                    isEditingDetails = true
                }) {
                    Label("Edit", systemImage: "square.and.pencil")
                        .help("Edit Book Details")
                        .accessibilityLabel("Edit Book Details")
                }
                
                BookActionButton(books: [book], dataManager: dataManager)
                QuoteShareButton(book: book)
            }
        }
        .sheet(isPresented: $isEditingDetails) {
            EditBookDetailsSheet(book: book)
        }
    }
    
    // MARK: - Book Info
    private var bookDetailsSection: some View {
        let descriptionExpanded = viewModel.collapseBinding(for: .description, bookId: book.id)
        
        return DetailsSection(
            title: book.title,
            author: book.author,
            rating: book.rating,
            genre: book.genre ?? "",
            series: book.series ?? "",
            isbn: book.isbn ?? "",
            publisher: book.publisher ?? "",
            formattedDate: formatDate(book.published),
            description: sanitizeDescription(book.bookDescription) ?? "",
            canRate: book.status == .read,
            showFullDescription: descriptionExpanded,
            onRatingChanged: { newRating in
                let loadingMessage = newRating == 0 ? "Removing rating..." : "Updating rating..."
                overlayManager.showLoading(message: loadingMessage)
                let _ = viewModel.updateBookRating(for: book, to: newRating)
                    .sink { _ in
                        overlayManager.hideOverlay()
                        let toastMessage = newRating == 0 ? "Rating removed" : "Rating updated"
                        overlayManager.showToast(message: toastMessage)
                    }
            }
        )
    }
    
    // MARK: - Date Start/Finish
    private func dateTextView(label: String, date: Date) -> some View {
        Text("\(label): \(formatDate(date))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    // MARK: - Tags
    private var tagsSection: some View {
        TagsSection(book: book)
    }
    
    // MARK: - Quotes
    private var quotesSection: some View {
        QuotesSection(book: book, newQuote: $newQuote)
    }
    
    // MARK: - Notes
    private var notesSection: some View {
        NotesSection(book: book, newNote: $newNote)
    }
    
    // MARK: Helpers
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return DateFormatterUtils.cachedMediumFormatter.string(from: date)
    }
}

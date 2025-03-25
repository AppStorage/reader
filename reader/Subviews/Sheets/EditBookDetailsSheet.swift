import SwiftUI
import Combine

struct EditBookDetailsSheet: View {
    @Bindable var book: BookData
    
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var overlayManager: OverlayManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var author: String
    @State private var genre: String
    @State private var series: String
    @State private var isbn: String
    @State private var publisher: String
    @State private var publishedDate: Date?
    @State private var description: String
    @State private var validationErrors: [Field: String] = [:]
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var cancelable: AnyCancellable?
    
    @FocusState private var focusedField: Field?
    
    init(book: BookData) {
        self.book = book
        
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _genre = State(initialValue: book.genre ?? "")
        _series = State(initialValue: book.series ?? "")
        _isbn = State(initialValue: book.isbn ?? "")
        _publisher = State(initialValue: book.publisher ?? "")
        _publishedDate = State(initialValue: book.published)
        _description = State(initialValue: book.bookDescription ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            header
            
            Divider()
                .opacity(0.25)
            bookForm
            
            Divider()
                .opacity(0.25)
            
            actionButtons
        }
        .frame(width: 450)
        .padding(24)
        .background(Color(.windowBackgroundColor))
        .disabled(overlayManager.isShowingOverlay())
        .alert("Invalid Data", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {
                if let field = validationErrors.keys.first {
                    focusedField = field
                }
            }
        } message: {
            Text(validationMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Edit Book Details")
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Spacer()
            Label("Edit Book Details", systemImage: "square.and.pencil")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
    }
    
    // MARK: - Book Form
    private var bookForm: some View {
        BookFormView(
            title: $title,
            author: $author,
            genre: $genre,
            series: $series,
            isbn: $isbn,
            publisher: $publisher,
            publishedDate: $publishedDate,
            description: $description,
            validationErrors: $validationErrors,
            showDescriptionField: true,
            focusedField: $focusedField
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack {
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Cancel editing")
            
            Button(action: saveChanges) {
                HStack {
                    Text("Save")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(overlayManager.isShowingOverlay() || title.isEmpty || author.isEmpty)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("Save book details")
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Validation
    private func validateFields() -> Bool {
        validationErrors = BookFormView.validateFields(
            title: title,
            author: author,
            isbn: isbn
        )
        
        if !validationErrors.isEmpty {
            let firstError = validationErrors.values.first ?? "Please fix the validation errors"
            validationMessage = firstError
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        if !validateFields() {
            return
        }
        
        overlayManager.showLoading(
            message: "Saving book details...",
            onCancel: {
                self.cancelable?.cancel()
            }
        )
        
        // String Cleanup
        let cleanTitle = BookFormView.cleanField(title)
        let cleanAuthor = BookFormView.cleanField(author)
        let cleanGenre = BookFormView.cleanOptionalField(genre)
        let cleanSeries = BookFormView.cleanOptionalField(series)
        let cleanISBN = BookFormView.formatISBN(isbn).isEmpty ? nil : BookFormView.formatISBN(isbn)
        let cleanPublisher = BookFormView.cleanOptionalField(publisher)
        let cleanDescription = BookFormView.cleanOptionalField(description)
        
        cancelable = dataManager.updateBookDetails(
            book: book,
            title: cleanTitle,
            author: cleanAuthor,
            genre: cleanGenre,
            series: cleanSeries,
            isbn: cleanISBN,
            publisher: cleanPublisher,
            publishedDate: publishedDate,
            description: cleanDescription
        )
        .delay(for: .milliseconds(300), scheduler: RunLoop.main)
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.overlayManager.hideOverlay()
                    
                    self.validationMessage = "Failed to save: \(error.localizedDescription)"
                    self.showValidationAlert = true
                } else {
                    self.overlayManager.showToast(message: "Book details saved successfully")
                    
                    // Dismiss after a short delay
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                        self.dismiss()
                    }
                }
            },
            receiveValue: { _ in }
        )
    }
}

import SwiftUI

struct AddView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var form = BookForm()
    @State private var searchResults: [BookTransferData] = []
    @State private var selectedBook: BookTransferData? = nil
    @State private var isLoading = false
    @State private var isSheetPresented = false
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                header
                Divider()
                formFields
                Divider()
                actionButtons
            }
            .frame(width: 450)
            .padding()
            .onAppear {
                if let window = NSApp.windows.first(where: { $0.title == "Add Book" }) {
                    window.styleMask.remove(.miniaturizable)
                    window.canHide = false
                }
            }
            .onDisappear(perform: resetForm)
            .sheet(isPresented: $isSheetPresented) {
                SelectEditionSheet(
                    selectedBook: $selectedBook,
                    addBook: { book in
                        addBook(book)
                        isSheetPresented = false
                        // Closes Add Book window
                        if let window = NSApp.windows.first(where: { $0.title == "Add Book" }) {
                            window.close()
                        }
                    },
                    cancel: {
                        isSheetPresented = false
                    },
                    searchResults: searchResults
                )
            }
            
            if isLoading {
                loadingView
            }
        }
    }
    
    private func resetForm() {
        form = BookForm()
    }
    
    private var header: some View {
        HStack {
            Spacer()
            Label("Add New Book", systemImage: "book.fill")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title (required)
            fieldRow(label: "Title", placeholder: "Enter book title", text: $form.title, field: .title, required: true)
            
            // Author (required)
            fieldRow(label: "Author", placeholder: "Enter author name", text: $form.author, field: .author, required: true)
            
            // Optional fields
            fieldRow(label: "Genre", placeholder: "Enter genre", text: $form.genre, field: .genre)
            fieldRow(label: "Series", placeholder: "Enter series name", text: $form.series, field: .series)
            
            // ISBN with Validation
            fieldRow(label: "ISBN", placeholder: "Enter ISBN", text: $form.isbn, field: .isbn)
                .onSubmit { form.isbn = form.isbn.filter { $0.isNumber } }
            
            fieldRow(label: "Publisher", placeholder: "Enter publisher name", text: $form.publisher, field: .publisher)
            
            // Published Date
            dateField(label: "Published Date", date: $form.published)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            Button("Fetch Book") {
                fetchAndShowSheet()
            }
            .buttonStyle(.borderedProminent)
            .disabled(form.title.isEmpty || form.author.isEmpty)
            
            Button("Add Book") {
                addManualBook()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
    
    private func fieldRow(label: String, placeholder: String, text: Binding<String>, field: Field, required: Bool = false) -> some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 0) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 120, alignment: .leading)
            
            TextField(placeholder, text: text)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(focusedField == field ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1.5)
                )
                .textFieldStyle(PlainTextFieldStyle())
                .focused($focusedField, equals: field)
        }
    }
    
    private func dateField(label: String, date: Binding<Date?>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.body)
                .frame(width: 120, alignment: .leading)
            
            if let bindingDate = date.wrappedValue {
                HStack {
                    DatePicker("", selection: Binding(
                        get: { bindingDate },
                        set: { date.wrappedValue = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    
                    Button(action: { date.wrappedValue = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            } else {
                Button("Add Date") {
                    date.wrappedValue = Date()
                    focusedField = .published
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func fetchAndShowSheet() {
        Task {
            isLoading = true
            
            let results = await dataManager.fetchBookData(
                title: form.title,
                author: form.author,
                isbn: form.isbn.isEmpty ? nil : form.isbn
            )
            
            isLoading = false
            
            if results.isEmpty {
                appState.showNoResults()
            } else {
                searchResults = results
                isSheetPresented = true
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            
            ProgressView("Fetching books...")
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
    }
    
    private func addBook(_ bookTransferData: BookTransferData) {
        let book = BookData(
            title: bookTransferData.title,
            author: bookTransferData.author,
            published: bookTransferData.published,
            publisher: bookTransferData.publisher,
            genre: bookTransferData.genre,
            series: bookTransferData.series,
            isbn: bookTransferData.isbn,
            bookDescription: bookTransferData.bookDescription,
            status: bookTransferData.status,
            quotes: bookTransferData.quotes,
            notes: bookTransferData.notes,
            tags: bookTransferData.tags
        )
        dataManager.addBook(book: book)
    }
    
    private func addManualBook() {
        let manualBook = BookData(
            title: form.title,
            author: form.author,
            published: form.published,
            publisher: form.publisher,
            genre: form.genre,
            series: form.series,
            isbn: form.isbn,
            bookDescription: form.description
        )
        dataManager.addBook(book: manualBook)
        dismiss()
    }
    
    private func formattedDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct BookForm {
    var title = ""
    var author = ""
    var genre = ""
    var series = ""
    var isbn = ""
    var publisher = ""
    var published: Date? = nil
    var description = ""
}

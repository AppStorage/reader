import SwiftUI

struct AddView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var series = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var published: Date? = nil
    @State private var bookDescription = ""
    
    @FocusState private var focusedField: Field?

    var body: some View {
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
    }
    
    private func resetForm() {
        title = ""
        author = ""
        genre = ""
        series = ""
        isbn = ""
        publisher = ""
        published = nil
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
            fieldRow(label: "Title ", placeholder: "Enter book title", text: $title, field: .title, required: true)
            fieldRow(label: "Author ", placeholder: "Enter author name", text: $author, field: .author, required: true)
            fieldRow(label: "Genre", placeholder: "Enter genre", text: $genre, field: .genre)
            fieldRow(label: "Series", placeholder: "Enter series name", text: $series, field: .series)
            fieldRow(label: "ISBN", placeholder: "Enter ISBN", text: $isbn, field: .isbn)
                .onChange(of: isbn) {
                    isbn = isbn.filter { $0.isNumber }
                }
            fieldRow(label: "Publisher", placeholder: "Enter publisher name", text: $publisher, field: .publisher)

            dateField(label: "Published Date", date: $published)
        }
    }

    private var actionButtons: some View {
        HStack {
            Spacer()
            Button("Add Book") {
                fetchAndAddBook()
            }
            .buttonStyle(.borderedProminent)
            .disabled(title.isEmpty || author.isEmpty)
            Spacer()
        }
        .padding(.bottom)
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
                        .stroke(focusedField == field ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 2)
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
                HStack(spacing: 4) {
                    DatePicker("", selection: Binding(
                        get: { bindingDate },
                        set: { date.wrappedValue = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .focused($focusedField, equals: .published)
                    
                    Button(action: { date.wrappedValue = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear")
                    .help("Clear")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .fixedSize(horizontal: true, vertical: false)
            } else {
                Button("Add Date") {
                    date.wrappedValue = Date()
                    focusedField = .published
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func fetchAndAddBook() {
        let capturedTitle = title
        let capturedAuthor = author
        let capturedGenre = genre
        let capturedSeries = series
        let capturedIsbn = isbn
        let capturedPublisher = publisher
        let capturedDescription = bookDescription

        Task {
            let fetchedBook = await dataManager.fetchBookData(
                title: capturedTitle,
                author: capturedAuthor,
                publishedDate: published != nil ? DateFormatter().string(from: published!) : nil
            )

            await MainActor.run {
                let finalPublished = fetchedBook?.published ?? published

                if let book = fetchedBook {
                    dataManager.addBook(
                        title: book.title,
                        author: book.author,
                        genre: book.genre ?? capturedGenre,
                        series: book.series ?? capturedSeries,
                        isbn: book.isbn ?? capturedIsbn,
                        publisher: book.publisher ?? capturedPublisher,
                        published: finalPublished,
                        description: book.bookDescription ?? capturedDescription
                    )
                } else {
                    dataManager.addBook(
                        title: capturedTitle,
                        author: capturedAuthor,
                        genre: capturedGenre,
                        series: capturedSeries,
                        isbn: capturedIsbn,
                        publisher: capturedPublisher,
                        published: finalPublished,
                        description: capturedDescription
                    )
                }
                dismiss()
            }
        }
    }
}

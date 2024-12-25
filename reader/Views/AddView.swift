import SwiftUI

struct AddView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var form = BookForm()
    
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
            Button("Add Book") {
                fetchAndAddBook()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddBook) // Use a reusable computed property
            Spacer()
        }
        .padding(.bottom)
    }
    
    private var canAddBook: Bool {
        !form.title.isEmpty && !form.author.isEmpty
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
        Task {
            // Fetch book data asynchronously
            let fetchedBook = await dataManager.fetchBookData(
                title: form.title,
                author: form.author,
                isbn: form.isbn
            )

            // Prepare book data (fallback to manual entry if fetch fails)
            let finalBook = fetchedBook ?? BookData(
                title: form.title,
                author: form.author,
                published: form.published,
                publisher: form.publisher,
                genre: form.genre,
                series: form.series,
                isbn: form.isbn,
                bookDescription: form.description
            )

            // Add the book and dismiss the view
            await MainActor.run {
                dataManager.addBook(book: finalBook)
                dismiss()
            }
        }
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

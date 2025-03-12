import SwiftUI
import SwiftData

struct EditBookDetails: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: BookData
    
    @State private var title: String
    @State private var author: String
    @State private var genre: String
    @State private var series: String
    @State private var isbn: String
    @State private var publisher: String
    @State private var publishedDate: Date?
    @State private var description: String
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
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
            .alert("Invalid Data", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Spacer()
            Label("Edit Book Details", systemImage: "square.and.pencil")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldRow(label: "Title", placeholder: "Enter book title", text: $title, field: .title, required: true)
            
            fieldRow(label: "Author", placeholder: "Enter author name", text: $author, field: .author, required: true)
            
            fieldRow(label: "Genre", placeholder: "Enter genre", text: $genre, field: .genre)
            fieldRow(label: "Series", placeholder: "Enter series name", text: $series, field: .series)
            
            fieldRow(label: "ISBN", placeholder: "Enter ISBN", text: $isbn, field: .isbn)
                .onSubmit { isbn = isbn.filter { $0.isNumber } }
            
            fieldRow(label: "Publisher", placeholder: "Enter publisher name", text: $publisher, field: .publisher)
            
            dateField(label: "Published Date", date: $publishedDate)
            
            descriptionField
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.body)
                .foregroundColor(.primary)
            
            TextEditor(text: $description)
                .frame(height: 120)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(focusedField == .description ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1.5)
                )
                .focused($focusedField, equals: .description)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Button("Save") {
                saveChanges()
            }
            .buttonStyle(.borderedProminent)
            .disabled(title.isEmpty || author.isEmpty)
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
    
    private func saveChanges() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Title cannot be empty."
            showValidationAlert = true
            return
        }
        
        if author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Author cannot be empty."
            showValidationAlert = true
            return
        }
        
        book.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        book.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        book.genre = genre.isEmpty ? nil : genre
        book.series = series.isEmpty ? nil : series
        book.isbn = isbn.isEmpty ? nil : isbn
        book.publisher = publisher.isEmpty ? nil : publisher
        book.published = publishedDate
        book.bookDescription = description.isEmpty ? nil : description
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving book: \(error)")
            validationMessage = "Failed to save changes: \(error.localizedDescription)"
            showValidationAlert = true
        }
    }
}

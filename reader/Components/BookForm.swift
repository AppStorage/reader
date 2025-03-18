import SwiftUI

// MARK: - Fields
enum Field: Hashable {
    case title
    case author
    case genre
    case series
    case isbn
    case publisher
    case published
    case description
}

// MARK: - Book Form
class BookForm: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var genre = ""
    @Published var series = ""
    @Published var isbn = ""
    @Published var publisher = ""
    @Published var published: Date? = nil
    @Published var description = ""
}

// MARK: - Book Form View
struct BookFormView: View {
    @Binding var title: String
    @Binding var author: String
    @Binding var genre: String
    @Binding var series: String
    @Binding var isbn: String
    @Binding var publisher: String
    @Binding var publishedDate: Date?
    @Binding var description: String
    @Binding var validationErrors: [Field: String]
    
    var showValidationErrors: Bool = true
    var showDescriptionField: Bool = false
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldRow(
                label: "Title",
                placeholder: "Enter book title",
                text: $title,
                field: .title,
                required: true,
                error: showValidationErrors ? validationErrors[.title] : nil
            )
            .accessibilityHint("Required field")
            
            fieldRow(
                label: "Author",
                placeholder: "Enter author name",
                text: $author,
                field: .author,
                required: true,
                error: showValidationErrors ? validationErrors[.author] : nil
            )
            .accessibilityHint("Required field")
            
            fieldRow(
                label: "Genre",
                placeholder: "Enter genre",
                text: $genre,
                field: .genre,
                error: showValidationErrors ? validationErrors[.genre] : nil
            )
            
            fieldRow(
                label: "Series",
                placeholder: "Enter series name",
                text: $series,
                field: .series,
                error: showValidationErrors ? validationErrors[.series] : nil
            )
            
            fieldRow(
                label: "ISBN",
                placeholder: "Enter ISBN",
                text: $isbn,
                field: .isbn,
                error: showValidationErrors ? validationErrors[.isbn] : nil
            )
            .onChange(of: isbn) { _, newValue in
                // Format ISBN on change
                if newValue != newValue.filter({ $0.isNumber || $0.isWhitespace || $0 == "-" }) {
                    isbn = Self.formatISBN(newValue.filter { $0.isNumber })
                }
            }
            
            fieldRow(
                label: "Publisher",
                placeholder: "Enter publisher name",
                text: $publisher,
                field: .publisher,
                error: showValidationErrors ? validationErrors[.publisher] : nil
            )
            
            dateField(
                label: "Published Date",
                date: $publishedDate,
                error: showValidationErrors ? validationErrors[.published] : nil
            )
            
            if showDescriptionField {
                descriptionField
            }
        }
    }
    
    // MARK: - Description Field
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(12)
                    .font(.system(size: 12))
                    .lineSpacing(1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(focusedField.wrappedValue == .description ? Color.accentColor :
                                        (validationErrors[.description] != nil && showValidationErrors ? Color.red : Color(nsColor: .separatorColor)),
                                    lineWidth: 1.5)
                    )
                    .focused(focusedField, equals: .description)
                    .accessibilityLabel("Book description")
                
                if let error = validationErrors[.description], showValidationErrors {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                        .cornerRadius(4)
                        .offset(y: -8)
                        .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Field Row
    private func fieldRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        required: Bool = false,
        error: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
                    .lineSpacing(1.3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(focusedField.wrappedValue == field ? Color.accentColor :
                                        (error != nil ? Color.red : Color(nsColor: .separatorColor)),
                                    lineWidth: 1.5)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused(focusedField, equals: field)
                    .accessibilityLabel(label)
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 120)
                    .transition(.opacity)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }
    
    // MARK: - Date Field
    private func dateField(label: String, date: Binding<Date?>, error: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(width: 120, alignment: .leading)
                
                ZStack(alignment: .leading) {
                    Button("Add Date") {
                        withAnimation {
                            date.wrappedValue = Date()
                        }
                    }
                    .buttonStyle(.bordered)
                    .opacity(date.wrappedValue == nil ? 1 : 0)
                    .disabled(date.wrappedValue != nil)
                    .accessibilityLabel("Add published date")
                    .accessibilityHidden(date.wrappedValue != nil)
                    
                    HStack(spacing: 4) {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { date.wrappedValue ?? Date() },
                                set: { date.wrappedValue = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        
                        Button {
                            withAnimation {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    date.wrappedValue = nil
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear date")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(error != nil ? Color.red : Color(nsColor: .separatorColor), lineWidth: 1.5)
                    )
                    .opacity(date.wrappedValue != nil ? 1 : 0)
                    .disabled(date.wrappedValue == nil)
                    .accessibilityHidden(date.wrappedValue == nil)
                }
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 120)
                    .transition(.opacity)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    // ISBN validation and formatting
    static func isValidISBN(_ isbn: String) -> Bool {
        // Basic validation for ISBN-10 or ISBN-13
        let digits = isbn.filter { $0.isNumber }
        return digits.count == 10 || digits.count == 13
    }
    
    static func formatISBN(_ isbn: String) -> String {
        let digits = isbn.filter { $0.isNumber }
        
        // Format as ISBN-13
        if digits.count == 13 {
            var formatted = ""
            for (index, char) in digits.enumerated() {
                if index == 3 || index == 4 || index == 6 || index == 12 {
                    formatted += "-"
                }
                formatted.append(char)
            }
            return formatted
        }
        
        // Format as ISBN-10
        else if digits.count == 10 {
            var formatted = ""
            for (index, char) in digits.enumerated() {
                if index == 1 || index == 3 || index == 9 {
                    formatted += "-"
                }
                formatted.append(char)
            }
            return formatted
        }
        
        // If not valid ISBN length, return as is
        return digits
    }
    
    // Field Validation
    static func validateFields(
        title: String,
        author: String,
        isbn: String
    ) -> [Field: String] {
        var validationErrors: [Field: String] = [:]
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors[.title] = "Title cannot be empty"
        }
        
        if author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors[.author] = "Author cannot be empty"
        }
        
        if !isbn.isEmpty && !isValidISBN(isbn) {
            validationErrors[.isbn] = "Invalid ISBN format"
        }
        
        return validationErrors
    }
    
    // String Cleanup
    static func cleanField(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func cleanOptionalField(_ value: String) -> String? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

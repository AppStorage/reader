import SwiftUI
import SwiftData

struct QuotesSection: View {
    @Bindable var book: BookData
    @Binding var newQuote: String
    
    @State private var newPageNumber: String = ""
    @State private var isEditing: Bool = false
    @State private var isAddingQuote: Bool = false
    @State private var isCollapsed: Bool = false
    
    @FocusState private var isFocusedOnQuote: Bool
    @FocusState private var isFocusedOnPage: Bool
    
    var modelContext: ModelContext

    // Computed property to work with quotes as an array
    private var quotesArray: [String] {
        book.quotes.components(separatedBy: "|||").filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Collapsible toggle icon
                Button(action: { isCollapsed.toggle() }) {
                    HStack {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.body)
                        Text("Quotes")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation { isEditing.toggle() }
                }
                .buttonStyle(LinkButtonStyle())
                .disabled(book.status == .deleted)
            }
            .padding(.bottom, 4)
            
            // Display quotes if not collapsed
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(quotesArray, id: \.self) { quote in
                        let components = quote.components(separatedBy: " [p. ")
                        let text = components.first ?? quote
                        let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                // Quote text
                                Text("“\(text)”")
                                    .font(.custom("Merriweather-Regular", size: 12, relativeTo: .body))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                // Page number
                                if let page = pageNumber, !page.isEmpty {
                                    Text("p. \(page)")
                                        .font(.custom("Merriweather-Regular", size: 12, relativeTo: .footnote))
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }

                                if isEditing {
                                    Button(action: { withAnimation { removeQuote(quote) } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        
                        if quotesArray.last != quote {
                            Divider().padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.bottom, isEditing ? 6 : 0)
                
                // Add quote button
                if isAddingQuote {
                    addQuoteForm
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button(action: { withAnimation { isAddingQuote = true } }) {
                        Label("Add Quote", systemImage: "plus.circle")
                            .font(.callout)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 6)
                    .disabled(book.status == .deleted)
                }
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.25), value: isEditing)
    }
    
    // MARK: Quote form
    private var addQuoteForm: some View {
        VStack(spacing: 16) {
            // Input fields section
            VStack(spacing: 12) {
                // Quote text input with icon and focus state
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.bubble")                        .frame(width: 20, height: 20)

                    ScrollView {
                        TextEditor(text: $newQuote)
                            .font(.body)
                            .lineSpacing(4)
                            .frame(minHeight: 60, maxHeight: max(120, CGFloat(newQuote.split(separator: "\n").count * 20)))
                            .padding(6)
                            .focused($isFocusedOnQuote)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isFocusedOnQuote ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isFocusedOnQuote)
                            .scrollDisabled(true)
                    }
                    .frame(maxHeight: 120)
                    .scrollIndicators(.hidden)
                }

                // Page number input
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "number")
                        .frame(width: 20, height: 20)

                    TextField("Page no. (e.g., 11 or 11-15)", text: Binding(
                        get: { newPageNumber }, // Proxy's getter accesses the real value
                        set: { newValue in
                            let filteredValue = filterPageNumberInput(newValue)
                            if filteredValue != newPageNumber {
                                newPageNumber = filteredValue // Update only if there's a change
                            }
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(6)
                    .focused($isFocusedOnPage)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFocusedOnPage ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                            
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocusedOnPage)
                }
            }

            // Divider line
            Divider()
                .background(Color(NSColor.separatorColor))
                .frame(height: 1)

            // Action buttons
            HStack {
                Button("Cancel") {
                    withAnimation { resetAddQuoteForm() }
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.secondary)

                Spacer()

                Button("Save") {
                    withAnimation { saveQuote() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .foregroundColor((newQuote.isEmpty || newPageNumber.isEmpty) ? .gray : .white)
                .disabled(newQuote.isEmpty || newPageNumber.isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Actions
    private func saveQuote() {
        let formattedQuote = newPageNumber.isEmpty ? newQuote : "\(newQuote) [p. \(newPageNumber)]"
        addQuote(formattedQuote)
        resetAddQuoteForm()
    }

    private func addQuote(_ quote: String) {
        book.quotes = (quotesArray + [quote]).joined(separator: "|||")
        try? modelContext.save()
    }

    private func removeQuote(_ quote: String) {
        book.quotes = quotesArray.filter { $0 != quote }.joined(separator: "|||")
        try? modelContext.save()
    }

    private func resetAddQuoteForm() {
        newQuote = ""
        newPageNumber = ""
        isAddingQuote = false
    }
    
    private func filterPageNumberInput(_ input: String) -> String {
        // Allow numbers and a single hyphen
        input.filter { $0.isNumber || $0 == "-" }
    }
}

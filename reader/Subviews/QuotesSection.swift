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
    
    private var quotesArray: [String] {
        book.quotes.components(separatedBy: "|||").filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Quotes",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: { isEditing.toggle() },
                isEditingDisabled: book.status == .deleted
            )
            if !isCollapsed {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.25), value: isEditing)
    }
    
    // MARK: Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedQuotesArray, id: \.self) { quote in
                let components = quote.components(separatedBy: " [p. ")
                let text = components.first ?? quote
                let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                
                ItemDisplayRow(
                    text: text,
                    secondaryText: pageNumber.map { "\(PageInputHelper.pagePrefix(for: $0)) \($0)" },
                    isEditing: isEditing,
                    includeQuotes: true,
                    customFont: .custom("Merriweather-Regular", size: 12, relativeTo: .body),
                    onRemove: { removeQuote(quote) }
                )
            }
            if isAddingQuote {
                addQuoteForm
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                addQuoteButton
            }
        }
    }
    
    private var addQuoteButton: some View {
        ItemActionButton(
            label: "Add Quote",
            systemImageName: "plus.circle",
            foregroundColor: .accentColor,
            action: { isAddingQuote = true },
            padding: EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0)
        )
        .disabled(book.status == .deleted)
    }
    
    // MARK: Quote form
    private var addQuoteForm: some View {
        ItemForm(
            text: $newQuote,
            supplementaryField: $newPageNumber,
            textLabel: "Quote Text",
            supplementaryLabel: "Page no. (e.g., 11 or 11-15)",
            iconName: "text.quote",
            onSave: saveQuote,
            onCancel: resetAddQuoteForm
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
    
    private var sortedQuotesArray: [String] {
        quotesArray.sorted { quote1, quote2 in
            let page1 = PageInputHelper.extractPageNumber(from: quote1) ?? Int.max
            let page2 = PageInputHelper.extractPageNumber(from: quote2) ?? Int.max
            return page1 < page2
        }
    }
}

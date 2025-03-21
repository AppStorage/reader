import SwiftUI
import Combine

struct QuotesSection: View {
    @Bindable var book: BookData
    @Binding var newQuote: String
    
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var isEditing: Bool = false
    @State private var isCollapsed: Bool = false
    @State private var localQuotes: [String] = []
    @State private var editQuoteText: String = ""
    @State private var newPageNumber: String = ""
    @State private var editPageNumber: String = ""
    @State private var newAttribution: String = ""
    @State private var isAddingQuote: Bool = false
    @State private var editAttribution: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var editingQuoteId: String? = nil
    @State private static var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isEditing: $isEditing,
                isCollapsed: $isCollapsed,
                title: "Quotes",
                isEditingDisabled: (book.status == .deleted) || (book.quotes.isEmpty),
                onEditToggle: {
                    isEditing.toggle()
                    if !isEditing {
                        editingQuoteId = nil
                    }
                },
                onToggleCollapse: { isCollapsed.toggle() }
            )
            if !isCollapsed {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isEditing)
        .animation(.easeInOut(duration: 0.3), value: editingQuoteId)
        .onChange(of: book.quotes) { loadQuotes() }
        .onChange(of: localQuotes) {
            oldQuotes, newQuotes in if newQuotes.isEmpty { isEditing = false }
        }
        .onAppear { loadQuotes() }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localQuotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(localQuotes, id: \.self) { quote in
                    let (text, pageNumber, attribution) = RowItems.parseFromStorage(quote)
                    
                    RowItems(
                        contentType: .quote,
                        text: text,
                        secondaryText: pageNumber.isEmpty ? nil : pageNumber,
                        attributedText: attribution.isEmpty ? nil : attribution,
                        customFont: .custom("Merriweather Regular", size: 12, relativeTo: .body),
                        mode: editingQuoteId == quote ? .edit : .display,
                        allowEditing: isEditing,
                        isMultiline: true,
                        editText: $editQuoteText,
                        editSecondary: $editPageNumber,
                        editAttribution: $editAttribution,
                        onRemove: { removeQuote(quote) },
                        onEdit: { beginEditingQuote(quote) },
                        onSave: { saveEditedQuote(originalQuote: quote) },
                        onCancel: { cancelEditingQuote() }
                    )
                }
            }
            
            if isAddingQuote && editingQuoteId == nil {
                RowItems(
                    contentType: .quote,
                    mode: .add,
                    isMultiline: true,
                    editText: $newQuote,
                    editSecondary: $newPageNumber,
                    editAttribution: $newAttribution,
                    onSave: saveQuote,
                    onCancel: resetAddQuoteForm
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if editingQuoteId == nil {
                RowItems.ActionButton(
                    label: "Add Quote",
                    systemImageName: "plus.circle",
                    action: { isAddingQuote = true },
                    padding: EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0),
                    isDisabled: book.status == .deleted
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: localQuotes.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: isAddingQuote)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(type: .quotes, isCompact: true)
            .transition(.opacity)
    }
    
    // MARK: Actions
    private func saveQuote() {
        guard !newQuote.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        contentViewModel.addQuote(
            newQuote,
            pageNumber: newPageNumber,
            attribution: newAttribution,
            to: book
        )
        .sink(receiveCompletion: { _ in },
              receiveValue: {
            overlayManager.showToast(message: "Quote added")
            resetAddQuoteForm()
        })
        .store(in: &Self.cancellables)
    }

    private func removeQuote(_ quote: String) {
        contentViewModel.removeQuote(quote, from: book)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                overlayManager.showToast(message: "Quote removed")
            })
            .store(in: &Self.cancellables)
    }
    
    private func beginEditingQuote(_ quote: String) {
        if editingQuoteId != nil {
            cancelEditingQuote()
        }
        
        let (text, pageNumber, attribution) = RowItems.parseFromStorage(quote)
        
        editQuoteText = text
        editPageNumber = pageNumber
        editAttribution = attribution
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingQuoteId = quote
        }
    }
    
    private func saveEditedQuote(originalQuote: String) {
        guard !editQuoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        contentViewModel.updateQuote(
            originalQuote: originalQuote,
            newText: editQuoteText,
            newPageNumber: editPageNumber,
            newAttribution: editAttribution,
            in: book
        )
        .sink(receiveCompletion: { _ in },
              receiveValue: {
            overlayManager.showToast(message: "Quote updated")
            withAnimation(.easeInOut(duration: 0.2)) {
                editingQuoteId = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                editQuoteText = ""
                editPageNumber = ""
                editAttribution = ""
            }
        })
        .store(in: &Self.cancellables)
    }
    
    private func cancelEditingQuote() {
        withAnimation(.easeInOut(duration: 0.2)) {
            editingQuoteId = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            editQuoteText = ""
            editPageNumber = ""
            editAttribution = ""
        }
    }
    
    private func loadQuotes() {
        if localQuotes.count != book.quotes.count || !localQuotes.elementsEqual(book.quotes) {
            localQuotes = book.quotes
        }
    }
    
    private func resetAddQuoteForm() {
        newQuote = ""
        newPageNumber = ""
        newAttribution = ""
        isAddingQuote = false
    }
}

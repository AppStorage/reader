import SwiftUI
import Combine

struct QuotesSection: View {
    @Bindable var book: BookData
    @Binding var newQuote: String
    
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var currentPage: Int = 0
    @State private var isEditing: Bool = false
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
    
    private let pageSize: Int = 5
    
    var isCollapsedBinding: Binding<Bool> {
        contentViewModel.collapseBinding(for: .quotes, bookId: book.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isEditing: $isEditing,
                isCollapsed: isCollapsedBinding,
                title: "Quotes",
                isEditingDisabled: (book.status == .deleted) || (book.quotes.isEmpty),
                onEditToggle: {
                    isEditing.toggle()
                    if !isEditing {
                        editingQuoteId = nil
                    }
                },
                onToggleCollapse: { isCollapsedBinding.wrappedValue.toggle() }
            )
            if !isCollapsedBinding.wrappedValue {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isEditing)
        .animation(.easeInOut(duration: 0.3), value: editingQuoteId)
        .onChange(of: book.id) {
            resetAddQuoteForm()
            cancelEditingQuote()
            isEditing = false
            currentPage = 0
            loadQuotes()
        }
        .onAppear { loadQuotes() }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localQuotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(paginatedQuotes, id: \.self) { quote in
                    let (text, pageNumber, attribution) = RowItems.parseFromStorage(quote)
                    let quoteId = RowItems.hashedIdentifier(for: quote)
                    let isExpanded = contentViewModel.isExpanded(hash: quoteId, for: book.id)
                    let previewLimit = 120
                    let displayText = isExpanded || text.count < previewLimit ? text : String(text.prefix(previewLimit)) + "…"
                    
                    RowItems(
                        contentType: .quote,
                        text: displayText,
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
                    .transition(.opacity)
                    
                    if text.count > previewLimit {
                        ExpandableTextToggle(
                            isExpanded: Binding(
                                get: { isExpanded },
                                set: { _ in
                                    contentViewModel.toggleExpandedState(hash: quoteId, for: book.id)
                                }
                            )
                        )
                    }
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
            
            if localQuotes.count > pageSize {
                PaginationControls(
                    currentPage: currentPage,
                    totalCount: localQuotes.count,
                    pageSize: pageSize,
                    onPrevious: { currentPage = max(currentPage - 1, 0) },
                    onNext: {
                        let maxPage = (localQuotes.count - 1) / pageSize
                        currentPage = min(currentPage + 1, maxPage)
                    }
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
        guard !self.newQuote.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        self.contentViewModel.addQuote(
            self.newQuote,
            pageNumber: self.newPageNumber,
            attribution: self.newAttribution,
            to: self.book
        )
        .sink(receiveCompletion: { _ in },
              receiveValue: {
            self.overlayManager.showToast(message: "Quote added")
            self.resetAddQuoteForm()
            self.loadQuotes()
        })
        .store(in: &Self.cancellables)
    }

    private func removeQuote(_ quote: String) {
        self.contentViewModel.removeQuote(quote, from: self.book)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                self.overlayManager.showToast(message: "Quote removed")

                let quoteIdToRemove = RowItems.hashedIdentifier(for: quote)
                self.localQuotes.removeAll { RowItems.hashedIdentifier(for: $0) == quoteIdToRemove }
            })
            .store(in: &Self.cancellables)
    }
    
    private func beginEditingQuote(_ quote: String) {
        if self.editingQuoteId != nil {
            self.cancelEditingQuote()
        }

        let (text, pageNumber, attribution) = RowItems.parseFromStorage(quote)

        self.editQuoteText = text
        self.editPageNumber = pageNumber
        self.editAttribution = attribution

        withAnimation(.easeInOut(duration: 0.2)) {
            self.editingQuoteId = quote
        }
    }
    
    private func saveEditedQuote(originalQuote: String) {
        guard !self.editQuoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        self.contentViewModel.updateQuote(
            originalQuote: originalQuote,
            newText: self.editQuoteText,
            newPageNumber: self.editPageNumber,
            newAttribution: self.editAttribution,
            in: self.book
        )
        .sink(receiveCompletion: { _ in },
              receiveValue: {
            self.overlayManager.showToast(message: "Quote updated")
            withAnimation(.easeInOut(duration: 0.2)) {
                self.editingQuoteId = nil
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.editQuoteText = ""
                self.editPageNumber = ""
                self.editAttribution = ""
            }
        })
        .store(in: &Self.cancellables)
    }
    
    private func cancelEditingQuote() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.editingQuoteId = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.editQuoteText = ""
            self.editPageNumber = ""
            self.editAttribution = ""
        }
    }
    
    private func loadQuotes() {
        if self.localQuotes.count != self.book.quotes.count || !self.localQuotes.elementsEqual(self.book.quotes) {
            self.localQuotes = self.book.quotes
        }
    }
    
    private func resetAddQuoteForm() {
        self.newQuote = ""
        self.newPageNumber = ""
        self.newAttribution = ""
        self.isAddingQuote = false
    }
    
    // MARK: - Pagination
    private var paginatedQuotes: [String] {
        let startIndex = currentPage * pageSize
        guard startIndex < localQuotes.count else {
            return []
        }
        let endIndex = min(startIndex + pageSize, localQuotes.count)
        return Array(localQuotes[startIndex..<endIndex])
    }

}

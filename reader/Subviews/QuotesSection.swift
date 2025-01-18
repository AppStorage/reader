import SwiftUI
import SwiftData

struct QuotesSection: View {
    @Bindable var book: BookData
    @Binding var newQuote: String
    
    @State private var newPageNumber: String = ""
    @State private var newAttribution: String = ""
    @State private var isEditing: Bool = false
    @State private var isAddingQuote: Bool = false
    @State private var isCollapsed: Bool = false
    @State private var localQuotes: [String] = []
    @State private var saveTask: Task<Void, Never>?
    
    var modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Quotes",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: { isEditing.toggle() },
                isEditingDisabled: book.status == .deleted || (book.quotes.isEmpty)
            )
            if !isCollapsed {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.25), value: isEditing)
        .onChange(of: localQuotes) { oldQuotes, newQuotes in
            if newQuotes.isEmpty {
                isEditing = false
            }
        }
        .onChange(of: book.id) {
            loadQuotes()
        }
        .onAppear {
            loadQuotes()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localQuotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(localQuotes, id: \..self) { quote in
                    let components = quote.components(separatedBy: " [p. ")
                    let textPart = components.first ?? quote
                    let pageAndAttribution = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                    
                    let pageComponents = pageAndAttribution?.components(separatedBy: " — ")
                    let pageNumber = pageComponents?.first
                    let attribution = pageComponents?.count ?? 0 > 1 ? pageComponents?.last : nil
                    
                    ItemDisplayRow(
                        text: textPart,
                        secondaryText: pageNumber,
                        attributedText: attribution,
                        isEditing: isEditing,
                        includeQuotes: true,
                        customFont: .custom("Merriweather-Regular", size: 12, relativeTo: .body),
                        onRemove: { removeQuote(quote) }
                    )
                }
            }
            
            if isAddingQuote {
                addQuoteForm
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                addQuoteButton
            }
        }
        .animation(.easeInOut(duration: 0.25), value: localQuotes.isEmpty)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "quote.opening")
                .foregroundColor(.secondary)
                .imageScale(.large)
                .padding(.bottom, 8)
            Text("No quotes exist here yet.")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
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
    
    private var addQuoteForm: some View {
        ItemForm(
            text: $newQuote,
            supplementaryField: Binding<String?>(
                get: { newPageNumber },
                set: { newPageNumber = $0 ?? "" }
            ),
            attributedField: Binding<String?>(
                get: { newAttribution },
                set: { newAttribution = $0 ?? "" }
            ),
            textLabel: "Enter a quote here",
            iconName: "text.quote",
            onSave: saveQuote,
            onCancel: resetAddQuoteForm,
            isSingleLine: false
        )
    }
    
    // MARK: Actions
    private func saveQuote() {
        guard !newQuote.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let pagePart = newPageNumber.isEmpty ? "" : "[p. \(newPageNumber)]"
        let attributionPart = newAttribution.isEmpty ? "" : " — \(newAttribution)"
        let formattedQuote = "\(newQuote) \(pagePart)\(attributionPart)".trimmingCharacters(in: .whitespaces)
        addQuote(formattedQuote)
        resetAddQuoteForm()
    }
    
    private func addQuote(_ quote: String) {
        localQuotes.append(quote)
        saveQuotes()
    }
    
    private func removeQuote(_ quote: String) {
        localQuotes.removeAll { $0 == quote }
        saveQuotes()
    }
    
    private func saveQuotes() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                book.quotes = localQuotes
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save quotes: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadQuotes() {
        localQuotes = book.quotes
    }
    
    private func resetAddQuoteForm() {
        newQuote = ""
        newPageNumber = ""
        newAttribution = ""
        isAddingQuote = false
    }
}

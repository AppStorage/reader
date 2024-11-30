import SwiftUI
import SwiftData

struct NotesSection: View {
    @Bindable var book: BookData
    @Binding var newNote: String
    
    @State private var newPageNumber: String = ""
    @State private var isEditing: Bool = false
    @State private var isAddingNote: Bool = false
    @State private var isCollapsed: Bool = false
    
    @FocusState private var isFocusedOnNote: Bool
    @FocusState private var isFocusedOnPage: Bool
    
    var modelContext: ModelContext
    
    private var notesArray: [String] {
        book.notes.components(separatedBy: "|||").filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Notes",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: { isEditing.toggle() },
                isEditingDisabled: book.status == .deleted || (book.notes.isEmpty)
            )
            if !isCollapsed {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.25), value: isEditing)
        .onChange(of: book.quotes) {
            if notesArray.isEmpty {
                isEditing = false
            }
        }
    }
    
    // MARK: Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if notesArray.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(sortedNotesArray, id: \.self) { note in
                    let components = note.components(separatedBy: " [p. ")
                    let text = components.first ?? note
                    let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                    
                    ItemDisplayRow(
                        text: text,
                        secondaryText: pageNumber.map { "\(PageNumberInput.pagePrefix(for: $0)) \($0)" },
                        isEditing: isEditing,
                        includeQuotes: false,
                        customFont: nil,
                        onRemove: { removeNote(note) }
                    )
                }
            }
            if isAddingNote {
                addNoteForm
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                addNoteButton
            }
        }
        .animation(.easeInOut(duration: 0.25), value: notesArray.isEmpty)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "note")
                .foregroundColor(.secondary)
                .imageScale(.large)
                .padding(.bottom, 8)
            Text("No notes exist here yet.")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
    
    
    private func removeNoteButton(note: String) -> some View {
        ItemActionButton(
            label: nil,
            systemImageName: "minus.circle.fill",
            foregroundColor: .red,
            action: { removeNote(note) },
            padding: nil
        )
        .buttonStyle(BorderlessButtonStyle())
        .transition(.opacity)
    }
    
    private var addNoteButton: some View {
        ItemActionButton(
            label: "Add Note",
            systemImageName: "plus.circle",
            foregroundColor: .accentColor,
            action: { isAddingNote = true },
            padding: EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0)
        )
        .disabled(book.status == .deleted)
    }
    
    // MARK: Note Form
    private var addNoteForm: some View {
        ItemForm(
            text: $newNote,
            supplementaryField: Binding<String?>(
                get: { newPageNumber },
                set: { newPageNumber = $0 ?? "" }
            ),
            textLabel: "Enter a note here",
            iconName: "note.text",
            onSave: saveNote,
            onCancel: resetAddNoteForm,
            isSingleLine: false
        )
    }
    
    // MARK: Actions
    private func saveNote() {
        let formattedNote = newPageNumber.isEmpty ? newNote : "\(newNote) [p. \(newPageNumber)]"
        addNote(formattedNote)
        resetAddNoteForm()
    }
    
    private func addNote(_ note: String) {
        book.notes = (notesArray + [note]).joined(separator: "|||")
        try? modelContext.save()
    }
    
    private func removeNote(_ note: String) {
        book.notes = notesArray.filter { $0 != note }.joined(separator: "|||")
        try? modelContext.save()
    }
    
    private func resetAddNoteForm() {
        newNote = ""
        newPageNumber = ""
        isAddingNote = false
    }
    
    private var sortedNotesArray: [String] {
        notesArray.sorted { note1, note2 in
            let page1 = PageNumberInput.extractPageNumber(from: note1) ?? Int.max
            let page2 = PageNumberInput.extractPageNumber(from: note2) ?? Int.max
            return page1 < page2
        }
    }
}

import SwiftUI
import SwiftData

struct NotesSection: View {
    @Bindable var book: BookData
    @Binding var newNote: String
    
    @State private var newPageNumber: String = ""
    @State private var isEditing: Bool = false
    @State private var isAddingNote: Bool = false
    @State private var isCollapsed: Bool = false
    @State private var localNotes: [String] = []
    @State private var saveTask: Task<Void, Never>?
    
    @FocusState private var isFocusedOnNote: Bool
    @FocusState private var isFocusedOnPage: Bool
    
    var modelContext: ModelContext
    
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
        .onChange(of: localNotes) { oldNotes, newNotes in
            if newNotes.isEmpty {
                isEditing = false
            }
        }
        .onChange(of: book.id) {
            loadNotes()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localNotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(localNotes, id: \..self) { note in
                    let components = note.components(separatedBy: " [p. ")
                    let text = components.first ?? note
                    let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                    
                    ItemDisplayRow(
                        text: text,
                        secondaryText: pageNumber,
                        attributedText: nil,
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
        .animation(.easeInOut(duration: 0.25), value: localNotes.isEmpty)
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
    
    private var addNoteForm: some View {
        ItemForm(
            text: $newNote,
            supplementaryField: Binding<String?>(
                get: { newPageNumber },
                set: { newPageNumber = $0 ?? "" }
            ),
            attributedField: .constant(nil),
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
        localNotes.append(note)
        saveNotes()
    }
    
    private func removeNote(_ note: String) {
        localNotes.removeAll { $0 == note }
        saveNotes()
    }
    
    private func saveNotes() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                book.notes = localNotes
                try? modelContext.save()
            }
        }
    }
    
    private func loadNotes() {
        localNotes = book.notes
    }
    
    private func resetAddNoteForm() {
        newNote = ""
        newPageNumber = ""
        isAddingNote = false
    }
}

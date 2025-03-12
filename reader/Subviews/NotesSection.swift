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
    
    @State private var editingNoteId: String? = nil
    @State private var editNoteText: String = ""
    @State private var editPageNumber: String = ""
    
    var modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Notes",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: {
                    isEditing.toggle()
                    if !isEditing {
                        editingNoteId = nil
                    }
                },
                isEditingDisabled: book.status == .deleted || (book.notes.isEmpty)
            )
            if !isCollapsed {
                content
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isEditing)
        .animation(.easeInOut(duration: 0.3), value: editingNoteId)
        .onChange(of: localNotes) { oldNotes, newNotes in
            if newNotes.isEmpty {
                isEditing = false
            }
        }
        .onChange(of: book.id) {
            loadNotes()
        }
        .onAppear {
            loadNotes()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localNotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(localNotes, id: \.self) { note in
                    let components = note.components(separatedBy: " [p. ")
                    let text = components.first ?? note
                    let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") ?? "" : ""
                    
                    ItemDisplayRow(
                        text: text,
                        secondaryText: pageNumber.isEmpty ? nil : pageNumber,
                        attributedText: nil,
                        isEditing: isEditing,
                        includeQuotes: false,
                        customFont: nil,
                        isEditingThis: editingNoteId == note,
                        editText: $editNoteText,
                        editSecondary: $editPageNumber,
                        editAttribution: .constant(""),
                        onRemove: { removeNote(note) },
                        onEdit: { beginEditingNote(note) },
                        onSave: { saveEditedNote(originalNote: note) },
                        onCancel: { cancelEditingNote() }
                    )
                }
            }
            
            if isAddingNote && editingNoteId == nil {
                addNoteForm
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if editingNoteId == nil {
                addNoteButton
            }
        }
        .animation(.easeInOut(duration: 0.3), value: localNotes.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: isAddingNote)
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
            onCancel: resetAddNoteForm
        )
    }
    
    // MARK: Actions
    private func saveNote() {
        guard !newNote.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formattedNote: String
        if let pageNumber = Int(newPageNumber), pageNumber > 0 {
            formattedNote = "\(newNote) [p. \(pageNumber)]"
        } else {
            formattedNote = newNote
        }
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
    
    private func beginEditingNote(_ note: String) {
        if editingNoteId != nil {
            cancelEditingNote()
        }
        
        let components = note.components(separatedBy: " [p. ")
        let text = components.first ?? note
        let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") ?? "" : ""
        
        editNoteText = text
        editPageNumber = pageNumber
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingNoteId = note
        }
    }
    
    private func saveEditedNote(originalNote: String) {
        guard !editNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let formattedNote: String
        if let pageNumber = Int(editPageNumber), pageNumber > 0 {
            formattedNote = "\(editNoteText) [p. \(pageNumber)]"
        } else {
            formattedNote = editNoteText
        }
        
        if let index = localNotes.firstIndex(of: originalNote) {
            localNotes[index] = formattedNote
            saveNotes()
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingNoteId = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            editNoteText = ""
            editPageNumber = ""
        }
    }
    
    private func cancelEditingNote() {
        withAnimation(.easeInOut(duration: 0.2)) {
            editingNoteId = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            editNoteText = ""
            editPageNumber = ""
        }
    }
    
    private func saveNotes() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                book.notes = localNotes
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save notes: \(error)")
                }
            }
        }
    }
    
    private func loadNotes() {
        if localNotes != book.notes {
            localNotes = book.notes
        }
    }
    
    private func resetAddNoteForm() {
        newNote = ""
        newPageNumber = ""
        isAddingNote = false
    }
}

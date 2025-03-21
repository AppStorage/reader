import SwiftUI
import Combine

struct NotesSection: View {
    @Bindable var book: BookData
    @Binding var newNote: String
    
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var isEditing: Bool = false
    @State private var isCollapsed: Bool = false
    @State private var localNotes: [String] = []
    @State private var editNoteText: String = ""
    @State private var newPageNumber: String = ""
    @State private var isAddingNote: Bool = false
    @State private var editPageNumber: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var editingNoteId: String? = nil
    @State private static var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isEditing: $isEditing,
                isCollapsed: $isCollapsed,
                title: "Notes",
                isEditingDisabled: (book.status == .deleted) || (book.notes.isEmpty),
                onEditToggle: {
                    isEditing.toggle()
                    if !isEditing {
                        editingNoteId = nil
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
        .animation(.easeInOut(duration: 0.3), value: editingNoteId)
        .onChange(of: book.notes) { loadNotes() }
        .onChange(of: localNotes) {
            oldNotes, newNotes in if newNotes.isEmpty { isEditing = false }
        }
        .onAppear { loadNotes() }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localNotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(localNotes, id: \.self) { note in
                    let (text, pageNumber, _) = RowItems.parseFromStorage(note)
                    
                    RowItems(
                        contentType: .note,
                        text: text,
                        secondaryText: pageNumber.isEmpty ? nil : pageNumber,
                        attributedText: nil,
                        mode: editingNoteId == note ? .edit : .display,
                        allowEditing: isEditing,
                        isMultiline: true,
                        editText: $editNoteText,
                        editSecondary: $editPageNumber,
                        onRemove: { removeNote(note) },
                        onEdit: { beginEditingNote(note) },
                        onSave: { saveEditedNote(originalNote: note) },
                        onCancel: { cancelEditingNote() }
                    )
                }
            }
            
            if isAddingNote && editingNoteId == nil {
                RowItems(
                    contentType: .note,
                    mode: .add,
                    isMultiline: true,
                    editText: $newNote,
                    editSecondary: $newPageNumber,
                    onSave: saveNote,
                    onCancel: resetAddNoteForm
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if editingNoteId == nil {
                RowItems.ActionButton(
                    label: "Add Note",
                    systemImageName: "plus.circle",
                    action: { isAddingNote = true },
                    padding: EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0),
                    isDisabled: book.status == .deleted
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: localNotes.isEmpty)
        .animation(.easeInOut(duration: 0.3), value: isAddingNote)
    }
    
    private var emptyStateView: some View {
        EmptyStateView(type: .notes, isCompact: true)
            .transition(.opacity)
    }
    
    // MARK: - Actions
    private func saveNote() {
        guard !newNote.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        contentViewModel.addNote(newNote, pageNumber: newPageNumber, to: book)
            .sink(receiveValue: { _ in
                overlayManager.showToast(message: "Note added")
                self.resetAddNoteForm()
            })
            .store(in: &Self.cancellables)
    }
    
    private func removeNote(_ note: String) {
        contentViewModel.removeNote(note, from: book)
            .sink(receiveValue: { _ in
                overlayManager.showToast(message: "Note removed")
            })
            .store(in: &Self.cancellables)
    }
    
    private func beginEditingNote(_ note: String) {
        if editingNoteId != nil {
            cancelEditingNote()
        }
        
        let (text, pageNumber, _) = RowItems.parseFromStorage(note)
        
        editNoteText = text
        editPageNumber = pageNumber
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingNoteId = note
        }
    }
    
    private func saveEditedNote(originalNote: String) {
        guard !editNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        contentViewModel.updateNote(
            originalNote: originalNote,
            newText: editNoteText,
            newPageNumber: editPageNumber,
            in: book
        )
        .sink(receiveCompletion: { _ in },
              receiveValue: {
            overlayManager.showToast(message: "Note updated")
            withAnimation(.easeInOut(duration: 0.2)) {
                editingNoteId = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                editNoteText = ""
                editPageNumber = ""
            }
        })
        .store(in: &Self.cancellables)
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
    
    private func loadNotes() {
        if localNotes.count != book.notes.count || !localNotes.elementsEqual(book.notes) {
            localNotes = book.notes
        }
    }

    private func resetAddNoteForm() {
        newNote = ""
        newPageNumber = ""
        isAddingNote = false
    }
}

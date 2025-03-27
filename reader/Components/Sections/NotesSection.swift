import SwiftUI
import Combine

struct NotesSection: View {
    @Bindable var book: BookData
    @Binding var newNote: String
    
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var currentPage: Int = 0
    @State private var isEditing: Bool = false
    @State private var localNotes: [String] = []
    @State private var editNoteText: String = ""
    @State private var newPageNumber: String = ""
    @State private var isAddingNote: Bool = false
    @State private var editPageNumber: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var editingNoteId: String? = nil
    
    @State private static var cancellables = Set<AnyCancellable>()
    
    private let pageSize: Int = 5
    
    var isCollapsedBinding: Binding<Bool> {
        contentViewModel.collapseBinding(for: .notes, bookId: book.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isEditing: $isEditing,
                isCollapsed: isCollapsedBinding,
                title: "Notes",
                isEditingDisabled: (book.status == .deleted) || (book.notes.isEmpty),
                onEditToggle: {
                    isEditing.toggle()
                    if !isEditing {
                        editingNoteId = nil
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
        .animation(.easeInOut(duration: 0.3), value: editingNoteId)
        .onChange(of: book.id) {
            resetAddNoteForm()
            cancelEditingNote()
            isEditing = false
            currentPage = 0
            loadNotes()
        }
        .onAppear { loadNotes() }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if localNotes.isEmpty {
                emptyStateView
                    .transition(.opacity)
            } else {
                ForEach(paginatedNotes, id: \.self) { note in
                    let (text, pageNumber, _) = RowItems.parseFromStorage(note)
                    let noteId = RowItems.hashedIdentifier(for: note)
                    let isExpanded = contentViewModel.isExpanded(hash: noteId, for: book.id)
                    let previewLimit = 120
                    let displayText = isExpanded || text.count < previewLimit ? text : String(text.prefix(previewLimit)) + "…"

                    VStack(alignment: .leading, spacing: 4) {
                        RowItems(
                            contentType: .note,
                            text: displayText,
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
                        .transition(.opacity)

                        if text.count > previewLimit {
                            ExpandableTextToggle(
                                isExpanded: Binding(
                                    get: { isExpanded },
                                    set: { _ in
                                        contentViewModel.toggleExpandedState(hash: noteId, for: book.id)
                                    }
                                )
                            )
                        }
                    }
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

            if localNotes.count > pageSize {
                PaginationControls(
                    currentPage: currentPage,
                    totalCount: localNotes.count,
                    pageSize: pageSize,
                    onPrevious: { currentPage = max(currentPage - 1, 0) },
                    onNext: {
                        let maxPage = (localNotes.count - 1) / pageSize
                        currentPage = min(currentPage + 1, maxPage)
                    }
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
                
                let noteIdToRemove = RowItems.hashedIdentifier(for: note)
                localNotes.removeAll { RowItems.hashedIdentifier(for: $0) == noteIdToRemove }
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
    
    // MARK: - Pagination
    private var paginatedNotes: [String] {
        let startIndex = currentPage * pageSize
        guard startIndex < localNotes.count else {
            return []
        }
        let endIndex = min(startIndex + pageSize, localNotes.count)
        return Array(localNotes[startIndex..<endIndex])
    }
}

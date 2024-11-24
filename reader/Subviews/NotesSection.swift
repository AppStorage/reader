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
            HStack {
                // Collapsible toggle icon
                Button(action: { isCollapsed.toggle() }) {
                    HStack {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.body)
                        Text("Notes")
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
            
            // Display notes if not collapsed
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(notesArray, id: \.self) { note in
                        let components = note.components(separatedBy: " [p. ")
                        let text = components.first ?? note
                        let pageNumber = components.count > 1 ? components.last?.replacingOccurrences(of: "]", with: "") : nil
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                // Display the note with a custom font
                                Text(text)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)

                                Spacer()

                                // Page number with system font
                                if let page = pageNumber, !page.isEmpty {
                                    Text("p. \(page)")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }

                                if isEditing {
                                    Button(action: { withAnimation { removeNote(note) } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding(.vertical, 6)

                        if notesArray.last != note {
                            Divider().padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.bottom, isEditing ? 6 : 0)

                if isAddingNote {
                    addNoteForm
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button(action: { withAnimation { isAddingNote = true } }) {
                        Label("Add Note", systemImage: "plus.circle")
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
    
    // MARK: Note Form
    private var addNoteForm: some View {
        VStack(spacing: 16) {
            // Input fields section
            VStack(spacing: 12) {
                // Note text input with icon and focus state
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .frame(width: 20, height: 20)

                    ScrollView {
                        TextEditor(text: $newNote)
                            .font(.body)
                            .lineSpacing(4)
                            .frame(minHeight: 60, maxHeight: max(120, CGFloat(newNote.split(separator: "\n").count * 20)))
                            .padding(6)
                            .focused($isFocusedOnNote)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isFocusedOnNote ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isFocusedOnNote)
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
                    withAnimation { resetAddNoteForm() }
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.secondary)

                Spacer()

                Button("Save") {
                    withAnimation { saveNote() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .foregroundColor((newNote.isEmpty || newPageNumber.isEmpty) ? .gray : .white)
                .disabled(newNote.isEmpty || newPageNumber.isEmpty)
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

    private func filterPageNumberInput(_ input: String) -> String {
        // Allow numbers and a single hyphen
        input.filter { $0.isNumber || $0 == "-" }
    }
}

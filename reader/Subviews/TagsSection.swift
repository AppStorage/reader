import SwiftUI

struct TagsSection: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @Bindable var book: BookData
    
    @State private var isCollapsed: Bool = false
    @State private var isEditing: Bool = false
    @State private var newTag: String = ""
    @State private var isAddingTag: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Tags",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: { isEditing.toggle() },
                isEditingDisabled: (book.tags.isEmpty && !isEditing) || book.status == .deleted
            )
            
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.selectedTags.isEmpty {
                        selectedTagsView
                    }
                    
                    Group {
                        if book.tags.isEmpty {
                            emptyStateView
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            tagGrid
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    if isAddingTag {
                        tagForm
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        addTagButton
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: book.tags.isEmpty)
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
    }
    
    // MARK: - Subviews
    private var selectedTagsView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                HoverableTag(tag: tag, clearAction: { clearTag(tag) })
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "tag.slash.fill")
                .foregroundColor(.secondary)
                .imageScale(.large)
                .padding(.bottom, 8)
            Text("No tags exist here yet.")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
    
    private var tagForm: some View {
        ItemForm(
            text: $newTag,
            supplementaryField: .constant(nil),
            textLabel: "Enter a tag here",
            iconName: "tag",
            onSave: handleAddTag,
            onCancel: { withAnimation { isAddingTag = false } },
            isSingleLine: true
        )
        .onSubmit {
            handleAddTag()
        }
    }
    
    private var tagGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(book.tags, id: \.self) { tag in
                TagChip(tag: tag, isEditing: isEditing, onRemove: { removeTag(tag) })
                    .background(viewModel.selectedTags.contains(tag) ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .onTapGesture { toggleTagSelection(tag) }
            }
        }
    }
    
    private var addTagButton: some View {
        HStack {
            ItemActionButton(
                label: "Add Tag",
                systemImageName: "plus.circle",
                foregroundColor: .accentColor,
                action: { isAddingTag = true },
                padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            )
        }
        .padding(.top, 8)
        .disabled(book.status == .deleted)
    }
    
    // MARK: - Helper Functions
    private func toggleTagSelection(_ tag: String) {
        viewModel.toggleTagSelection(tag)
    }
    
    private func clearTag(_ tag: String) {
        viewModel.clearTag(tag)
    }
    
    private func removeTag(_ tag: String) {
        book.tags.removeAll { $0 == tag }
        viewModel.selectedTags.remove(tag)
    }
    
    private func handleAddTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !book.tags.contains(trimmedTag) else { return }
        book.tags.append(trimmedTag)
        newTag = ""
        withAnimation { isAddingTag = false }
    }
}


extension ContentViewModel {
    // Toggles the selection state of a tag
    func toggleTagSelection(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    // Clears a specific tag from the selectedTags set
    func clearTag(_ tag: String) {
        selectedTags.remove(tag)
    }
}

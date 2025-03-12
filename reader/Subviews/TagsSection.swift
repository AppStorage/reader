import SwiftUI

struct TagsSection: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @Bindable var book: BookData
    
    @State private var isCollapsed: Bool = false
    @State private var isEditing: Bool = false
    @State private var newTag: String = ""
    @State private var isAddingTag: Bool = false
    @State private var localTags: [String]
    
    init(book: BookData) {
        self.book = book
        _localTags = State(initialValue: book.tags)
    }
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isCollapsed: $isCollapsed,
                isEditing: $isEditing,
                title: "Tags",
                onToggleCollapse: { isCollapsed.toggle() },
                onEditToggle: { isEditing.toggle() },
                isEditingDisabled: book.status == .deleted || localTags.isEmpty
            )
            
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.selectedTags.isEmpty {
                        selectedTagsView
                    }
                    
                    Group {
                        if localTags.isEmpty {
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
                            .disabled(book.status == .deleted)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: localTags.isEmpty)
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
        .onChange(of: book.tags) {
            localTags = book.tags
            if localTags.isEmpty {
                isEditing = false
            }
        }
    }
    
    // MARK: Subviews
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
            attributedField: .constant(nil),
            textLabel: "Enter a tag here",
            iconName: "tag",
            onSave: handleAddTag,
            onCancel: { withAnimation { isAddingTag = false } }
        )
        .onSubmit {
            handleAddTag()
        }
    }
    
    private var tagGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(localTags, id: \.self) { tag in
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
    
    // MARK: Helpers
    private func toggleTagSelection(_ tag: String) {
        viewModel.toggleTagSelection(tag)
    }
    
    private func clearTag(_ tag: String) {
        viewModel.clearTag(tag)
    }
    
    private func removeTag(_ tag: String) {
        localTags.removeAll { $0 == tag }
        saveTags()
    }
    
    private func handleAddTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !localTags.contains(trimmedTag) else { return }
        localTags.append(trimmedTag)
        saveTags()
        newTag = ""
        withAnimation { isAddingTag = false }
    }
    
    private func saveTags() {
        book.tags = localTags
    }
    
    private func loadTags() {
        localTags = book.tags
    }
}

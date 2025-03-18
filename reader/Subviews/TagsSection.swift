import SwiftUI
import Combine

struct TagsSection: View {
    @Bindable var book: BookData
    
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var newTag: String = ""
    @State private var localTags: [String]
    @State private var isEditing: Bool = false
    @State private var formWidth: CGFloat = 280
    @State private var isCollapsed: Bool = false
    @State private var isAddingTag: Bool = false
    @State private var showSuggestions: Bool = false
    @State private var selectedSuggestionIndex: Int = 0
    @State private static var cancellables = Set<AnyCancellable>()
    
    @FocusState private var isFocused: Bool
    
    init(book: BookData) {
        self.book = book
        _localTags = State(initialValue: book.tags)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CollapsibleHeader(
                isEditing: $isEditing,
                isCollapsed: $isCollapsed,
                title: "Tags",
                isEditingDisabled: (book.status == .deleted) || (localTags.isEmpty),
                onEditToggle: { isEditing.toggle() },
                onToggleCollapse: { isCollapsed.toggle() }
            )
            if !isCollapsed {
                tagsContent
            }
        }
        .padding(16)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
        .animation(.easeInOut(duration: 0.3), value: showSuggestions)
        .onChange(of: book.tags) { onTagsChanged() }
        .onChange(of: newTag) { _, newValue in onNewTagChanged(newValue) }
    }
    
    private var tagsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !contentViewModel.selectedTags.isEmpty {
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
                tagAddingSection
            } else {
                RowItems.ActionButton(
                    label: "Add Tag",
                    systemImageName: "plus.circle",
                    action: { isAddingTag = true },
                    padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    isDisabled: book.status == .deleted
                )
                .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: localTags.isEmpty)
    }
    
    private var selectedTagsView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(contentViewModel.selectedTags), id: \.self) { tag in
                TagItem(
                    tag: tag,
                    backgroundColor: .accentColor,
                    textColor: .white,
                    cornerRadius: 10,
                    isSelected: true,
                    enableHoverEffect: true,
                    onRemove: { clearTag(tag) }
                )
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty
    private var emptyStateView: some View {
        EmptyStateView(type: .tags, isCompact: true)
            .transition(.opacity)
    }
    
    // MARK: - Grid
    private var tagGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(localTags, id: \.self) { tag in
                TagItem(
                    tag: tag,
                    backgroundColor: contentViewModel.selectedTags.contains(tag) ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.2),
                    showRemoveButton: isEditing,
                    onRemove: { removeTag(tag) }
                )
                .onTapGesture { toggleTagSelection(tag) }
            }
        }
    }
    
    // MARK: - Form
    private var tagAddingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowItems(
                contentType: .tag,
                mode: .add,
                isMultiline: false,
                editText: $newTag,
                onSave: handleAddTag,
                onCancel: {
                    withAnimation {
                        isAddingTag = false
                        showSuggestions = false
                    }
                }
            )
            .focused($isFocused)
            .onSubmit { handleTagSubmit() }
            .onKeyPress(.upArrow) {
                if showSuggestions {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        navigateSuggestions(direction: -1)
                    }
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.downArrow) {
                if showSuggestions {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        navigateSuggestions(direction: 1)
                    }
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.escape) {
                if showSuggestions {
                    withAnimation {
                        showSuggestions = false
                    }
                    return .handled
                }
                return .ignored
            }
            .background(formWidthReader)
            .padding(.bottom, 8)
            
            if showSuggestions && !newTag.isEmpty {
                tagSuggestionsView
                    .frame(width: formWidth)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    .zIndex(100)
            }
        }
    }
    
    private var formWidthReader: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: FormWidthPreferenceKey.self, value: geometry.size.width)
                .onPreferenceChange(FormWidthPreferenceKey.self) { width in
                    Task { @MainActor in
                        formWidth = width
                    }
                }
        }
    }
    
    // MARK: - Suggestion Views
    private var tagSuggestionsView: some View {
        let suggestions = getSuggestions()
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagExists = tagExistsCaseInsensitive(trimmedTag)
        
        return VStack(alignment: .leading, spacing: 0) {
            if !suggestions.isEmpty {
                suggestionsListView(suggestions)
            } else if !trimmedTag.isEmpty {
                if tagExists {
                    tagAlreadyExistsView(trimmedTag)
                } else {
                    noSuggestionsView
                }
            }
        }
        .frame(width: formWidth)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func tagAlreadyExistsView(_ tag: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Tag already exists")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                
                Text("already exists in this book")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }
    
    
    private func suggestionsListView(_ suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element) { index, tag in
                suggestionRow(tag: tag, index: index)
                
                if index < suggestions.count - 1 {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
            
            keyboardHelpView
        }
    }
    
    private func suggestionRow(tag: String, index: Int) -> some View {
        Button(action: {
            selectSuggestion(tag)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text("#")
                    .foregroundColor(.secondary)
                    .font(.footnote)
                
                Text(tag)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if index == selectedSuggestionIndex {
                    Text("↩︎")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                index == selectedSuggestionIndex ?
                Color.accentColor.opacity(0.1) :
                    Color.clear
            )
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var keyboardHelpView: some View {
        HStack(spacing: 4) {
            Image(systemName: "keyboard")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Use ↑↓ to navigate, Enter to select")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.05))
    }
    
    private var noSuggestionsView: some View {
        VStack(spacing: 4) {
            Text("No matching tags")
                .font(.callout)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text("Press Enter to create")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("#\(newTag)")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }
    
    // MARK: - Event Handlers
    private func onTagsChanged() {
        if localTags.count != book.tags.count || !localTags.elementsEqual(book.tags) {
            localTags = book.tags
            
            if localTags.isEmpty {
                isEditing = false
            }
        }
    }
    
    private func onNewTagChanged(_ newValue: String) {
        selectedSuggestionIndex = 0
        
        if newValue.isEmpty {
            showSuggestions = false
        } else {
            if !newTag.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.newTag.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSuggestions = true
                        }
                    }
                }
            }
        }
    }
    
    private func handleTagSubmit() {
        if showSuggestions && selectedSuggestionIndex >= 0 {
            let suggestions = getSuggestions()
            if !suggestions.isEmpty && selectedSuggestionIndex < suggestions.count {
                selectSuggestion(suggestions[selectedSuggestionIndex])
            } else {
                handleAddTag()
            }
        } else {
            handleAddTag()
        }
    }
    
    // MARK: - Actions
    private func toggleTagSelection(_ tag: String) {
        contentViewModel.toggleTagSelection(tag)
    }
    
    private func clearTag(_ tag: String) {
        contentViewModel.clearTag(tag)
    }
    
    private func removeTag(_ tag: String) {
        contentViewModel.removeTag(tag, from: book)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in
                overlayManager.showToast(message: "Tag removed")
            })
            .store(in: &Self.cancellables)
    }
    
    private func containsTagCaseInsensitive(_ tag: String) -> Bool {
        return localTags.contains { $0.caseInsensitiveCompare(tag) == .orderedSame }
    }
    
    private func handleAddTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        // Use case insensitive comparison to check for existing tags
        guard !tagExistsCaseInsensitive(trimmedTag) else {
            // Give feedback that tag already exists
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            return
        }
        
        contentViewModel.addTag(trimmedTag, to: book)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                overlayManager.showToast(message: "Tag added")
                newTag = ""
                
                withAnimation {
                    isFocused = true
                    showSuggestions = false
                }
                
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
            })
            .store(in: &Self.cancellables)
    }
    
    // MARK: - Suggestion Functions
    private func getSuggestions() -> [String] {
        let suggestedTags = contentViewModel.getTopTags(matching: newTag, limit: 5)
        
        return suggestedTags.filter { suggestedTag in
            !localTags.contains { existingTag in
                existingTag.caseInsensitiveCompare(suggestedTag) == .orderedSame
            }
        }
    }
    
    private func tagExistsCaseInsensitive(_ tag: String) -> Bool {
        return localTags.contains { existingTag in
            existingTag.caseInsensitiveCompare(tag) == .orderedSame
        }
    }
    
    private func navigateSuggestions(direction: Int) {
        let suggestions = getSuggestions()
        if !suggestions.isEmpty {
            selectedSuggestionIndex = (selectedSuggestionIndex + direction) % suggestions.count
            if selectedSuggestionIndex < 0 {
                selectedSuggestionIndex = suggestions.count - 1
            }
        }
    }
    
    private func selectSuggestion(_ tag: String) {
        // Use case insensitive comparison
        guard !containsTagCaseInsensitive(tag) else { return }
        
        contentViewModel.addTag(tag, to: book)
            .sink(receiveCompletion: { _ in },
                  receiveValue: {
                overlayManager.showToast(message: "Tag added")
                newTag = ""
                
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFocused = true
                    showSuggestions = false
                }
            })
            .store(in: &Self.cancellables)
    }
    
    // MARK: - Data Management
    private func saveTags() {
        book.tags = localTags
        contentViewModel.saveChanges()
    }
    
    private func loadTags() {
        localTags = book.tags
    }
}

struct FormWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 280
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

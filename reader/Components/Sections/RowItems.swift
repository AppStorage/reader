import SwiftUI
import CryptoKit

// MARK: - Display Modes
enum DisplayMode {
    case display
    case edit
    case add
}

// MARK: - Content Types
enum ContentType {
    case note
    case quote
    case tag
    
    var iconName: String {
        switch self {
        case .note: return "note.text"
        case .quote: return "text.quote"
        case .tag: return "tag"
        }
    }
    
    var textLabel: String {
        switch self {
        case .note: return "note"
        case .quote: return "quote"
        case .tag: return "tag"
        }
    }
}

// MARK: - Row Items
// Reusable compoenent for sections (notes, quotes, and tags)
struct RowItems: View {
    @Binding var editText: String
    @Binding var editSecondary: String
    @Binding var editAttribution: String
    
    @FocusState private var isFocusedOnText: Bool
    @FocusState private var isFocusedOnSecondary: Bool
    @FocusState private var isFocusedOnAttribution: Bool
    
    let contentType: ContentType
    let text: String
    let secondaryText: String?
    let attributedText: String?
    let customFont: Font?
    let mode: DisplayMode
    let allowEditing: Bool
    let isMultiline: Bool
    let onRemove: (() -> Void)?
    let onEdit: (() -> Void)?
    let onSave: (() -> Void)?
    let onCancel: (() -> Void)?
    
    init(
        contentType: ContentType,
        text: String = "",
        secondaryText: String? = nil,
        attributedText: String? = nil,
        customFont: Font? = nil,
        mode: DisplayMode = .display,
        allowEditing: Bool = true,
        isMultiline: Bool = true,
        editText: Binding<String>,
        editSecondary: Binding<String> = .constant(""),
        editAttribution: Binding<String> = .constant(""),
        onRemove: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.contentType = contentType
        self.text = text
        self.secondaryText = secondaryText
        self.attributedText = attributedText
        self.customFont = customFont
        self.mode = mode
        self.allowEditing = allowEditing
        self.isMultiline = isMultiline
        self._editText = editText
        self._editSecondary = editSecondary
        self._editAttribution = editAttribution
        self.onRemove = onRemove
        self.onEdit = onEdit
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        switch mode {
        case .display:
            displayView
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn(duration: 0.2)),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                ))
        case .edit, .add:
            editView
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn(duration: 0.2)),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                ))
        }
    }
    
    private var displayView: some View {
        HStack(alignment: .top, spacing: 8) {
            mainTextView
            Spacer()
            
            if let secondary = secondaryText, !secondary.isEmpty {
                secondaryTextView(secondary)
            }
            
            if allowEditing {
                editActionMenu
            }
        }
        .padding(.vertical, 6)
    }
    
    private var mainTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(customFont ?? .body)
                .multilineTextAlignment(.leading)
                .padding(10)
            
            if let attributedText = attributedText, !attributedText.isEmpty {
                Text("— \(attributedText)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private func secondaryTextView(_ text: String) -> some View {
        Text("p. \(text)")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .frame(minWidth: 50, alignment: .trailing)
    }
    
    // MARK: - Edit Actions
    // Edit or delete an item
    private var editActionMenu: some View {
        Menu {
            Button(action: {
                if let onEdit = onEdit {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onEdit()
                    }
                }
            }) {
                Text("Edit")
            }
            
            if let onRemove = onRemove {
                Button(action: {
                    withAnimation { onRemove() }
                }) {
                    Text("Delete")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(BorderlessButtonStyle())
        .contentShape(Rectangle())
        .transition(.opacity)
    }
    
    // MARK: - Edit Form
    private var editView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Main text input
                if isMultiline {
                    multilineTextInputSection
                } else {
                    singleLineTextInputSection
                }
                
                // Page number input for notes and quotes
                if contentType != .tag && shouldShowSecondaryField {
                    pageNumberInput
                }
                
                // Attribution field for quotes only
                if contentType == .quote && shouldShowAttributionField {
                    attributionField
                }
            }
            
            Divider()
                .background(Color(NSColor.separatorColor))
                .frame(height: 1)
            
            formButtons
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            // Set focus to the text field when edit view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocusedOnText = true
            }
        }
    }
    
    private var shouldShowSecondaryField: Bool {
        contentType != .tag
    }
    
    private var shouldShowAttributionField: Bool {
        contentType == .quote
    }
    
    // MARK: - Multi-line Form
    // For notes and quotes sections
    @ViewBuilder
    private var multilineTextInputSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: contentType.iconName)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            ZStack(alignment: .topLeading) {
                if editText.isEmpty {
                    Text(mode == .add ? "Enter a \(contentType.textLabel) here" : "Edit \(contentType.textLabel)")
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 12, leading: 6, bottom: 0, trailing: 0))
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $editText)
                    .font(.body)
                    .lineSpacing(4)
                    .padding(6)
                    .frame(height: 100)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFocusedOnText ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                    )
                    .focused($isFocusedOnText)
                    .animation(.easeInOut(duration: 0.2), value: isFocusedOnText)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.visible)
            }
            .frame(height: 100)
        }
    }
    
    // MARK: - Single Line Form
    // For like tags section
    @ViewBuilder
    private var singleLineTextInputSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: contentType.iconName)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                if editText.isEmpty {
                    Text(mode == .add ? "Enter a \(contentType.textLabel) here" : "Edit \(contentType.textLabel)")
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $editText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFocusedOnText ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                    )
                    .focused($isFocusedOnText)
                    .animation(.easeInOut(duration: 0.2), value: isFocusedOnText)
            }
        }
    }
    
    private var pageNumberInput: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "number")
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            TextField("Page no. (e.g., 11 or 11-15)", text: $editSecondary)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFocusedOnSecondary ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                )
                .focused($isFocusedOnSecondary)
                .onChange(of: editSecondary) { _, newValue in
                    editSecondary = filterPageNumberInput(newValue)
                }
                .animation(.easeInOut(duration: 0.2), value: isFocusedOnSecondary)
        }
    }
    
    // MARK: - Attribution for Quotes
    @ViewBuilder
    private var attributionField: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "person")
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            TextField("Attributed to", text: $editAttribution)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFocusedOnAttribution ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                )
                .focused($isFocusedOnAttribution)
                .animation(.easeInOut(duration: 0.2), value: isFocusedOnAttribution)
        }
    }
    
    // MARK: - Form Buttons
    private var formButtons: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeOut(duration: 0.5)) {
                    if let onCancel = onCancel {
                        onCancel()
                    }
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Save") {
                withAnimation(.easeOut(duration: 0.5)) {
                    if let onSave = onSave {
                        onSave()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .foregroundColor(editText.isEmpty ? .gray : .white)
            .disabled(editText.isEmpty)
            .scaleEffect(editText.isEmpty ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.3), value: editText.isEmpty)
        }
    }
    
    // MARK: - Helpers
    // Formats content and metadata into a storage string
    static func formatForStorage(text: String, pageNumber: String, attribution: String = "") -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !pageNumber.isEmpty {
            result += " [p. \(pageNumber)]"
        }

        if !attribution.isEmpty {
            result += " — \(attribution)"
        }

        return result
    }
    
    // Parses a storage string into components (text, page, attribution)
    static func parseFromStorage(_ storedString: String) -> (text: String, pageNumber: String, attribution: String) {
        var text = storedString
        var pageNumber = ""
        var attribution = ""

        // Extract page number: look for " [p. ...]"
        if let pageRange = text.range(of: #" \[p\. ([^\]]+)\]"#, options: .regularExpression) {
            let pageText = String(text[pageRange])
            if let match = pageText.range(of: #"(?<=\[p\. ).+?(?=\])"#, options: .regularExpression) {
                pageNumber = String(pageText[match])
            }
            text.removeSubrange(pageRange)
        }

        // Extract attribution: look for " — attribution" at end
        if let dashRange = text.range(of: #" — .+$"#, options: .regularExpression) {
            let attributionText = String(text[dashRange]).replacingOccurrences(of: " — ", with: "")
            attribution = attributionText
            text.removeSubrange(dashRange)
        }

        return (
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            pageNumber: pageNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            attribution: attribution.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    private func filterPageNumberInput(_ input: String) -> String {
        // Allow numbers and one hyphen for page ranges
        let allowedCharacters = CharacterSet(charactersIn: "0123456789-")
        
        // Filter to only allow valid characters
        let filtered = String(input.unicodeScalars.filter { allowedCharacters.contains($0) })
        
        // If there's no hyphen or just one hyphen, return filtered input
        let hyphenCount = filtered.filter { $0 == "-" }.count
        if hyphenCount <= 1 {
            return filtered
        }
        
        // If there are multiple hyphens, keep only the first one
        if let firstHyphenIndex = filtered.firstIndex(of: "-") {
            let beforeHyphen = filtered[..<firstHyphenIndex]
            let afterHyphenStart = filtered.index(after: firstHyphenIndex)
            let afterHyphen = filtered[afterHyphenStart...].filter { $0 != "-" }
            
            return String(beforeHyphen) + "-" + String(afterHyphen)
        }
        
        return filtered
    }
    
    // MARK: - Static Utility Functions
    static func formatPagePrefix(for pageNumber: String) -> String {
        return pageNumber.contains("-") ? "pp." : "p."
    }
    
    static func extractPageNumber(from input: String) -> Int? {
        let components = input.components(separatedBy: " [p. ")
        guard components.count > 1,
              let pageComponent = components.last?.replacingOccurrences(of: "]", with: "") else {
            return nil
        }
        
        // Extract the first number from the page range
        let pageRangeComponents = pageComponent.split(separator: "-")
        if let firstPage = pageRangeComponents.first, let pageNumber = Int(firstPage) {
            return pageNumber
        }
        
        return nil
    }
    
    // MARK: - Hash for Notes/Quotes
    static func hashedIdentifier(for text: String) -> String {
        let data = Data(text.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Reusable Buttons
extension RowItems {
    struct ActionButton: View {
        let label: String?
        let systemImageName: String
        let foregroundColor: Color
        let action: () -> Void
        let padding: EdgeInsets?
        let isDisabled: Bool
        
        init(
            label: String? = nil,
            systemImageName: String,
            foregroundColor: Color = .accentColor,
            action: @escaping () -> Void,
            padding: EdgeInsets? = nil,
            isDisabled: Bool = false
        ) {
            self.label = label
            self.systemImageName = systemImageName
            self.foregroundColor = foregroundColor
            self.action = action
            self.padding = padding
            self.isDisabled = isDisabled
        }
        
        var body: some View {
            Button(action: { withAnimation { action() } }) {
                if let label = label {
                    Label(label, systemImage: systemImageName)
                        .font(.callout)
                        .foregroundColor(isDisabled ? .gray : foregroundColor)
                } else {
                    Image(systemName: systemImageName)
                        .foregroundColor(isDisabled ? .gray : foregroundColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(padding ?? .init())
            .disabled(isDisabled)
        }
    }
}

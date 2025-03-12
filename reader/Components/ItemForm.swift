import SwiftUI

struct ItemForm: View {
    @Binding var text: String
    @Binding var supplementaryField: String?
    @Binding var attributedField: String?
    
    @FocusState private var isFocusedOnText: Bool
    @FocusState private var isFocusedOnAttributedField: Bool
    
    let textLabel: String
    let iconName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let isMultiline: Bool
    
    init(text: Binding<String>,
         supplementaryField: Binding<String?>,
         attributedField: Binding<String?>,
         textLabel: String,
         iconName: String,
         onSave: @escaping () -> Void,
         onCancel: @escaping () -> Void,
         isMultiline: Bool) {
        self._text = text
        self._supplementaryField = supplementaryField
        self._attributedField = attributedField
        self.textLabel = textLabel
        self.iconName = iconName
        self.onSave = onSave
        self.onCancel = onCancel
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                if isMultiline {
                    multilineTextInputSection
                } else {
                    singleLineTextInputSection
                }
                
                if supplementaryField != nil {
                    PageNumberInput(pageNumber: Binding(
                        get: { supplementaryField ?? "" },
                        set: { supplementaryField = $0.isEmpty ? nil : $0 }
                    ))
                }
                if attributedField != nil {
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
    }
    
    // Multi-line text input
    @ViewBuilder
    private var multilineTextInputSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(textLabel)
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 12, leading: 6, bottom: 0, trailing: 0))
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
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
    
    // Single-line text input
    @ViewBuilder
    private var singleLineTextInputSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(textLabel)
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $text)
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
    
    @ViewBuilder
    private var attributionField: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "person")
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            TextField("Attributed to", text: Binding(
                get: { attributedField ?? "" },
                set: { attributedField = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocusedOnAttributedField ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
            )
            .focused($isFocusedOnAttributedField)
            .animation(.easeInOut(duration: 0.2), value: isFocusedOnAttributedField)
        }
    }
    
    private var formButtons: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeOut(duration: 0.75)) {
                    onCancel()
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Save") {
                withAnimation(.easeOut(duration: 0.75)) {
                    onSave()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .foregroundColor(text.isEmpty ? .gray : .white)
            .disabled(text.isEmpty)
            .scaleEffect(text.isEmpty ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.75), value: text.isEmpty)
        }
    }
}

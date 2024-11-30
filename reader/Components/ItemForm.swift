import SwiftUI

struct ItemForm: View {
    @Binding var text: String
    @Binding var supplementaryField: String?
    @FocusState private var isFocusedOnText: Bool
    
    let textLabel: String
    let iconName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let isSingleLine: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                textInputSection
                if supplementaryField != nil {
                    PageNumberInput(pageNumber: Binding(
                        get: { supplementaryField ?? "" },
                        set: { supplementaryField = $0.isEmpty ? nil : $0 }
                    ))
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
    
    @ViewBuilder
    private var textInputSection: some View {
        HStack(alignment: .center, spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            
            if isSingleLine {
                // Single-line
                TextField(textLabel, text: $text)
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
            } else {
                // Multi-line
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
                        .background(RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isFocusedOnText ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
                        )
                        .focused($isFocusedOnText)
                        .animation(.easeInOut(duration: 0.2), value: isFocusedOnText)
                        .scrollDisabled(text.split(separator: "\n").count < 6)
                        .scrollIndicators(.hidden)
                }
                .frame(minHeight: 60, maxHeight: max(120, CGFloat(text.split(separator: "\n").count * 20)))
            }
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

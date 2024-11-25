import SwiftUI

struct ItemForm: View {
    @Binding var text: String
    @Binding var supplementaryField: String
    @FocusState private var isFocusedOnText: Bool

    let textLabel: String
    let supplementaryLabel: String
    let iconName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                textEditorSection
                PageInputHelper(pageNumber: $supplementaryField)
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

    private var textEditorSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 20, height: 20)
            TextEditor(text: $text)
                .font(.body)
                .lineSpacing(4)
                .frame(minHeight: 60, maxHeight: max(120, CGFloat(text.split(separator: "\n").count * 20)))
                .padding(6)
                .focused($isFocusedOnText)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(isFocusedOnText ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2))
                .animation(.easeInOut(duration: 0.2), value: isFocusedOnText)
                .scrollDisabled(text.split(separator: "\n").count < 6)
                .scrollIndicators(.hidden)
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
            .scaleEffect(1.0)
            .animation(.easeOut(duration: 0.75), value: true)

            Spacer()

            Button("Save") {
                withAnimation(.easeOut(duration: 0.75)) {
                    onSave()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .foregroundColor((text.isEmpty || supplementaryField.isEmpty) ? .gray : .white)
            .disabled(text.isEmpty || supplementaryField.isEmpty)
            .scaleEffect((text.isEmpty || supplementaryField.isEmpty) ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.75), value: (text.isEmpty || supplementaryField.isEmpty))
        }
    }
}

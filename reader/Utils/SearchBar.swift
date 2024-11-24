import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .autocorrectionDisabled(true)
                .frame(height: 20)
            
            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .padding(2)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isFocused ? Color.accentColor : Color(nsColor: NSColor.separatorColor), lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .frame(height: 28) // Adjust overall height
    }
}

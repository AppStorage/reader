import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var placeholder: String = "Search"

    var body: some View {
        HStack {
            searchIcon
            searchTextField
            clearButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(searchBarBackground)
        .overlay(searchBarBorder)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .frame(height: 28)
    }

    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
    }

    private var searchTextField: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isFocused)
            .autocorrectionDisabled(true)
            .frame(height: 20)
    }

    private var clearButton: some View {
        Group {
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .padding(2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear")
            }
        }
    }

    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(nsColor: NSColor.controlBackgroundColor))
    }

    private var searchBarBorder: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(
                isFocused
                    ? Color.accentColor
                    : Color(nsColor: NSColor.separatorColor), lineWidth: 2)
    }
}

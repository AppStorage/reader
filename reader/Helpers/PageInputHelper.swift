import SwiftUI

struct PageInputHelper: View {
    @Binding var pageNumber: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "number")
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            TextField("Page no. (e.g., 11 or 11-15)", text: Binding(
                get: { pageNumber },
                set: { pageNumber = filterPageNumberInput($0) }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 2)
            )
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }

    private func filterPageNumberInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789-")
        let filtered = input.unicodeScalars.filter { allowedCharacters.contains($0) }
        var result = String(String.UnicodeScalarView(filtered))
        
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        
        if result.hasPrefix("-") {
            result.removeFirst()
        }
        if result.hasSuffix("-") {
            result.removeLast()
        }
        
        let components = result.split(separator: "-")
        if components.count > 2 {
            result = components.joined(separator: "-")
        }
        
        return result
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
    
    static func pagePrefix(for pageNumber: String) -> String {
        return pageNumber.contains("-") ? "pp." : "p."
    }
}

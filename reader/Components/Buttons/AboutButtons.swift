import SwiftUI

struct AboutButtons: View {
    @State private var isHovered: Bool = false
    
    let title: String
    let systemImage: String
    var url: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let action = action {
                action()
            } else if let url = url, let validURL = URL(string: url) {
                NSWorkspace.shared.open(validURL)
            }
        }) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? .gray.opacity(0.2) : .gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovered ? .gray : .clear, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

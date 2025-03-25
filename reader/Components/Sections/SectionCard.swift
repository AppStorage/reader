import SwiftUI

struct SectionCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: 700, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
    }
}

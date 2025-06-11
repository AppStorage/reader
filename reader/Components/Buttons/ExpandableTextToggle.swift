import SwiftUI

struct ExpandableTextToggle: View {
    @Binding var isExpanded: Bool
    
    var alignmentPadding: CGFloat = 6
    var font: Font = .footnote

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }) {
            Text(isExpanded ? "Show Less" : "Show More")
                .font(font)
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .padding(.leading, alignmentPadding)
    }
}

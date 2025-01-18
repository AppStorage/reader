import SwiftUI

struct TagChip: View {
    let tag: String
    let isEditing: Bool
    let onRemove: () -> Void
    var backgroundColor: Color = Color.secondary.opacity(0.2)
    var textColor: Color = .primary
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.body)
                .foregroundColor(textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
            
            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isEditing)
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
    }
}

import SwiftUI

struct TagItem: View {
    @State private var isHovered: Bool = false
    
    let tag: String
    var backgroundColor: Color = .secondary.opacity(0.2)
    var textColor: Color = .primary
    var cornerRadius: CGFloat = 8
    var isSelected: Bool = false
    var showRemoveButton: Bool = false
    var enableHoverEffect: Bool = false
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(enableHoverEffect ? .subheadline : .body)
                .foregroundColor(enableHoverEffect ? .white : textColor)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if shouldShowButton {
                Button(action: {
                    if let onRemove = onRemove {
                        onRemove()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(enableHoverEffect ? .white : .red)
                        .imageScale(.small)
                        .padding(enableHoverEffect ? 2 : 0)
                }
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isHovered || showRemoveButton)
                .accessibilityLabel(enableHoverEffect ? "Clear tag \(tag)" : "Remove tag \(tag)")
            }
        }
        .padding(.horizontal, enableHoverEffect ? 6 : 8)
        .padding(.vertical, enableHoverEffect ? 2 : 5)
        .background(backgroundColor)
        .cornerRadius(enableHoverEffect ? 10 : cornerRadius)
        .scaleEffect(isHovered && enableHoverEffect ? 1.1 : 1.0)
        .onHover { hovering in
            if enableHoverEffect {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
    
    private var shouldShowButton: Bool {
        showRemoveButton || (isHovered && enableHoverEffect && onRemove != nil)
    }
}

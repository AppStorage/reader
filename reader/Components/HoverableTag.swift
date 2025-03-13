import SwiftUI

struct HoverableTag: View {
    @State private var isHovered: Bool = false
    
    let tag: String
    let clearAction: () -> Void
    
    var backgroundColor: Color = .accentColor
    var enableHoverEffect: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if isHovered {
                Button(action: clearAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.small)
                        .padding(2)
                }
                .buttonStyle(.borderless)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
                .accessibilityLabel("Clear tag \(tag)")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .cornerRadius(10)
        .scaleEffect(isHovered && enableHoverEffect ? 1.1 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

import SwiftUI

struct SettingsButton: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Label("Preferences", systemImage: "gear")
                .font(.system(size: 16, weight: .regular))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .foregroundColor(buttonForegroundColor)
                .brightness(buttonBrightness)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.borderless)
        .padding([.leading, .bottom], 10)
        .accessibilityLabel("Preferences")
        .help("Preferences")
        .onHover { hovering in
            handleHover(hovering)
        }
    }
    
    // MARK: - Helpers
    private func handleHover(_ hovering: Bool) {
        isHovered = hovering
    }
    private var buttonForegroundColor: Color {
        isHovered && colorScheme == .light ? .accentColor : .primary
    }
    private var buttonBrightness: Double {
        isHovered ? (colorScheme == .dark ? 0.5 : 0) : 0
    }
}

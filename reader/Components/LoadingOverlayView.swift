import SwiftUI

struct LoadingOverlayView: View {
    let message: String
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView(message)
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Cancel Fetching Books")
                }
                .buttonStyle(.plain)
                .onHover { isHovering in
                    NSCursor.pointingHand.push()
                    if !isHovering {
                        NSCursor.pop()
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
}

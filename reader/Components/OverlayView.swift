import SwiftUI

struct OverlayView: View {
    @EnvironmentObject var overlayManager: OverlayManager
    var windowId: String = "main"
    
    var body: some View {
        if overlayManager.isShowingOverlay(for: windowId),
           let overlay = overlayManager.getOverlay(for: windowId) {
            switch overlay {
            case .toast:
                toastOverlay
            case .loading:
                loadingOverlay
            }
        }
    }
    
    // MARK: - Toast Overlay
    private var toastOverlay: some View {
        VStack {
            Text(overlayManager.getOverlay(for: windowId)?.message ?? "")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(radius: 10)
                .transition(.opacity)
                .animation(.easeInOut, value: overlayManager.isShowingOverlay(for: windowId))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView(overlayManager.getOverlay(for: windowId)?.message ?? "")
                
                if let cancelAction = overlayManager.getCancelAction(for: windowId) {
                    Button(action: {
                        cancelAction()
                        overlayManager.hideOverlay(windowId: windowId)
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Cancel Operation")
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        NSCursor.pointingHand.push()
                        if !isHovering {
                            NSCursor.pop()
                        }
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

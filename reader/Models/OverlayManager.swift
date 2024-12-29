import SwiftUI

@MainActor
class OverlayManager: ObservableObject {
    @Published var isShowingOverlay: Bool = false
    @Published var overlayMessage: String = ""
    
    func showOverlay(message: String, duration: TimeInterval = 1.5) {
        overlayMessage = message
        isShowingOverlay = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isShowingOverlay = false
            self.overlayMessage = ""
        }
    }
}

struct OverlayView: View {
    @EnvironmentObject var overlayManager: OverlayManager
    
    var body: some View {
        if overlayManager.isShowingOverlay {
            VStack {
                Text(overlayManager.overlayMessage)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.opacity)
                    .animation(.easeInOut, value: overlayManager.isShowingOverlay)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

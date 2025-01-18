import SwiftUI

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

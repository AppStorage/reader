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

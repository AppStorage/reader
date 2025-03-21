import SwiftUI

// MARK: - Overlay Types
enum OverlayType: Equatable {
    case toast(message: String)
    case loading(message: String)
    
    var message: String {
        switch self {
        case .toast(let message), .loading(let message):
            return message
        }
    }
}

struct OverlayContext: Equatable {
    var overlayType: OverlayType
    var windowId: String
}

// MARK: - Overlay Manager
@MainActor
class OverlayManager: ObservableObject {
    @Published var currentOverlays: [String: OverlayType] = [:]
    @Published var cancelActions: [String: (() -> Void)] = [:]
    
    private var dismissTasks: [String: Task<Void, Never>] = [:]
    
    func showToast(message: String, duration: TimeInterval = 1.5, windowId: String = "main") {
        // Cancel any existing dismiss task for this window
        dismissTasks[windowId]?.cancel()
        
        // Set up new toast
        currentOverlays[windowId] = .toast(message: message)
        objectWillChange.send()
        
        // Schedule auto-dismissal
        dismissTasks[windowId] = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                currentOverlays.removeValue(forKey: windowId)
                objectWillChange.send()
            }
        }
    }
    
    func showLoading(message: String, windowId: String = "main", onCancel: (() -> Void)? = nil) {
        // Cancel any existing dismiss task for this window
        dismissTasks[windowId]?.cancel()
        
        // Set up loading overlay
        currentOverlays[windowId] = .loading(message: message)
        if let onCancel = onCancel {
            cancelActions[windowId] = onCancel
        }
        objectWillChange.send()
    }
    
    func hideOverlay(windowId: String = "main") {
        dismissTasks[windowId]?.cancel()
        currentOverlays.removeValue(forKey: windowId)
        cancelActions.removeValue(forKey: windowId)
        objectWillChange.send()
    }
    
    func isShowingOverlay(for windowId: String = "main") -> Bool {
        return currentOverlays[windowId] != nil
    }
    
    func getOverlay(for windowId: String = "main") -> OverlayType? {
        return currentOverlays[windowId]
    }
    
    func getCancelAction(for windowId: String = "main") -> (() -> Void)? {
        return cancelActions[windowId]
    }
}

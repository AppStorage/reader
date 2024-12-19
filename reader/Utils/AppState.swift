import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("selectedTheme") private var storedTheme: String = "system"
    @AppStorage("checkForUpdatesAutomatically") var checkForUpdatesAutomatically: Bool = false
    
    @Published var selectedTheme: Theme = .system {
        didSet {
            storedTheme = selectedTheme.rawValue
            applyTheme(selectedTheme)
        }
    }
    
    @Published var isCheckingForUpdates: Bool = false
    
    // Temporary states
    var temporarySettings: [String: Any] = [:]
    var aboutCache: [String: Any] = [:]

    init() {
        DispatchQueue.main.async {
            self.selectedTheme = Theme(rawValue: self.storedTheme) ?? .system
            self.applyTheme(self.selectedTheme)
        }
    }
    
    func applyTheme(_ theme: Theme) {
        switch theme {
        case .system:
            NSApp.appearance = nil
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        }
    }

    func cleanupTemporarySettings() {
        temporarySettings.removeAll()
    }

    func clearAboutCache() {
        aboutCache.removeAll()
    }
}

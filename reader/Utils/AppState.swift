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
    @Published var alertType: AlertType?
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    
    // Temporary States
    var temporarySettings: [String: Any] = [:]
    var aboutCache: [String: Any] = [:]
    
    init() {
        // Apply selected theme
        DispatchQueue.main.async {
            self.selectedTheme = Theme(rawValue: self.storedTheme) ?? .system
            self.applyTheme(self.selectedTheme)
        }
        
        // Perform a daily update check if enabled
        scheduleDailyUpdateCheck()
    }
    
    // MARK: Appearance
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
    
    // MARK: Cleanup
    func cleanupTemporarySettings() {
        temporarySettings.removeAll()
    }
    
    func clearAboutCache() {
        aboutCache.removeAll()
    }
    
    // MARK: Updates
    func checkForAppUpdates(isUserInitiated: Bool) {
        isCheckingForUpdates = true
        
        Task {
            do {
                let (latestVersionFound, downloadURLFound) = try await fetchLatestRelease()
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                
                if isNewerVersion(latestVersionFound, than: currentVersion) {
                    DispatchQueue.main.async {
                        self.latestVersion = latestVersionFound
                        self.downloadURL = downloadURLFound
                        self.alertType = .newUpdateAvailable
                    }
                } else if isUserInitiated {
                    alertType = .upToDate
                }
            } catch {
                if isUserInitiated {
                    DispatchQueue.main.async {
                        if isUserInitiated {
                            self.alertType = .error("Update Check Failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            isCheckingForUpdates = false
        }
    }
    
    func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        for (new, current) in zip(newComponents, currentComponents) {
            if new > current { return true }
            if new < current { return false }
        }
        
        return newComponents.count > currentComponents.count
    }
    
    func scheduleDailyUpdateCheck() {
        guard checkForUpdatesAutomatically else { return }
        
        let lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        let now = Date()
        
        if !Calendar.current.isDate(now, inSameDayAs: lastUpdateCheck) {
            checkForAppUpdates(isUserInitiated: false)
            UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        }
    }
}

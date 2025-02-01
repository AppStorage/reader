import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("selectedTheme") private var storedTheme: String = "system"
    @AppStorage("checkForUpdatesAutomatically") var checkForUpdatesAutomatically: Bool = false
    
    @Published var isCheckingForUpdates: Bool = false
    @Published var alertType: AlertType?
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    @Published var showSoftDeleteConfirmation = false
    @Published var showPermanentDeleteConfirmation = false
    @Published var selectedBooks: [BookData] = []
    
    @Published var selectedTheme: Theme = .system {
        didSet {
            storedTheme = selectedTheme.rawValue
            applyTheme(selectedTheme)
        }
    }
    
    var viewModel: ContentViewModel?
    var temporarySettings: [String: Any] = [:]
    var aboutCache: [String: Any] = [:]
    
    init() {
        selectedTheme = Theme(rawValue: storedTheme) ?? .system
        applyTheme(selectedTheme)
        
        DispatchQueue.main.async {
            self.applyTheme(self.selectedTheme)
        }
        
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
    func cleanupPreferencesCache() {
        temporarySettings.removeAll()
        aboutCache.removeAll()
    }
    
    // MARK: Updates
    func checkForAppUpdates(isUserInitiated: Bool) {
        isCheckingForUpdates = true
        
        Task {
            defer { isCheckingForUpdates = false }
            
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
                        self.alertType = .error("Update Check Failed: \(error.localizedDescription)")
                    }
                }
            }
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
    
    // MARK: Delete Actions
    func showSoftDeleteConfirmation(for books: [BookData]) {
        alertType = .softDelete(books: books)
    }
    
    func showPermanentDeleteConfirmation(for books: [BookData]) {
        alertType = .permanentDelete(books: books)
    }
    
    // MARK: Book Results
    func showNoResults() {
        alertType = .noResults("")
    }
    
    // MARK: Import/Export
    func showImportSuccess() {
        alertType = .importSuccess
    }
    
    func showExportSuccess() {
        alertType = .exportSuccess
    }
}

import SwiftUI

@MainActor
class AppState: ObservableObject {
    @AppStorage("selectedTheme") private var storedTheme: String = "system"
    @AppStorage("checkForUpdatesAutomatically") var checkForUpdatesAutomatically: Bool = false
    @AppStorage("updateCheckFrequency") var updateCheckFrequency: Double = 604800.0 // Default to weekly in seconds
    
    @Published var isCheckingForUpdates: Bool = false
    @Published var alertType: AlertTypes?
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    @Published var lastCheckStatus: UpdateCheckStatus = .unknown
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
        
        scheduleUpdateCheck()
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
    func checkForAppUpdates(isUserInitiated: Bool, showAlert: Bool = true) {
        isCheckingForUpdates = true
        lastCheckStatus = .checking
        
        Task {
            defer { isCheckingForUpdates = false }
            
            do {
                let (latestVersionFound, downloadURLFound) = try await fetchLatestRelease()
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                
                if isNewerVersion(latestVersionFound, than: currentVersion) {
                    DispatchQueue.main.async {
                        self.latestVersion = latestVersionFound
                        self.downloadURL = downloadURLFound
                        self.lastCheckStatus = .updateAvailable
                        
                        if showAlert {
                            self.alertType = .newUpdateAvailable
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.lastCheckStatus = .upToDate
                        
                        if isUserInitiated && showAlert {
                            self.alertType = .upToDate
                        }
                    }
                }
                
                UserDefaults.standard.set(Date(), forKey: "lastUpdateCheck")
            } catch {
                let errorMessage = "Update Check Failed: \(error.localizedDescription)"
                
                DispatchQueue.main.async {
                    self.lastCheckStatus = .error(errorMessage)
                    
                    if isUserInitiated && showAlert {
                        self.alertType = .error(errorMessage)
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
    
    func scheduleUpdateCheck() {
        guard checkForUpdatesAutomatically else { return }
        
        let lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdateCheck)
        
        if timeInterval >= updateCheckFrequency {
            checkForAppUpdates(isUserInitiated: false)
        }
    }
    
    enum UpdateCheckStatus {
        case unknown
        case checking
        case upToDate
        case updateAvailable
        case error(String)
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

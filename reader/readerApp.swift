import SwiftUI
import SwiftData

@main
struct readerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @StateObject private var viewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var isCheckingForUpdates = false
    @State private var latestVersion: String = ""
    @State private var downloadURL: URL?
    @State private var alertType: AlertType? = nil
    
    private static let sharedModelContainer: ModelContainer? = {
        let schema = Schema([BookData.self])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)])
        } catch {
            return nil
        }
    }()
    
    init() {
        guard let container = readerApp.sharedModelContainer else {
            fatalError("ModelContainer is not available.")
        }
        let dataManager = DataManager(modelContainer: container)
        _dataManager = StateObject(wrappedValue: dataManager)
        _viewModel = StateObject(wrappedValue: ContentViewModel(dataManager: dataManager))
    }
    
    var body: some Scene {
        mainWindow
        aboutWindow
        settingsWindow
        addBookWindow
    }
    
    // MARK: - Main Window
    private var mainWindow: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(dataManager)
                .environment(\.modelContainer, readerApp.sharedModelContainer!)
                .alert(item: $alertType, content: createAlert)
                .onAppear {
                    handleOnAppear()
                }
                .onDisappear {
                    NSApp.terminate(nil)
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About reader") {
                    openWindow(id: "aboutWindow")
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    checkForAppUpdates(isUserInitiated: true)
                }
                .disabled(isCheckingForUpdates)
            }
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    openWindow(id: "settingsWindow")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    // MARK: - About Window
    private var aboutWindow: some Scene {
        Window("About reader", id: "aboutWindow") {
            AboutView()
                .onDisappear {
                    releaseAboutWindowResources()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: - Settings Window
    private var settingsWindow: some Scene {
        Window("Settings", id: "settingsWindow") {
            SettingsView(checkForUpdates: {
                checkForAppUpdates(isUserInitiated: true)
            })
            .environmentObject(appState)
            .onDisappear {
                releaseSettingsWindowResources()
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: - Add Book Window
    private var addBookWindow: some Scene {
        Window("Add Book", id: "addBookWindow") {
            AddView()
                .environmentObject(dataManager)
                .environmentObject(appState)
                .onDisappear {
                    releaseAddBookWindowResources()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: - Update Alerts
    private func createAlert(for alertType: AlertType) -> Alert {
        switch alertType {
        case .newUpdateAvailable:
            return Alert(
                title: Text("New Update Available"),
                message: Text("reader \(latestVersion) is available. Would you like to download it?"),
                primaryButton: .default(Text("Download")) {
                    if let downloadURL = downloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                },
                secondaryButton: .cancel(Text("Later"))
            )
        case .upToDate:
            return Alert(
                title: Text("No Updates Available"),
                message: Text("You are already on the latest version."),
                dismissButton: .default(Text("OK"))
            )
        case .error(let errorDetails):
            return Alert(
                title: Text("Error"),
                message: Text(errorDetails),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Helper Functions
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        scheduleDailyUpdateCheck()
    }
    
    private func scheduleDailyUpdateCheck() {
        guard appState.checkForUpdatesAutomatically else { return }
        
        let lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        let now = Date()
        
        if !Calendar.current.isDate(now, inSameDayAs: lastUpdateCheck) {
            checkForAppUpdates(isUserInitiated: false)
            UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        }
    }
    
    // MARK: - Update Check
    private func checkForAppUpdates(isUserInitiated: Bool) {
        isCheckingForUpdates = true
        
        Task {
            do {
                let (latestVersionFound, downloadURLFound) = try await fetchLatestRelease()
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                
                if isNewerVersion(latestVersionFound, than: currentVersion) {
                    latestVersion = latestVersionFound
                    downloadURL = downloadURLFound
                    alertType = .newUpdateAvailable
                } else if isUserInitiated {
                    alertType = .upToDate
                }
            } catch {
                if isUserInitiated {
                    alertType = .error("Update Check Failed: \(error.localizedDescription)")
                }
            }
            
            isCheckingForUpdates = false
        }
    }
    
    private func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        for (new, current) in zip(newComponents, currentComponents) {
            if new > current { return true }
            if new < current { return false }
        }
        
        return newComponents.count > currentComponents.count
    }
    
    // MARK: - Cleanup Functions
    private func releaseAddBookWindowResources() {
        appState.cleanupAddBookTemporaryState()
        dataManager.clearTemporaryData()
    }
    
    private func releaseSettingsWindowResources() {
        appState.cleanupTemporarySettings()
    }
    
    private func releaseAboutWindowResources() {
    }
}

extension AppState {
    func cleanupAddBookTemporaryState() {
    }

    func cleanupTemporarySettings() {
    }
}

extension DataManager {
    func clearTemporaryData() {
    }
}

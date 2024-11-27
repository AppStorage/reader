import SwiftUI
import SwiftData

@main
struct readerApp: App {
    private static let sharedModelContainer = createModelContainer()
    
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @Environment(\.openWindow) private var openWindow
    
    @State private var isCheckingForUpdates = false
    @State private var latestVersion: String = ""
    @State private var downloadURL: URL?
    @State private var alertType: AlertType? = nil
    
    @AppStorage("checkForUpdatesAutomatically") private var checkForUpdatesAutomatically: Bool = false
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        guard let container = readerApp.sharedModelContainer else {
            fatalError("ModelContainer is not available.")
        }
        _dataManager = StateObject(wrappedValue: DataManager(modelContainer: container))
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
            ContentView(viewModel: ContentViewModel(dataManager: dataManager))
                .environmentObject(appState)
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
            }
            CommandGroup(after: .appInfo) {
                Button("Settings") {
                    openWindow(id: "settingsWindow")
                }
            }
        }
    }
    
    // MARK: - About Window
    private var aboutWindow: some Scene {
        Window("About reader", id: "aboutWindow") {
            AboutView()
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
        }
    }
    
    // MARK: - Helper Functions
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        scheduleDailyUpdateCheck()
    }
    
    private func scheduleDailyUpdateCheck() {
        guard checkForUpdatesAutomatically else { return }
        
        let lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        let now = Date()
        
        if !Calendar.current.isDate(now, inSameDayAs: lastUpdateCheck) {
            checkForAppUpdates(isUserInitiated: false)
            UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        }
    }
    
    private static func createModelContainer() -> ModelContainer? {
        let schema = Schema([BookData.self])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)])
        } catch {
            print("Error: Could not create ModelContainer - \(error)")
            return nil
        }
    }
    
    // Consolidated Update Check
    private func checkForAppUpdates(isUserInitiated: Bool) {
        appState.isCheckingForUpdates = true
        
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
                print("Failed to check for updates: \(error.localizedDescription)")
            }
            
            appState.isCheckingForUpdates = false
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
}

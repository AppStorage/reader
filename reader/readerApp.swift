import SwiftUI
import SwiftData

@main
struct readerApp: App {
    private static let sharedModelContainer = createModelContainer()

    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @Environment(\.openWindow) private var openWindow

    // State variables for the update functionality
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
        WindowGroup {
            if let container = readerApp.sharedModelContainer {
                ContentView(viewModel: ContentViewModel(dataManager: dataManager))
                    .environmentObject(appState)
                    .environmentObject(dataManager)
                    .environment(\.modelContainer, container)
                    .alert(item: $alertType) { alertType in
                        switch alertType {
                        case .newUpdateAvailable:
                            return Alert(
                                title: Text("New Update Available"),
                                message: Text("reader \(latestVersion) is available. Would you like to download it?"),
                                primaryButton: .default(Text("Download")) {
                                    if let downloadURL = downloadURL {
                                        NSWorkspace.shared.open(downloadURL) // Open the browser to the download URL
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
                    .onAppear {
                        appState.applyTheme(appState.selectedTheme)
                        scheduleDailyUpdateCheck()
                    }
                    .onDisappear {
                        NSApp.terminate(nil)
                    }
            } else {
                Text("Failed to initialize data model")
                    .onAppear {
                        print("Warning: ModelContainer failed to initialize.")
                    }
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

        Window("About reader", id: "aboutWindow") {
            AboutView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        Window("Settings", id: "settingsWindow") {
            SettingsView()
                .environmentObject(appState)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        Window("Add Book", id: "addBookWindow") {
            AddView()
                .environmentObject(dataManager)
                .environmentObject(appState)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
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

    // Function to check for updates, showing an alert with the update status
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
                    // Only show "up to date" alert if the check was initiated by the user
                    alertType = .upToDate
                }
            } catch {
                print("Failed to check for updates: \(error.localizedDescription)")
            }

            isCheckingForUpdates = false
        }
    }


    // Helper function to compare version strings
    func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }

        for (new, current) in zip(newComponents, currentComponents) {
            if new > current {
                return true // newVersion is greater
            } else if new < current {
                return false // newVersion is not greater
            }
        }

        // If all components so far are equal, but newVersion has more components (e.g., "2.1.1" vs "2.1")
        return newComponents.count > currentComponents.count
    }
    
    private func scheduleDailyUpdateCheck() {
        guard checkForUpdatesAutomatically else { return }

        let lastUpdateCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        let now = Date()

        // If the last update check was more than a day ago
        if Calendar.current.isDate(now, inSameDayAs: lastUpdateCheck) == false {
            checkForAppUpdates(isUserInitiated: false)
            UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        }
    }
}

import SwiftUI
import SwiftData
import Settings

@main
struct readerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @StateObject private var viewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var alertType: AlertType? = nil
    
    private static var preferencesWindow: SettingsWindowController?
    
    private static let sharedModelContainer: ModelContainer? = {
        let schema = Schema([BookData.self])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Disable tabs
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Initialize ModelContainer
        guard let container = readerApp.sharedModelContainer else {
            fatalError("ModelContainer is not available.")
        }
        
        // Create DataManager and ViewModel
        let dataManager = DataManager(modelContainer: container)
        _dataManager = StateObject(wrappedValue: dataManager)
        _viewModel = StateObject(wrappedValue: ContentViewModel(dataManager: dataManager))
    }
    
    var body: some Scene {
        mainWindow
        addBookWindow
    }
    
    // MARK: Main Window
    private var mainWindow: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(dataManager)
                .environment(\.modelContainer, readerApp.sharedModelContainer!)
                .alert(item: $appState.alertType) { alertType in
                    alertType.createAlert(appState: appState)
                }
                .onAppear {
                    handleOnAppear()
                }
                .onDisappear {
                    NSApp.terminate(nil)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Book") {
                    openWindow(id: "addBookWindow")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }
                .disabled(appState.isCheckingForUpdates)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    readerApp.showSettingsWindow(appState: appState) {
                        appState.checkForAppUpdates(isUserInitiated: true)
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    // MARK: Preferences Window
    static func showSettingsWindow(appState: AppState, checkForUpdates: @escaping () -> Void) {
        if preferencesWindow == nil {
            let settingsView = SettingsView(checkForUpdates: {
                checkForUpdates()
            }).environmentObject(appState)
            
            let aboutView = AboutView().environmentObject(appState)
            
            preferencesWindow = SettingsWindowController(
                panes: [
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("general"),
                        title: "General",
                        toolbarIcon: {
                            let originalImage = NSImage(named: "squareGear")!
                            let paddedSize = NSSize(width: 24, height: 24)
                            let innerSize = NSSize(width: 18, height: 18)
                            
                            let paddedImage = NSImage(size: paddedSize)
                            paddedImage.lockFocus()
                            
                            let xOffset = (paddedSize.width - innerSize.width) / 2
                            let yOffset = (paddedSize.height - innerSize.height) / 2
                            originalImage.draw(
                                in: NSRect(x: xOffset, y: yOffset, width: innerSize.width, height: innerSize.height),
                                from: .zero,
                                operation: .sourceOver,
                                fraction: 1.0
                            )
                            
                            paddedImage.unlockFocus()
                            paddedImage.isTemplate = true
                            return paddedImage
                        }()
                    ) {
                        settingsView
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("about"),
                        title: "About",
                        toolbarIcon: {
                            let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                            return NSImage(
                                systemSymbolName: "info.square.fill",
                                accessibilityDescription: nil
                            )!.withSymbolConfiguration(config)!
                        }()
                    ) {
                        aboutView
                    }
                ]
            )
        }
        preferencesWindow?.show()
    }
    
    // MARK: Add Book Window
    private var addBookWindow: some Scene {
        Window("Add Book", id: "addBookWindow") {
            AddView()
                .environmentObject(dataManager)
                .environmentObject(appState)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: Helper Functions
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        appState.scheduleDailyUpdateCheck()
    }
}

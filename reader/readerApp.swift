import SwiftUI
import SwiftData
import Settings

@main
struct readerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @StateObject private var viewModel: ContentViewModel
    @StateObject private var overlayManager = OverlayManager()
    
    @Environment(\.openWindow) private var openWindow
    
    private static var preferencesWindow: SettingsWindowController?
    
    private static let sharedModelContainer: ModelContainer? = {
        let schema = Schema([BookData.self, BookCollection.self])
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
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
        
        // Initialize DataManager and ViewModel
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
                .environmentObject(appState)
                .environmentObject(overlayManager)
                .environment(\.modelContainer, readerApp.sharedModelContainer!)
                .onAppear {
                    appState.viewModel = viewModel
                    handleOnAppear()
                }
                .onDisappear {
                    NSApp.terminate(nil)
                }
        }
        .commands {
            AppCommands.fileCommands { openWindow(id: $0) }
            AppCommands.appInfoCommands(appState: appState)
            AppCommands.settingsCommands(appState: appState)
            AppCommands.deleteCommands(appState: appState, viewModel: viewModel)
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
                        toolbarIcon: createToolbarIcon(named: "squareGear", size: 24)
                    ) {
                        settingsView
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("about"),
                        title: "About",
                        toolbarIcon: createToolbarIcon(systemSymbolName: "info.square.fill", size: 24)
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
                .environmentObject(overlayManager)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: Helpers
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        appState.scheduleDailyUpdateCheck()
    }
    
    private static func createToolbarIcon(named: String? = nil, systemSymbolName: String? = nil, size: CGFloat) -> NSImage {
        if let named = named, let image = NSImage(named: named) {
            return image
        }
        if let systemSymbolName = systemSymbolName {
            let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
            return NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config) ?? NSImage()
        }
        return NSImage()
    }
}

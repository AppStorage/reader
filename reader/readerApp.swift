import SwiftUI
import SwiftData
import Settings
import enum Settings.Settings

@main
struct readerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @StateObject private var alertManager = AlertManager()
    @StateObject private var overlayManager = OverlayManager()
    @StateObject private var contentViewModel: ContentViewModel
    
    @Environment(\.openWindow) private var openWindow
    
    private static var sharedModelContainer: ModelContainer? = {
        let schema = Schema([BookData.self, BookCollection.self])
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            print("Failed to initialize ModelContainer: \(error.localizedDescription)")
            return nil
        }
    }()
    
    private static var preferencesWindow: SettingsWindowController? = nil
    
    // MARK: - Main Window
    private var mainWindow: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(dataManager)
                .environmentObject(alertManager)
                .environmentObject(overlayManager)
                .environmentObject(contentViewModel)
                .environment(\.modelContainer, readerApp.sharedModelContainer!)
                .onAppear {
                    appState.contentViewModel = contentViewModel
                    appState.alertManager = alertManager
                    alertManager.contentViewModel = contentViewModel
                    alertManager.appState = appState
                    handleOnAppear()
                }
                .onDisappear {
                    NSApp.terminate(nil)
                }
        }
        .commands {
            AppCommands.fileCommands(
                appState: appState,
                dataManager: dataManager
            ) { openWindow(id: $0) }
            AppCommands.appInfoCommands(appState: appState)
            AppCommands.settingsCommands(
                appState: appState,
                dataManager: dataManager
            )
            AppCommands.deleteCommands(
                appState: appState,
                contentViewModel: contentViewModel
            )
        }
    }
    
    // MARK: - Add Book Window
    private var addBookWindow: some Scene {
        Window("Add Book", id: "addBookWindow") {
            AddView(viewModel: contentViewModel)
                .environmentObject(appState)
                .environmentObject(overlayManager)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    var body: some Scene {
        mainWindow
        addBookWindow
    }
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        
        guard let container = readerApp.sharedModelContainer else {
            print("ModelContainer is not available. Exiting application.")
            exit(1)
        }
        
        let dataManager = DataManager(modelContainer: container)
        _dataManager = StateObject(wrappedValue: dataManager)
        _contentViewModel = StateObject(wrappedValue: ContentViewModel(dataManager: dataManager))
    }
    
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        appState.scheduleUpdateCheck()
    }
    
    // MARK: - Preferences Icons
    private static func gearToolbarIcon(size: CGFloat = 24, innerSize: CGFloat = 18) -> NSImage {
        let originalImage = NSImage(named: "squareGear") ?? NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!
        let paddedSize = NSSize(width: size, height: size)
        let innerSize = NSSize(width: innerSize, height: innerSize)
        
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
    }
    
    private static func infoToolbarIcon(size: CGFloat = 24) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(
            systemSymbolName: "info.square.fill",
            accessibilityDescription: nil
        )!.withSymbolConfiguration(config)!
    }
    
    private static func manageDataToolbarIcon(size: CGFloat = 24) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(
            systemSymbolName: "icloud.square.fill",
            accessibilityDescription: "Manage Data"
        )!.withSymbolConfiguration(config)!
    }
    
    // MARK: - Preferences Window
    static func showSettingsWindow(appState: AppState, dataManager: DataManager, checkForUpdates: @escaping () -> Void) {
        if preferencesWindow == nil {
            let settingsView = SettingsView(checkForUpdates: {
                checkForUpdates()
            })
                .environmentObject(appState)
                .environmentObject(appState.alertManager!)
            
            let aboutView = AboutView()
                .environmentObject(appState)
            
            let importExportView = ImportExportView()
                .environmentObject(appState)
                .environmentObject(dataManager)
                .environmentObject(appState.alertManager!)
            
            preferencesWindow = SettingsWindowController(
                panes: [
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("general"),
                        title: "General",
                        toolbarIcon: { gearToolbarIcon() }()
                    ) {
                        settingsView
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("import_export"),
                        title: "Manage Data",
                        toolbarIcon: { manageDataToolbarIcon() }()
                    ) {
                        importExportView
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("about"),
                        title: "About",
                        toolbarIcon: { infoToolbarIcon() }()
                    ) {
                        aboutView
                    }
                ]
            )
        }
        preferencesWindow?.window?.center()
        preferencesWindow?.show()
    }
}

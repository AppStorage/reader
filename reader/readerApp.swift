import SwiftUI
import SwiftData
import Settings
import enum Settings.Settings

@main
struct readerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataManager: DataManager
    @StateObject private var viewModel: ContentViewModel
    @StateObject private var overlayManager = OverlayManager()
    
    @Environment(\.openWindow) private var openWindow
    
    private static var preferencesWindow: SettingsWindowController? = nil
    
    private static let sharedModelContainer: ModelContainer? = {
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
    
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        
        guard let container = readerApp.sharedModelContainer else {
            print("ModelContainer is not available. Exiting application.")
            exit(1)
        }
        
        let dataManager = DataManager(modelContainer: container)
        _dataManager = StateObject(wrappedValue: dataManager)
        _viewModel = StateObject(wrappedValue: ContentViewModel(dataManager: dataManager))
    }
    
    var body: some Scene {
        mainWindow
        addBookWindow
    }
    
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
    
    // MARK: Preferencees Window
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
                        toolbarIcon: { gearToolbarIcon() }()
                    ) {
                        settingsView
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
        preferencesWindow?.show()
    }
    
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
    
    private func handleOnAppear() {
        appState.applyTheme(appState.selectedTheme)
        appState.scheduleDailyUpdateCheck()
    }
    
    // MARK: Preferences Icons
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
}

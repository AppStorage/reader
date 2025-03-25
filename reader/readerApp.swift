import SwiftUI
import SwiftData

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
                dataManager: dataManager,
                openWindow: { openWindow(id: $0) }
            )
            
            AppCommands.appInfoCommands(appState: appState)
            
            AppCommands.settingsCommands(openWindow: { openWindow(id: $0) })
            
            AppCommands.deleteCommands(
                appState: appState,
                contentViewModel: contentViewModel
            )
        }
    }
    
    // MARK: - Preferences Window
    private var preferencesWindow: some Scene {
        Window("Preferences", id: "preferencesWindow") {
            PreferencesView()
                .environmentObject(appState)
                .environmentObject(dataManager)
                .environmentObject(alertManager)
                .environmentObject(contentViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    // MARK: - Add Book Window
    private var addBookWindow: some Scene {
        Window("Add Book", id: "addBookWindow") {
            AddView(viewModel: contentViewModel)
                .environmentObject(appState)
                .environmentObject(alertManager)
                .environmentObject(overlayManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    var body: some Scene {
        mainWindow
        addBookWindow
        preferencesWindow
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
}

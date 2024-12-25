import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @StateObject private var appState = AppState()
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var selectedStatus: StatusFilter?
    
    var body: some View {
        List(selection: $selectedStatus) {
            readingStatusSection
        }
        .listStyle(.sidebar)
        .onChange(of: selectedStatus) { oldValue, newValue in
            if let newValue = newValue {
                viewModel.selectedStatus = newValue
            }
        }
        
        HStack {
            SettingsButton {
                readerApp.showSettingsWindow(appState: appState) {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }
            }
            Spacer()
        }
    }
    
    private var readingStatusSection: some View {
        Section(header: Text("Reading Status")) {
            ForEach(StatusFilter.allCases) { status in
                Label(status.rawValue, systemImage: status.iconName)
                    .badge(viewModel.bookCount(for: status))
                    .tag(status)
            }
        }
    }
}

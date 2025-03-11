import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var checkForUpdates: () -> Void
    
    @State private var isCheckingManually = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Form {
            Section {
                updateToggleRow
                
                if appState.checkForUpdatesAutomatically {
                    frequencyPicker
                }
            }
            
            Section {
                checkForUpdatesButton
                updateStatusView
            }
            
            Section {
                Picker("Theme", selection: $appState.selectedTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .formStyle(.grouped)
        .animation(.easeInOut(duration: 0.2), value: appState.checkForUpdatesAutomatically)
        .animation(.easeInOut(duration: 0.3), value: appState.alertType != nil)
        .frame(width: 400, height: 300)
        .onDisappear {
            releaseSettingsWindowResources()
        }
    }
    
    private var updateToggleRow: some View {
        Toggle(isOn: $appState.checkForUpdatesAutomatically) {
            Label {
                Text("Automatic Updates")
            } icon: {
                Image(systemName: "arrow.clockwise")
                    .symbolVariant(.circle.fill)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var frequencyPicker: some View {
        Picker("Check Frequency", selection: $appState.updateCheckFrequency) {
            Text("Daily").tag(86400.0)
            Text("Weekly").tag(604800.0)
            Text("Monthly").tag(2592000.0)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var checkForUpdatesButton: some View {
        Button {
            isCheckingManually = true
            Task {
                // Don't show alert in preferences, show the status in the UI instead
                appState.checkForAppUpdates(isUserInitiated: true, showAlert: false)
                try? await Task.sleep(for: .seconds(0.5))
                isCheckingManually = false
            }
        } label: {
            HStack {
                Spacer()
                Group {
                    if appState.isCheckingForUpdates || isCheckingManually {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 5)
                        Text("Checking...")
                    } else {
                        Text("Check for Updates")
                    }
                }
                .font(.body)
                .foregroundStyle(colorScheme == .dark ? .white : .blue)
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .disabled(appState.isCheckingForUpdates || isCheckingManually)
    }
    
    @ViewBuilder
    private var updateStatusView: some View {
        switch appState.lastCheckStatus {
        case .updateAvailable:
            if let version = appState.latestVersion {
                Button {
                    if let downloadURL = appState.downloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Version \(version) Available", systemImage: "arrow.down.app")
                            .symbolVariant(.fill)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .buttonStyle(.borderless)
            }
            
        case .error(let message):
            HStack {
                Spacer()
                Label("Error: \(message)", systemImage: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            
        case .upToDate:
            HStack {
                Spacer()
                Label("You're up to date", systemImage: "checkmark.circle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.green)
                Spacer()
            }
            
        case .unknown, .checking:
            EmptyView()
        }
    }
    
    // MARK: Cleanup
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { rawValue }
}

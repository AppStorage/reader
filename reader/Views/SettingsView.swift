import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var checkForUpdates: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            SettingsForm
        }
        .padding()
        .frame(width: 400, height: 300)
        .onDisappear {
            releaseSettingsWindowResources()
        }
    }
    
    // MARK: Settings Form
    private var SettingsForm: some View {
        Form {
            updateSection
            appearanceSection
        }
        .formStyle(.grouped)
    }
    
    // MARK: Update Section
    private var updateSection: some View {
        Section {
            Toggle(isOn: $appState.checkForUpdatesAutomatically) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise.square.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Text("Check for Updates Automatically")
                }
            }
            
            // Subtext when enabled
            if appState.checkForUpdatesAutomatically {
                Text("Updates will be checked once a day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Manual check for updates button
            HStack {
                Spacer()
                Button(action: {
                    appState.checkForAppUpdates(isUserInitiated: true)
                }) {
                    if appState.isCheckingForUpdates {
                        HStack(spacing: 5) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking...")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .regular))
                            Text("Check for Updates")
                                .font(.system(size: 13, weight: .regular))
                        }
                    }
                }
                .buttonStyle(.borderless)
                .disabled(appState.isCheckingForUpdates)
                Spacer()
            }
        }
    }
    
    // MARK: Appearance Section
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $appState.selectedTheme) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.rawValue.capitalized).tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
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

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading) {
            SettingsHeader
            SettingsForm
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear(perform: adjustWindowAppearance)
    }
    
    // MARK: - Header
    private var SettingsHeader: some View {
        Text("Settings")
            .font(.system(size: 20, weight: .semibold, design: .default))
            .padding(.bottom, 10)
    }
    
    // MARK: - Settings Form
    private var SettingsForm: some View {
        Form {
            // Update settings section
            updateSection
            
            // Appearance settings section
            appearanceSection
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Update Section
    private var updateSection: some View {
        Section {
            Toggle("Check for Updates Automatically", isOn: $appState.checkForUpdatesAutomatically)
            
            if appState.checkForUpdatesAutomatically {
                Text("Updates will be checked once a day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Appearance Section
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
    
    // MARK: - Window Adjustment
    private func adjustWindowAppearance() {
        if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
            window.styleMask.remove(.miniaturizable)
            window.canHide = false
        }
    }
}

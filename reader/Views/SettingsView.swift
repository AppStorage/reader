import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading) {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold, design: .default))
                .padding(.bottom, 10)

            Form {
                Section {
                    Toggle("Check for Updates Automatically", isOn: $appState.checkForUpdatesAutomatically)

                    if appState.checkForUpdatesAutomatically {
                        Text("Updates will be checked once a day.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                SwiftUI.Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appState.selectedTheme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .formStyle(.grouped)
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
                window.styleMask.remove(.miniaturizable)
                window.canHide = false
            }
        }
    }
}

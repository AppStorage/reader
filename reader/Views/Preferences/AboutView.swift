import SwiftUI

struct AboutView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Match style with SettingsView
            Form { }
                .formStyle(.grouped)
                .opacity(0)
            
            VStack(spacing: 20) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
                
                Text("Inkwell")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 10)
                
                VStack(spacing: 5) {
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(copyright)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    AboutButtons(
                        title: "GitHub",
                        systemImage: "link",
                        url: "https://github.com/chippokiddo/reader"
                    )
                    AboutButtons(
                        title: "Support",
                        systemImage: "cup.and.saucer",
                        url: "https://www.buymeacoffee.com/chippo"
                    )
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(30)
            .onAppear {
                if let window = NSApp.windows.first(where: { $0.title == "About Inkwell" }) {
                    window.styleMask.remove(.miniaturizable)
                    window.canHide = false
                }
            }
            .onDisappear {
                releaseSettingsWindowResources()
            }
        }
    }
    
    // MARK: - App Version
    private var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(shortVersion) (\(buildNumber))"
    }

    // MARK: - Copyright Text
    private var copyright: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© chip"
    }
    
    // MARK: - Cleanup
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

import SwiftUI
import Foundation

struct AboutView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Match style with SettingsView
            Form { }
                .formStyle(.grouped)
                .opacity(0)
            
            VStack(spacing: 20) {
                // App Icon
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
                
                Text("reader")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 10)
                
                VStack(spacing: 5) {
                    Text("Version \(Bundle.main.appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(Bundle.main.copyrightText)
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
            .frame(width: 400, height: 320)
            .onAppear {
                if let window = NSApp.windows.first(where: { $0.title == "About reader" }) {
                    window.styleMask.remove(.miniaturizable)
                    window.canHide = false
                }
            }
            .onDisappear {
                releaseSettingsWindowResources()
            }
        }
    }
    
    // MARK: Cleanup
    private func releaseSettingsWindowResources() {
        appState.cleanupPreferencesCache()
    }
}

extension Bundle {
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var copyrightText: String {
        return Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "Copyright © chip"
    }
}

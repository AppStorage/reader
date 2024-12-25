import SwiftUI

extension AlertType {
    @MainActor func createAlert(appState: AppState) -> Alert {
        switch self {
        case .newUpdateAvailable:
            return Alert(
                title: Text("New Update Available"),
                message: Text("reader \(appState.latestVersion ?? "unknown") is available. Would you like to download it?"),
                primaryButton: .default(Text("Download")) {
                    if let downloadURL = appState.downloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                },
                secondaryButton: .cancel(Text("Later"))
            )
        case .upToDate:
            return Alert(
                title: Text("No Updates Available"),
                message: Text("You are already on the latest version."),
                dismissButton: .default(Text("OK"))
            )
        case .error(let errorDetails):
            return Alert(
                title: Text("Error"),
                message: Text(errorDetails),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

enum AlertType: Identifiable {
    case newUpdateAvailable
    case upToDate
    case error(String)
    
    var id: String {
        switch self {
        case .newUpdateAvailable: return "newUpdateAvailable"
        case .upToDate: return "upToDate"
        case .error(let message): return "error-\(message)"
        }
    }
}

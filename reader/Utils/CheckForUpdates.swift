import Foundation
import AppKit

struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [Asset]
    
    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
    
    struct Asset: Decodable {
        let browserDownloadURL: URL
        
        private enum CodingKeys: String, CodingKey {
            case browserDownloadURL = "browser_download_url"
        }
    }
}

// Async function to fetch the latest release information from GitHub
func fetchLatestRelease() async throws -> (String, URL) {
    let url = URL(string: "https://api.github.com/repos/chippokiddo/reader/releases/latest")!
    var request = URLRequest(url: url)
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    
    // Perform the network request
    let (data, _) = try await URLSession.shared.data(for: request)
    
    // Decode the JSON response
    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
    
    // Check if there are assets available
    guard let downloadURL = release.assets.first?.browserDownloadURL else {
        // Print the raw JSON response for debugging purposes
        if let jsonString = String(data: data, encoding: .utf8) {
            print("JSON Response: \(jsonString)")
        }
        throw NSError(domain: "GitHubReleaseError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "No assets available in the latest release on GitHub."
        ])
    }
    
    return (release.tagName, downloadURL)
}

// Main function to check for updates, now prompting the user if an update is available
func checkForUpdates() {
    Task { @MainActor in
        do {
            let (latestVersion, downloadURL) = try await fetchLatestRelease()
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            
            if currentVersion != latestVersion {
                print("New update available")
                
                let userWantsToUpdate = await promptForUpdate(latestVersion: latestVersion)
                
                if userWantsToUpdate {
                    print("User opted to update")
                    
                    // Open the browser to the GitHub release downloads page
                    NSWorkspace.shared.open(downloadURL)
                } else {
                    print("User declined the update")
                }
            } else {
                print("Already on the latest version")
            }
        } catch {
            print("Failed to check for updates: \(error.localizedDescription)")
        }
    }
}

// Function to prompt the user for an update, now marked as async and @MainActor
@MainActor
func promptForUpdate(latestVersion: String) async -> Bool {
    let alert = NSAlert()
    alert.messageText = "New Update Available"
    alert.informativeText = "reader \(latestVersion) is available. Would you like to download it?"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Download")
    alert.addButton(withTitle: "Cancel")
    
    let response = alert.runModal()
    return response == .alertFirstButtonReturn // Returns true if "Download" is clicked
}

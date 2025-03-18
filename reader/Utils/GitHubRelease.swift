import Foundation
import AppKit

// MARK: - GitHub Release Errors
private enum GitHubReleaseError: Error {
    case noAssetsAvailable
    case invalidResponse
    case decodingError(String)
}

// MARK: - Coding Keys
private enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case assets
}

// MARK: - GitHub Release
struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [Asset]
    
    struct Asset: Decodable {
        let browserDownloadURL: URL
        
        private enum CodingKeys: String, CodingKey {
            case browserDownloadURL = "browser_download_url"
        }
    }
}

// MARK: - Fetch Latest Release
// Async function to fetch the latest release information from GitHub
func fetchLatestRelease() async throws -> (String, URL) {
    let url = URL(string: "https://api.github.com/repos/chippokiddo/reader/releases/latest")!
    var request = URLRequest(url: url)
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.timeoutInterval = 15
    
    // Perform the network request
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // Validate HTTP response
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw GitHubReleaseError.invalidResponse
    }
    
    do {
        // Decode the JSON response
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        
        // Check if there are assets available
        guard let downloadURL = release.assets.first?.browserDownloadURL else {
            throw GitHubReleaseError.noAssetsAvailable
        }
        
        return (release.tagName, downloadURL)
    } catch {
        throw GitHubReleaseError.decodingError(error.localizedDescription)
    }
}

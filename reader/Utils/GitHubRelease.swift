import Foundation
import AppKit

// MARK: - GitHub Release Errors
private enum GitHubReleaseError: Error, LocalizedError {
    case noAssetsAvailable
    case invalidResponse
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAssetsAvailable:
            return "No downloadable assets were found in the latest GitHub release."
        case .invalidResponse:
            return "Received an invalid response from GitHub."
        case .decodingError(let details):
            return "Failed to decode release info: \(details)"
        }
    }
}

// MARK: - GitHub Asset
struct GitHubAsset: Decodable {
    let browserDownloadUrl: URL
}

// MARK: - GitHub Release
struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]
}

// MARK: - Fetch Latest Release
func fetchLatestRelease() async throws -> (String, URL) {
    let url = URL(string: "https://api.github.com/repos/chippokiddo/reader/releases/latest")!
    var request = URLRequest(url: url)
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.addValue("Inkwell/1.23.0", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 15
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw GitHubReleaseError.invalidResponse
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let release = try decoder.decode(GitHubRelease.self, from: data)
        
        guard let downloadURL = release.assets.first?.browserDownloadUrl else {
            throw GitHubReleaseError.noAssetsAvailable
        }
        
        return (release.tagName, downloadURL)
    } catch {
        throw GitHubReleaseError.decodingError(error.localizedDescription)
    }
}

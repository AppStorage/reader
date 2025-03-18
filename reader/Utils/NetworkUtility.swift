import Foundation

// MARK: - Network Errors
enum NetworkError: Error {
    case badURL
    case requestFailed(statusCode: Int)
    case emptyResponse
    case parsingFailed(Error)
    case rateLimited
    case serverError(statusCode: Int)
    case unknown(Error)
}

// MARK: - Network Utility
struct NetworkUtility {
    static func retryFetch<T: Sendable>(
        url: URL,
        retries: Int,
        backoffFactor: Double = 1.5,
        initialDelay: UInt64 = 500_000_000, // 500 ms
        parse: @escaping (Data) async throws -> T?
    ) async -> Result<T, NetworkError> {
        var delay = initialDelay
        
        for attempt in 1...max(1, retries) {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Handle HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        // Success case
                        break
                    case 429:
                        // Rate limited - apply exponential backoff
                        if attempt < retries {
                            try await Task.sleep(nanoseconds: delay)
                            delay = UInt64(Double(delay) * backoffFactor)
                            continue
                        } else {
                            return .failure(.rateLimited)
                        }
                    case 400...499:
                        return .failure(.requestFailed(statusCode: httpResponse.statusCode))
                    case 500...599:
                        return .failure(.serverError(statusCode: httpResponse.statusCode))
                    default:
                        return .failure(.requestFailed(statusCode: httpResponse.statusCode))
                    }
                }
                
                // Check for empty data
                guard !data.isEmpty else {
                    return .failure(.emptyResponse)
                }
                
                // Parse the data
                do {
                    if let result = try await parse(data) {
                        return .success(result)
                    } else {
                        return .failure(.parsingFailed(URLError(.cannotParseResponse)))
                    }
                } catch {
                    return .failure(.parsingFailed(error))
                }
            } catch {
                if attempt < retries {
                    try? await Task.sleep(nanoseconds: delay)
                    delay = UInt64(Double(delay) * backoffFactor)
                } else {
                    return .failure(.unknown(error))
                }
            }
        }
        
        return .failure(.unknown(URLError(.unknown)))
    }
}

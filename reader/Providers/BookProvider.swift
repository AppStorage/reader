import Foundation

enum BookProviderError: Error {
    case emptyQuery
    case invalidURL
    case apiError(NetworkError)
    case parsingError(Error)
    case unauthorized
}

protocol BookProvider {
    func fetchBooks(title: String, author: String, isbn: String?, limit: Int, retries: Int) async -> Result<[BookTransferData], BookProviderError>
}

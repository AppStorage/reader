import Foundation

struct URLBuilder {
    static func constructGoogleBooksURL(apiKey: String, parameters: [String: String]) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        components?.queryItems?.append(URLQueryItem(name: "key", value: apiKey))
        return components?.url
    }
    
    static func constructOpenLibraryURL(title: String, author: String, isbn: String?) -> URL? {
        let query = isbn != nil
        ? "bibkeys=ISBN:\(isbn!)"
        : "q=\(title)+\(author)"
        let urlString = isbn != nil
        ? "https://openlibrary.org/api/books?\(query)&format=json&jscmd=data"
        : "https://openlibrary.org/search.json?\(query)"
        return URL(string: urlString)
    }
}

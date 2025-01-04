import Foundation

struct URLBuilder {
    static func constructGoogleBooksURL(apiKey: String, parameters: [String: String]) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        if !parameters.keys.contains("key") {
            components?.queryItems?.append(URLQueryItem(name: "key", value: apiKey))
        }
        return components?.url
    }
    
    static func constructOpenLibraryURL(title: String?, author: String?, isbn: String?, limit: Int = 10, page: Int = 1) -> URL? {
        var components = URLComponents(string: "https://openlibrary.org/search.json")
        var queryItems: [URLQueryItem] = []
        
        if let isbn = isbn {
            components = URLComponents(string: "https://openlibrary.org/api/books")
            queryItems.append(URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"))
            queryItems.append(URLQueryItem(name: "format", value: "json"))
            queryItems.append(URLQueryItem(name: "jscmd", value: "data"))
        } else {
            if let title = title, !title.isEmpty {
                queryItems.append(URLQueryItem(name: "title", value: title))
            }
            if let author = author, !author.isEmpty {
                queryItems.append(URLQueryItem(name: "author", value: author))
            }
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
            queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }
}

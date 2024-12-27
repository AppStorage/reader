import Foundation

struct URLBuilder {
    static func constructGoogleBooksURL(apiKey: String, parameters: [String: String]) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = parameters.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return URLQueryItem(name: key, value: encodedValue)
        }
        components?.queryItems?.append(URLQueryItem(name: "key", value: apiKey))
        return components?.url
    }
    
    static func constructOpenLibraryURL(title: String?, author: String?, isbn: String?, limit: Int = 10, page: Int = 1) -> URL? {
        var queryItems: [String] = []
        
        // ISBN-based query (prioritized if ISBN is provided)
        if let isbn = isbn {
            queryItems.append("bibkeys=ISBN:\(isbn)")
            let urlString = "https://openlibrary.org/api/books?\(queryItems.joined(separator: "&"))&format=json&jscmd=data"
            return URL(string: urlString)
        }
        
        // Title and Author-based query
        if let title = title {
            queryItems.append("title=\(title)")
        }
        if let author = author {
            queryItems.append("author=\(author)")
        }
        
        // Add limit and pagination parameters
        queryItems.append("limit=\(limit)")
        queryItems.append("page=\(page)")
        
        // Construct search URL
        let query = queryItems.joined(separator: "&")
        let urlString = "https://openlibrary.org/search.json?\(query)"
        return URL(string: urlString)
    }
}

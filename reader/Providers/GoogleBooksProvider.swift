import Foundation

actor GoogleBooksProvider: BookProvider {
    private let apiKey: String
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchBooks(title: String, author: String, isbn: String? = nil, limit: Int = 10, retries: Int = 3) async -> Result<[BookTransferData], BookProviderError> {
        guard !apiKey.isEmpty else {
            return .failure(.unauthorized)
        }
        
        // Construct the query parameters directly since AddView and BooksAPIService already handle empty queries
        let parameters = constructQueryParameters(title: title, author: author, isbn: isbn, limit: limit)
        
        // Only validate the final query string
        if parameters["q"]?.isEmpty ?? true {
            return .failure(.emptyQuery)
        }
        
        guard let url = constructURL(parameters: parameters) else {
            return .failure(.invalidURL)
        }
        
        // Perform the network request with retry logic
        let networkResult = await NetworkUtility.retryFetch(url: url, retries: retries) { data in
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                
                let result = try decoder.decode(GoogleBooksResponse.self, from: data)
                return result.items?.compactMap { item in
                    Self.constructBookTransferDataStatic(from: item.volumeInfo)
                } ?? []
            } catch {
                throw NetworkError.parsingFailed(error)
            }
        }
        
        // Map the network result to our provider result
        switch networkResult {
        case .success(let books):
            return .success(books)
        case .failure(let error):
            return .failure(.apiError(error))
        }
    }
    
    private func constructQueryParameters(title: String, author: String, isbn: String?, limit: Int) -> [String: String] {
        var queryParts = [String]()
        
        // Add title to query if provided
        if !title.isEmpty {
            queryParts.append("intitle:\(title)")
        }
        
        // Add author to query if provided
        if !author.isEmpty {
            queryParts.append("inauthor:\(author)")
        }
        
        // Add ISBN to query if provided
        if let isbn = isbn, !isbn.isEmpty {
            queryParts.append("isbn:\(isbn)")
        }
        
        let queryString = queryParts.joined(separator: "+")
        
        return [
            "q": queryString,
            "maxResults": "\(limit)",
            "projection": "full",
            "key": apiKey
        ]
    }
    
    private func constructURL(parameters: [String: String]) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = parameters.compactMap { key, value in
            guard !value.isEmpty else { return nil }
            return URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
        }
        
        return components?.url
    }
    
    // Make this static to avoid actor isolation issues
    static func constructBookTransferDataStatic(from bookInfo: VolumeInfo) -> BookTransferData {
        return BookTransferData(
            title: bookInfo.fullTitle,
            author: bookInfo.authors?.joined(separator: ", ") ?? "",
            published: bookInfo.parsedPublishedDate,
            publisher: bookInfo.publisher ?? "",
            genre: bookInfo.primaryCategory ?? "",
            series: bookInfo.series,
            isbn: bookInfo.primaryISBN(),
            bookDescription: bookInfo.sanitizedDescription,
            status: "unread",
            dateStarted: nil,
            dateFinished: nil,
            quotes: [],
            notes: [],
            tags: []
        )
    }
}

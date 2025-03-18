import Foundation

actor OpenLibraryProvider: BookProvider {
    private let searchBaseURL = "https://openlibrary.org/search.json"
    private let booksBaseURL = "https://openlibrary.org/api/books"
    private let detailsBaseURL = "https://openlibrary.org"
    
    func fetchBooks(title: String, author: String, isbn: String? = nil, limit: Int = 10, retries: Int = 3) async -> Result<[BookTransferData], BookProviderError> {
        // Validation happens at the AddView and BooksAPIService
        guard let url = constructURL(title: title, author: author, isbn: isbn, limit: limit) else {
            return .failure(.invalidURL)
        }
        
        if let isbn = isbn, !isbn.isEmpty {
            let result = await NetworkUtility.retryFetch(url: url, retries: retries) { data in
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let bookData = json["ISBN:\(isbn)"] as? [String: Any] else {
                        return [] as [BookTransferData]
                    }
                    
                    let title = bookData["title"] as? String ?? "Unknown Title"
                    let authors = (bookData["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
                    let publishers = (bookData["publishers"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
                    let publishDate = bookData["publish_date"] as? String
                    
                    var description = ""
                    if let excerpts = bookData["excerpts"] as? [[String: Any]], let first = excerpts.first {
                        description = first["text"] as? String ?? ""
                    }
                    
                    return [
                        BookTransferData(
                            title: title,
                            author: authors.joined(separator: ", "),
                            published: parseDate(publishDate),
                            publisher: publishers.first,
                            genre: nil,
                            series: nil,
                            isbn: isbn,
                            bookDescription: sanitizeDescription(description),
                            status: "unread",
                            dateStarted: nil,
                            dateFinished: nil,
                            quotes: [],
                            notes: [],
                            tags: []
                        )
                    ]
                } catch {
                    throw NetworkError.parsingFailed(error)
                }
            }
            
            switch result {
            case .success(let books):
                return .success(books)
            case .failure(let error):
                return .failure(.apiError(error))
            }
        } else {
            // Handle title or author search
            let result = await NetworkUtility.retryFetch(url: url, retries: retries) { data -> [BookTransferData] in
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
                    
                    guard !result.docs.isEmpty else {
                        return []
                    }
                    
                    // Process results using task group
                    let books = await withTaskGroup(of: BookTransferData?.self) { group -> [BookTransferData] in
                        for doc in result.docs.prefix(min(10, limit)) {
                            group.addTask {
                                await Self.constructBookTransferDataStatic(from: doc, isbn: isbn)
                            }
                        }
                        
                        var results = [BookTransferData]()
                        for await book in group {
                            if let book = book {
                                results.append(book)
                            }
                        }
                        return results
                    }
                    
                    return books
                } catch {
                    throw NetworkError.parsingFailed(error)
                }
            }
            
            switch result {
            case .success(let books):
                return .success(books)
            case .failure(let error):
                return .failure(.apiError(error))
            }
        }
    }
    
    func fetchDescription(olid: String, retries: Int = 3) async -> Result<String, NetworkError> {
        let urlString = "\(detailsBaseURL)\(olid).json"
        guard let url = URL(string: urlString) else {
            return .failure(.badURL)
        }
        
        return await NetworkUtility.retryFetch(url: url, retries: retries) { data in
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let description = json?["description"] as? String {
                return description
            } else if let descriptionObject = json?["description"] as? [String: Any],
                      let value = descriptionObject["value"] as? String {
                return value
            }
            return "" // Return empty string instead of nil for consistency
        }
    }
    
    private func constructURL(title: String?, author: String?, isbn: String?, limit: Int = 10, page: Int = 1) -> URL? {
        // Handle ISBN search differently than title or author search
        if let isbn = isbn, !isbn.isEmpty {
            var components = URLComponents(string: booksBaseURL)
            let queryItems = [
                URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn)"),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "jscmd", value: "data")
            ]
            components?.queryItems = queryItems
            return components?.url
        } else {
            var components = URLComponents(string: searchBaseURL)
            var queryItems: [URLQueryItem] = []
            
            // Only add title and author if they're not empty
            if let title = title, !title.isEmpty {
                queryItems.append(URLQueryItem(name: "title", value: title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))
            }
            
            if let author = author, !author.isEmpty {
                queryItems.append(URLQueryItem(name: "author", value: author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))
            }
            
            // Only perform search if there is at least one search parameter
            if !queryItems.isEmpty {
                queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
                queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
                components?.queryItems = queryItems
                return components?.url
            }
        }
        
        return nil
    }
    
    // Static method to avoid actor isolation issues
    static func constructBookTransferDataStatic(from doc: OpenLibraryDoc, isbn: String?) async -> BookTransferData? {
        // Get description if there is an OLID
        var descriptionText = ""
        if let olid = doc.key {
            let urlString = "https://openlibrary.org\(olid).json"
            if let url = URL(string: urlString) {
                // Use NetworkUtility for consistent retry strategy
                let result = await NetworkUtility.retryFetch(url: url, retries: 3) { data in
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        if let description = json?["description"] as? String {
                            return description
                        } else if let descriptionObject = json?["description"] as? [String: Any],
                                  let value = descriptionObject["value"] as? String {
                            return value
                        }
                        return "" // Empty string if no description found
                    } catch {
                        return "" // Return empty string on parsing error
                    }
                }
                
                // Extract description text from result
                if case .success(let description) = result {
                    descriptionText = description
                }
            }
        }
        
        // Create a published date
        let publishedDate: Date? = doc.first_publish_year.flatMap {
            Calendar.current.date(from: DateComponents(year: $0))
        }
        
        return BookTransferData(
            title: doc.title,
            author: doc.author_name?.joined(separator: ", ") ?? "Unknown Author",
            published: publishedDate,
            publisher: doc.publisher?.first,
            genre: doc.subject?.first,
            series: nil,
            isbn: doc.isbn?.first ?? isbn,
            bookDescription: sanitizeDescription(descriptionText),
            status: "unread",
            dateStarted: nil,
            dateFinished: nil,
            quotes: [],
            notes: [],
            tags: []
        )
    }
}

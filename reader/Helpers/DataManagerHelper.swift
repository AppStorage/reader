import SwiftUI

// Parses a date string into a Date object, supporting multiple formats
func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString, !dateString.isEmpty else { return nil }
    let dateFormatter = DateFormatter()
    
    // Supported date formats
    let formats = ["yyyy-MM-dd", "yyyy-MM", "yyyy"]
    for format in formats {
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
    }
    return nil
}

func sanitizeDescription(_ description: String?) -> String? {
    guard let description = description else { return nil }
    
    var sanitized = description
        .replacingOccurrences(of: "<br>", with: "\n")
        .replacingOccurrences(of: "</p>", with: "\n")
        .replacingOccurrences(of: "<p>", with: "")
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
    
    if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
        sanitized = regex.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: NSRange(location: 0, length: sanitized.utf16.count),
            withTemplate: ""
        )
    }
    
    return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
}

// Constructs a Google Books API query URL from query parameters
func constructQueryURL(apiKey: String, queryParameters: [String: String]) -> URL? {
    let query = queryParameters.compactMap { key, value in
        value.isEmpty ? nil : "\(key):\(value)"
    }.joined(separator: " ")
    
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    
    return URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&key=\(apiKey)")
}

// Matches a book against input criteria (title, author, ISBN, etc.)
func matchBook(
    bookInfo: VolumeInfo,
    title: String,
    author: String,
    publishedDate: String?,
    inputISBN: String?,
    publisher: String?
) -> Bool {
    // Mandatory checks
    let titleMatches = bookInfo.title.localizedCaseInsensitiveContains(title)
    let authorMatches = bookInfo.authors?.contains(where: { $0.localizedCaseInsensitiveContains(author) }) ?? false
    
    // Optional checks
    let isbnMatches = inputISBN == nil || (bookInfo.industryIdentifiers?.contains { $0.identifier == inputISBN }) ?? false
    let publisherMatches = publisher == nil || (bookInfo.publisher?.localizedCaseInsensitiveContains(publisher ?? "") ?? false)
    let dateMatches = publishedDate == nil || bookInfo.publishedDate == publishedDate
    
    // Ensure all conditions are met
    return titleMatches && authorMatches && isbnMatches && publisherMatches && dateMatches
}

// Open Library as fallback
func parseOpenLibraryBookData(_ bookData: [String: Any], isbn: String?) -> BookData? {
    let title = bookData["title"] as? String ?? "Unknown Title"
    let authors = (bookData["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String }.joined(separator: ", ") ?? "Unknown Author"
    let publisher = (bookData["publishers"] as? [[String: Any]])?.compactMap { $0["name"] as? String }.first
    let publishDate = bookData["publish_date"] as? String
    
    let description: String? = {
        if let desc = bookData["description"] as? String {
            return desc
        } else if let descDict = bookData["description"] as? [String: Any] {
            return descDict["value"] as? String
        }
        return nil
    }()
    
    let genres = (bookData["subjects"] as? [[String: Any]])?.compactMap { $0["name"] as? String }.joined(separator: ", ")
    
    return BookData(
        title: title,
        author: authors,
        published: parseDate(publishDate),
        publisher: publisher,
        genre: genres,
        series: nil,
        isbn: isbn,
        bookDescription: description,
        status: .unread
    )
}

func parseOpenLibrarySearchResult(_ result: OpenLibraryDoc) -> BookData {
    return BookData(
        title: result.title,
        author: result.author_name?.joined(separator: ", ") ?? "Unknown Author",
        published: result.first_publish_year != nil ? DateFormatter().date(from: "\(result.first_publish_year!)") : nil,
        publisher: result.publisher?.first,
        genre: result.subject?.joined(separator: ", "),
        series: nil,
        isbn: result.isbn?.first,
        bookDescription: nil,
        status: .unread
    )
}

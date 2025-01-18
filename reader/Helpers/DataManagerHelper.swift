import SwiftUI

func parseDate(_ dateString: String?) -> Date? {
    guard let dateString, !dateString.isEmpty else { return nil }
    
    let dateFormatter = DateFormatter()
    let formats = ["yyyy-MM-dd", "yyyy-MM", "yyyy"]
    
    for format in formats {
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: dateString) {
            return date // Return immediately on first match
        }
    }
    
    return nil // Return nil if no formats match
}

func sanitizeDescription(_ description: String?) -> String? {
    guard let description, !description.isEmpty else { return nil }
    
    // Define reusable regex patterns and replacements
    let replacements: [String: String] = [
        "<br>": "\n\n",
        "</p>": "\n\n",
        "<p>": "",
        "&nbsp;": " ",
        "&amp;": "&",
        "&quot;": "\"",
        "&#39;": "'"
    ]
    
    // Apply replacements using reduce
    var sanitized = replacements.reduce(description) { result, replacement in
        result.replacingOccurrences(of: replacement.key, with: replacement.value)
    }
    
    // Precompile the regex for removing HTML tags
    let htmlTagRegex = try? NSRegularExpression(pattern: "<[^>]+>", options: [])
    sanitized = htmlTagRegex?.stringByReplacingMatches(
        in: sanitized,
        options: [],
        range: NSRange(location: 0, length: sanitized.utf16.count),
        withTemplate: ""
    ) ?? sanitized
    
    return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
}

// Constructs a Google Books API query URL from query parameters
func constructQueryURL(apiKey: String, queryParameters: [String: String]) -> URL? {
    // Combine query parameters into a string
    let query = queryParameters.compactMap { key, value in
        value.isEmpty ? nil : "\(key):\(value)"
    }.joined(separator: " ")
    
    // Percent-encode the query
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    
    // Construct and return the full URL
    return URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&key=\(apiKey)")
}

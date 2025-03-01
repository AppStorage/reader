import Foundation

func sanitizeDescription(_ description: String?) -> String? {
    guard let description, !description.isEmpty else { return nil }
    
    let replacements: [String: String] = [
        "<br>": "\n\n",
        "</p>": "\n\n",
        "<p>": "",
        "&nbsp;": " ",
        "&amp;": "&",
        "&quot;": "\"",
        "&#39;": "'"
    ]
    
    var sanitized = replacements.reduce(description) { result, replacement in
        result.replacingOccurrences(of: replacement.key, with: replacement.value)
    }
    
    let htmlTagRegex = try? NSRegularExpression(pattern: "<[^>]+>", options: [])
    sanitized = htmlTagRegex?.stringByReplacingMatches(
        in: sanitized,
        options: [],
        range: NSRange(location: 0, length: sanitized.utf16.count),
        withTemplate: ""
    ) ?? sanitized
    
    return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
}

func constructQueryURL(apiKey: String, queryParameters: [String: String]) -> URL? {
    let query = queryParameters.compactMap { key, value in
        value.isEmpty ? nil : "\(key):\(value)"
    }.joined(separator: " ")
    
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    
    return URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&key=\(apiKey)")
}

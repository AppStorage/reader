import SwiftUI

// MARK: - Search Suggestions Container
struct SearchSuggestionContainer: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        if contentViewModel.searchQuery.isEmpty {
            EmptyQuerySuggestions(contentViewModel: contentViewModel)
        } else if contentViewModel.searchQuery.lowercased().hasPrefix("author:") {
            AuthorSuggestions(contentViewModel: contentViewModel)
        } else if contentViewModel.searchQuery.hasPrefix("#") {
            TagSuggestions(contentViewModel: contentViewModel)
        } else if contentViewModel.searchQuery.lowercased().hasPrefix("title:") {
            TitleSuggestions(contentViewModel: contentViewModel)
        } else {
            MatchingRecentSearches(contentViewModel: contentViewModel)
        }
    }
}

// MARK: - Search Prefix List
private struct PrefixList: View {
    var body: some View {
        Section("Search by") {
            Label("title:", systemImage: "book.closed")
                .searchCompletion("title:")
            
            Label("author:", systemImage: "person")
                .searchCompletion("author:")
            
            Label("#", systemImage: "tag")
                .searchCompletion("#")
        }
    }
}

// MARK: - Suggestions List
private struct SuggestionsList: View {
    let suggestions: [String]
    let prefix: String
    let icon: String?
    let emptyMessage: String?
    
    var body: some View {
        if suggestions.isEmpty {
            if let emptyMessage = emptyMessage {
                Text(emptyMessage)
            }
        } else {
            ForEach(suggestions, id: \.self) { item in
                if let icon = icon {
                    Label("\(prefix)\(item)", systemImage: icon)
                        .searchCompletion("\(prefix)\(item)")
                } else {
                    Text("\(prefix)\(item)")
                        .searchCompletion("\(prefix)\(item)")
                }
            }
        }
    }
}

// MARK: - Empty Query Suggestions
private struct EmptyQuerySuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel

    var body: some View {
        PrefixList()
        
        let recentSearches = contentViewModel.getRecentSearches()
        
        if !recentSearches.isEmpty {
            Section(header: Text("Recent Searches")) {
                SuggestionsList(
                    suggestions: recentSearches.prefix(5).map { $0 },
                    prefix: "",
                    icon: "clock",
                    emptyMessage: nil
                )
                
                Button("Clear") {
                    contentViewModel.clearRecentSearches()
                }
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Author Suggestions
// When using the author: prefix
private struct AuthorSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel

    var body: some View {
        let query = contentViewModel.searchQuery.dropFirst(7).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopAuthors(matching: query)
        
        SuggestionsList(
            suggestions: suggestions,
            prefix: "author:",
            icon: nil,
            emptyMessage: "No matching authors found"
        )
    }
}

// MARK: - Tag Suggestions
// When using the # prefix
private struct TagSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel

    var body: some View {
        let query = contentViewModel.searchQuery.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopTags(matching: query)
        
        SuggestionsList(
            suggestions: suggestions,
            prefix: "#",
            icon: "tag",
            emptyMessage: "No matching tags found"
        )
    }
}

// MARK: - Title Suggestions
// When using the title: prefix
private struct TitleSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel

    var body: some View {
        let query = contentViewModel.searchQuery.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopTitles(matching: query)
        
        SuggestionsList(
            suggestions: suggestions,
            prefix: "title:",
            icon: nil,
            emptyMessage: "No matching titles found"
        )
    }
}

// MARK: - Matching Recent Searches
private struct MatchingRecentSearches: View {
    @ObservedObject var contentViewModel: ContentViewModel

    var body: some View {
        let filtered = contentViewModel.getRecentSearches()
            .filter { $0.lowercased().contains(contentViewModel.searchQuery.lowercased()) }

        if !filtered.isEmpty {
            Section("Recent Searches") {
                SuggestionsList(
                    suggestions: filtered.prefix(5).map { $0 },
                    prefix: "",
                    icon: "clock",
                    emptyMessage: nil
                )
            }
        }
    }
}

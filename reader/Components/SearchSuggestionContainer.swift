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

// MARK: - Empty Query Suggestions
struct EmptyQuerySuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        // Show search prefix options
        Section("Search by") {
            Label("title:", systemImage: "book.closed")
                .searchCompletion("title:")
            
            Label("author:", systemImage: "person")
                .searchCompletion("author:")
            
            Label("#", systemImage: "tag")
                .searchCompletion("#")
        }
        
        // Show recent searches with clear option
        let recentSearches = contentViewModel.getRecentSearches()
        if !recentSearches.isEmpty {
            Section {
                ForEach(recentSearches.prefix(5), id: \.self) { search in
                    Label(search, systemImage: "clock")
                        .searchCompletion(search)
                }
                
                Button("Clear") {
                    contentViewModel.clearRecentSearches()
                }
                .foregroundColor(.red)
            } header: {
                Text("Recent Searches")
            }
        }
    }
}

// MARK: - Author Suggestions
// When using the author: prefix
struct AuthorSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        let authorPrefix = contentViewModel.searchQuery.dropFirst(7).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopAuthors(matching: authorPrefix)
        
        if !suggestions.isEmpty {
            ForEach(suggestions, id: \.self) { author in
                Text(author)
                    .searchCompletion("author:\(author)")
            }
        } else {
            Text("No matching authors found")
        }
    }
}

// MARK: - Tag Suggestions
// When using the # prefix
struct TagSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        let tagPrefix = contentViewModel.searchQuery.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopTags(matching: tagPrefix)
        
        if !suggestions.isEmpty {
            ForEach(suggestions, id: \.self) { tag in
                Label("#\(tag)", systemImage: "tag")
                    .searchCompletion("#\(tag)")
            }
        } else {
            Text("No matching tags found")
        }
    }
}

// Title suggestions when using the title: prefix
struct TitleSuggestions: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        let titlePrefix = contentViewModel.searchQuery.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = contentViewModel.getTopTitles(matching: titlePrefix)
        
        if !suggestions.isEmpty {
            ForEach(suggestions, id: \.self) { title in
                Text(title)
                    .searchCompletion("title:\(title)")
            }
        } else {
            Text("No matching titles found")
        }
    }
}

// MARK: - Matching Recent Searches
struct MatchingRecentSearches: View {
    @ObservedObject var contentViewModel: ContentViewModel
    
    var body: some View {
        let recentSearches = contentViewModel.getRecentSearches()
            .filter { $0.lowercased().contains(contentViewModel.searchQuery.lowercased()) }
        
        if !recentSearches.isEmpty {
            Section("Recent Searches") {
                ForEach(recentSearches.prefix(5), id: \.self) { search in
                    Label(search, systemImage: "clock")
                        .searchCompletion(search)
                }
            }
        }
    }
}

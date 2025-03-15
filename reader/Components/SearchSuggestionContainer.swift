import SwiftUI

struct SearchSuggestionContainer: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        if viewModel.searchQuery.isEmpty {
            EmptyQuerySuggestions(viewModel: viewModel)
        } else if viewModel.searchQuery.lowercased().hasPrefix("author:") {
            AuthorSuggestions(viewModel: viewModel)
        } else if viewModel.searchQuery.hasPrefix("#") {
            TagSuggestions(viewModel: viewModel)
        } else if viewModel.searchQuery.lowercased().hasPrefix("title:") {
            TitleSuggestions(viewModel: viewModel)
        } else {
            MatchingRecentSearches(viewModel: viewModel)
        }
    }
}

struct EmptyQuerySuggestions: View {
    @ObservedObject var viewModel: ContentViewModel
    
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
        let recentSearches = viewModel.getRecentSearches()
        if !recentSearches.isEmpty {
            Section {
                ForEach(recentSearches.prefix(5), id: \.self) { search in
                    Label(search, systemImage: "clock")
                        .searchCompletion(search)
                }
                
                Button("Clear") {
                    viewModel.clearRecentSearches()
                }
                .foregroundColor(.red)
            } header: {
                Text("Recent Searches")
            }
        }
    }
}

// Author suggestions when using the author: prefix
struct AuthorSuggestions: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        let authorPrefix = viewModel.searchQuery.dropFirst(7).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = viewModel.getTopAuthors(matching: authorPrefix)
        
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

// Tag suggestions when using the # prefix
struct TagSuggestions: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        let tagPrefix = viewModel.searchQuery.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = viewModel.getTopTags(matching: tagPrefix)
        
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
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        let titlePrefix = viewModel.searchQuery.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = viewModel.getTopTitles(matching: titlePrefix)
        
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

// Matching recent searches
struct MatchingRecentSearches: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        let recentSearches = viewModel.getRecentSearches()
            .filter { $0.lowercased().contains(viewModel.searchQuery.lowercased()) }
        
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

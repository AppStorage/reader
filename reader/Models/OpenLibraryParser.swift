import Foundation

struct OpenLibraryParser {
    static func parseMultipleResponses(_ data: Data, isbn: String?) async throws -> [BookTransferData] {
        let result = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        
        guard !result.docs.isEmpty else {
            return []
        }
        
        let books = await withTaskGroup(of: BookTransferData?.self) { group in
            for doc in result.docs {
                group.addTask {
                    await constructBookTransferData(from: doc, isbn: isbn)
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
    }
    
    static func constructBookTransferData(from doc: OpenLibraryDoc, isbn: String?) async -> BookTransferData? {
        async let description: String? = {
            if let olid = doc.key {
                return await BooksAPIService.shared.fetchDescription(olid: olid)
            }
            return nil
        }()
        
        let publishedDate = doc.first_publish_year.map { year in
            Calendar.current.date(from: DateComponents(year: year))
        }
        
        return BookTransferData(
            title: doc.title,
            author: doc.author_name?.joined(separator: ", ") ?? "Unknown Author",
            published: publishedDate ?? nil,
            publisher: doc.publisher?.first ?? "Unknown Publisher",
            genre: doc.subject?.first ?? "Unknown Genre",
            series: nil, // Open Library doesn't provide series info
            isbn: doc.isbn?.first ?? isbn,
            bookDescription: await description ?? "",
            status: "unread",
            dateStarted: nil,
            dateFinished: nil,
            quotes: [],
            notes: [],
            tags: []
        )
    }
}

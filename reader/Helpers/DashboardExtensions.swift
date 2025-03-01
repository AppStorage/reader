import Foundation

extension Array where Element == (month: String, count: Int) {
    func toMonthlyData() -> [BookStatisticsService.MonthlyData] {
        let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let sortedData = self.sorted { first, second in
            guard let firstIndex = monthOrder.firstIndex(of: first.month),
                  let secondIndex = monthOrder.firstIndex(of: second.month) else {
                return false
            }
            return firstIndex < secondIndex
        }
        
        return sortedData.map { BookStatisticsService.MonthlyData(month: $0.month, count: $0.count) }
    }
}

extension Array where Element == (genre: String, count: Int) {
    func toGenreData() -> [BookStatisticsService.GenreData] {
        let sortedData = self.sorted { $0.count > $1.count }
        return sortedData.map { BookStatisticsService.GenreData(genre: $0.genre, count: $0.count) }
    }
}

extension BookStatisticsService {
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: String
        let count: Int
        
        init(month: String, count: Int) {
            self.month = month
            self.count = count
        }
    }
    
    struct GenreData: Identifiable {
        let id = UUID()
        let genre: String
        let count: Int
        
        init(genre: String, count: Int) {
            self.genre = genre
            self.count = count
        }
    }
}

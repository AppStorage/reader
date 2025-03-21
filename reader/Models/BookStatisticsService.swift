import Foundation

class BookStatisticsService {
    static func getBooksReadComparison(books: [BookData]) -> (current: Int, previous: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let currentMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: currentMonthStart),
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart),
              let previousMonthEnd = calendar.date(byAdding: DateComponents(day: -1), to: currentMonthStart)
        else {
            return (0, 0)
        }
        
        let currentMonthBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return dateFinished >= currentMonthStart && dateFinished <= currentMonthEnd
        }
        
        let previousMonthBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return dateFinished >= previousMonthStart && dateFinished <= previousMonthEnd
        }
        
        return (current: currentMonthBooks.count, previous: previousMonthBooks.count)
    }
    
    static func getBooksReadYearlyComparison(books: [BookData]) -> (current: Int, previous: Int) {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let previousYear = currentYear - 1
        
        let currentYearBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return calendar.component(.year, from: dateFinished) == currentYear
        }
        
        let previousYearBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return calendar.component(.year, from: dateFinished) == previousYear
        }
        
        return (current: currentYearBooks.count, previous: previousYearBooks.count)
    }
    
    static func getMonthlyReadingData(books: [BookData], forYear year: Int? = nil) -> [(month: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let targetYear = year ?? calendar.component(.year, from: now)
        
        let monthsData = (0...11).map { monthIndex -> (month: String, count: Int) in
            let monthComponents = DateComponents(year: targetYear, month: monthIndex + 1)
            let monthDate = calendar.date(from: monthComponents)!
            
            var monthName = ""
            DateFormatterUtils.formatterQueue.sync {
                DateFormatterUtils.sharedFormatter.dateFormat = "MMM"
                monthName = DateFormatterUtils.sharedFormatter.string(from: monthDate)
            }
            
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            
            let isCurrentMonth = calendar.component(.year, from: now) == targetYear &&
            calendar.component(.month, from: now) == monthIndex + 1
            
            let monthEnd = isCurrentMonth
            ? now
            : calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
            
            let booksInMonth = books.filter { book in
                guard let dateFinished = book.dateFinished else { return false }
                return dateFinished >= monthStart && dateFinished <= monthEnd
            }
            
            return (month: monthName, count: booksInMonth.count)
        }
        
        return monthsData
    }
    
    static func getLongestStreak(books: [BookData]) -> (streakMonths: Int, booksCount: Int) {
        let calendar = Calendar.current
        var monthCounts: [Date: Int] = [:]
        for book in books {
            guard let date = book.dateFinished else { continue }
            let monthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            monthCounts[monthDate, default: 0] += 1
        }
        
        let sortedMonths = monthCounts.keys.sorted()
        if sortedMonths.isEmpty {
            return (0, 0)
        }
        
        var longestStreak = 1
        var longestStreakBooks = monthCounts[sortedMonths[0]] ?? 0
        var currentStreak = 1
        var currentBooks = monthCounts[sortedMonths[0]] ?? 0
        
        for i in 1..<sortedMonths.count {
            let previousMonth = sortedMonths[i - 1]
            let currentMonth = sortedMonths[i]
            let expectedNextMonth = calendar.date(byAdding: .month, value: 1, to: previousMonth)!
            if calendar.isDate(expectedNextMonth, equalTo: currentMonth, toGranularity: .month) {
                currentStreak += 1
                currentBooks += monthCounts[currentMonth] ?? 0
            } else {
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                    longestStreakBooks = currentBooks
                }
                currentStreak = 1
                currentBooks = monthCounts[currentMonth] ?? 0
            }
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
            longestStreakBooks = currentBooks
        }
        
        return (longestStreak, longestStreakBooks)
    }
    
    static func getTopGenres(books: [BookData], limit: Int = 5) -> [(genre: String, count: Int)] {
        let genreCounts = Dictionary(
            grouping: books.filter { $0.genre != nil && !$0.genre!.isEmpty }
        ) { $0.genre! }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (genre: $0.key, count: $0.value) }
        
        return genreCounts
    }
}

// MARK: - BookStatisticsService Extension
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

// MARK: - Array Extensions
extension Array where Element == (month: String, count: Int) {
    func toMonthlyData() -> [BookStatisticsService.MonthlyData] {
        var monthOrder: [String] = []
        let calendar = Calendar.current
        DateFormatterUtils.formatterQueue.sync {
            DateFormatterUtils.sharedFormatter.dateFormat = "MMM"
            for month in 1...12 {
                let dateComponents = DateComponents(year: 2000, month: month)
                if let date = calendar.date(from: dateComponents) {
                    let monthAbbreviation = DateFormatterUtils.sharedFormatter.string(from: date)
                    monthOrder.append(monthAbbreviation)
                }
            }
        }
        
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

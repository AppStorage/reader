import Foundation

class BookStatisticsService {
    static func getBooksReadComparison(books: [BookData]) -> (
        current: Int, previous: Int
    ) {
        let calendar = Calendar.current
        let now = Date()
        
        let currentMonthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now))!
        let currentMonthEnd = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: currentMonthStart)!
        
        let previousMonthStart = calendar.date(
            byAdding: .month, value: -1, to: currentMonthStart)!
        let previousMonthEnd = calendar.date(
            byAdding: DateComponents(day: -1), to: currentMonthStart)!
        
        let currentMonthBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return dateFinished >= currentMonthStart
            && dateFinished <= currentMonthEnd
        }
        
        let previousMonthBooks = books.filter { book in
            guard let dateFinished = book.dateFinished else { return false }
            return dateFinished >= previousMonthStart
            && dateFinished <= previousMonthEnd
        }
        
        return (
            current: currentMonthBooks.count, previous: previousMonthBooks.count
        )
    }
    
    static func getBooksReadYearlyComparison(books: [BookData]) -> (
        current: Int, previous: Int
    ) {
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
        
        return (
            current: currentYearBooks.count, previous: previousYearBooks.count
        )
    }
    
    static func getMonthlyReadingData(books: [BookData], forYear year: Int? = nil) -> [(
        month: String, count: Int
    )] {
        let calendar = Calendar.current
        let now = Date()
        let targetYear = year ?? calendar.component(.year, from: now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        let monthsData = (0...11).map {
            monthIndex -> (month: String, count: Int) in
            let monthComponents = DateComponents(
                year: targetYear, month: monthIndex + 1)
            let month = calendar.date(from: monthComponents)!
            
            let monthName = dateFormatter.string(from: month)
            
            let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month))!
            
            let isCurrentMonth =
            calendar.component(.year, from: now) == targetYear &&
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
    
    static func getLongestReadingStreak(books: [BookData]) -> Int {
        let finishedDates = books.compactMap { $0.dateFinished }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
        
        if finishedDates.isEmpty {
            return 0
        }
        
        var longestStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current
        
        for i in 1..<finishedDates.count {
            let previousDate = finishedDates[i - 1]
            let currentDate = finishedDates[i]
            
            if let daysBetween = calendar.dateComponents(
                [.day], from: previousDate, to: currentDate
            ).day,
               daysBetween == 1
            {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if let daysBetween = calendar.dateComponents(
                [.day], from: previousDate, to: currentDate
            ).day,
                      daysBetween == 0
            {
                continue
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    static func getTopGenres(books: [BookData], limit: Int = 5) -> [(
        genre: String, count: Int
    )] {
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

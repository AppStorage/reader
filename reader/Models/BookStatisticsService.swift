import Foundation

// MARK: - Monthly Data
struct MonthlyData: Identifiable {
    var id: String { month }
    let month: String
    let index: Int
    let count: Int
}

// MARK: - Book Statistics Service
final class BookStatisticsService {
    private static func finishedBooks(from books: [BookData]) -> [BookData] {
        books.filter { $0.dateFinished != nil }
    }

    private static func groupAndCount<T: Hashable>(_ items: [T]) -> [T: Int] {
        Dictionary(grouping: items, by: { $0 }).mapValues(\.count)
    }

    // MARK: - Get Monthly Data
    static func getMonthlyReadingData(books: [BookData], forYear year: Int? = nil) -> [(month: String, count: Int)] {
        let now = Date()
        let currentYear = DateFormatterUtils.currentYear
        let targetYear = year ?? currentYear
        let finished = finishedBooks(from: books)

        return (1...12).compactMap { monthIndex in
            guard let interval = DateFormatterUtils.monthInterval(forYear: targetYear, month: monthIndex) else {
                return nil
            }

            let monthName = DateFormatterUtils.cachedShortMonthFormatter.string(from: interval.start)
            let effectiveEnd = DateFormatterUtils.isCurrentMonth(interval.start) ? now : interval.end

            let count = finished.filter {
                guard let date = $0.dateFinished else { return false }
                return (interval.start..<effectiveEnd).contains(date)
            }.count

            return (month: monthName, count: count)
        }
    }

    static func toMonthlyData(from monthlyCounts: [(month: String, count: Int)]) -> [MonthlyData] {
        let formatter = DateFormatterUtils.cachedShortMonthFormatter

        let monthOrder: [String] = (1...12).compactMap {
            DateFormatterUtils.dateFrom(year: 2000, month: $0).map { formatter.string(from: $0) }
        }

        return monthlyCounts
            .sorted { monthOrder.firstIndex(of: $0.month)! < monthOrder.firstIndex(of: $1.month)! }
            .enumerated()
            .map { index, item in
                MonthlyData(month: item.month, index: monthOrder.firstIndex(of: item.month) ?? index, count: item.count)
            }
    }

    static func averageBooksPerMonth(_ books: [BookData], timeScale: Int) -> Double {
        let finished = finishedBooks(from: books)
        guard !finished.isEmpty else { return 0 }

        switch timeScale {
        case 0:
            let currentYear = DateFormatterUtils.currentYear
            let currentMonth = DateFormatterUtils.currentMonth
            let count = countBooks(byYear: finished)[currentYear] ?? 0
            return currentMonth == 0 ? 0 : Double(count) / Double(currentMonth)

        case 1:
            let sorted = finished.sorted { $0.dateFinished! < $1.dateFinished! }
            guard let first = sorted.first?.dateFinished,
                  let last = sorted.last?.dateFinished else { return 0 }
            let months = max(1, DateFormatterUtils.monthsBetween(start: first, end: last) + 1)
            return Double(finished.count) / Double(months)

        default:
            return 0
        }
    }

    // MARK: - Comparison
    static func getBooksReadComparison(books: [BookData]) -> (current: Int, previous: Int) {
        let currentMonth = DateFormatterUtils.currentMonth
        let currentYear = DateFormatterUtils.currentYear

        guard let currentInterval = DateFormatterUtils.monthInterval(forYear: currentYear, month: currentMonth) else {
            return (0, 0)
        }

        let (previousMonth, previousYear) = DateFormatterUtils.previousYearMonth(from: currentMonth, year: currentYear)

        guard let previousInterval = DateFormatterUtils.monthInterval(forYear: previousYear, month: previousMonth) else {
            return (0, 0)
        }

        return finishedBooks(from: books).reduce((0, 0)) { result, book in
            guard let date = book.dateFinished else { return result }
            if currentInterval.contains(date) {
                return (result.0 + 1, result.1)
            } else if previousInterval.contains(date) {
                return (result.0, result.1 + 1)
            }
            return result
        }
    }

    // MARK: - Current / Previous Year
    static func countBooksThisYear(_ books: [BookData]) -> Int {
        return countBooks(byYear: books)[DateFormatterUtils.currentYear] ?? 0
    }

    static func countBooksLastYear(_ books: [BookData]) -> Int? {
        return countBooks(byYear: books)[DateFormatterUtils.previousYear]
    }

    static func projectedBooksThisYear(books: [BookData]) -> Double {
        let currentMonth = DateFormatterUtils.currentMonth
        let remaining = 12 - currentMonth
        let booksThisYear = countBooksThisYear(books)
        let avgPerMonth = averageBooksPerMonth(books, timeScale: 0)
        return Double(booksThisYear) + avgPerMonth * Double(remaining)
    }

    // MARK: - Statistics
    static func countBooks(byYear books: [BookData]) -> [Int: Int] {
        let years = finishedBooks(from: books).compactMap {
            $0.dateFinished.map { DateFormatterUtils.year(from: $0) }
        }
        return groupAndCount(years)
    }

    static func totalBooksRead(_ books: [BookData], timeScale: Int) -> Int {
        timeScale == 0 ? countBooksThisYear(books) : finishedBooks(from: books).count
    }

    static func averageReadingTime(books: [BookData]) -> TimeInterval? {
        let durations: [TimeInterval] = books.compactMap {
            guard let start = $0.dateStarted, let end = $0.dateFinished else { return nil }
            return end.timeIntervalSince(start)
        }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    static func completionRate(books: [BookData]) -> Double {
        let finishedCount = finishedBooks(from: books).count
        return books.isEmpty ? 0 : Double(finishedCount) / Double(books.count)
    }

    static func ratingDistribution(books: [BookData]) -> [Int: Int] {
        let validRatings = books.map(\.rating).filter { (1...5).contains($0) }
        let counted = groupAndCount(validRatings)
        return (1...5).reduce(into: [:]) { $0[$1] = counted[$1, default: 0] }
    }

    static func getCurrentReadingStreakInfo(books: [BookData]) -> (months: Int, totalBooks: Int)? {
        let dates = finishedBooks(from: books).compactMap(\.dateFinished)
        guard !dates.isEmpty else { return nil }

        let grouped = Dictionary(grouping: dates) {
            DateFormatterUtils.yearMonth(from: $0)
        }.mapValues(\.count)

        var streak = 0
        var total = 0
        var current = YearMonth(
            year: DateFormatterUtils.currentYear,
            month: DateFormatterUtils.currentMonth
        )

        while let count = grouped[current], count > 0 {
            streak += 1
            total += count
            current = current.previous()
        }

        return (months: streak, totalBooks: total)
    }

    static func readingDurationString(start: Date?, end: Date?) -> String? {
        DateFormatterUtils.formattedDuration(from: start, to: end)
    }

    static func getRecentlyFinishedBooks(from books: [BookData], limit: Int? = nil) -> [BookData] {
        let sorted = finishedBooks(from: books).sorted {
            ($0.dateFinished ?? .distantPast) > ($1.dateFinished ?? .distantPast)
        }
        return limit.map { Array(sorted.prefix($0)) } ?? sorted
    }
}

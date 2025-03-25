import Foundation

// MARK: - Year Month
struct YearMonth: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    func previous() -> YearMonth {
        month == 1 ? YearMonth(year: year - 1, month: 12) : YearMonth(year: year, month: month - 1)
    }
}

// MARK: Date Formatter Utils
final class DateFormatterUtils {
    private static let calendar = Calendar.current

    private static let formatterQueue = DispatchQueue(
        label: "chip.reader.dateformatter.queue",
        attributes: .concurrent
    )

    private static let _sharedFormatter: DateFormatter = createFormatter()
    
    // MARK: - Formatter Helper
    private static func createFormatter(
        dateStyle: DateFormatter.Style? = nil,
        timeStyle: DateFormatter.Style? = nil,
        dateFormat: String? = nil
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        if let dateStyle = dateStyle { formatter.dateStyle = dateStyle }
        if let timeStyle = timeStyle { formatter.timeStyle = timeStyle }
        if let dateFormat = dateFormat { formatter.dateFormat = dateFormat }
        return formatter
    }

    // MARK: - Cached Formatters
    static let cachedMediumFormatter = createFormatter(dateStyle: .medium)
    static let cachedShortMonthFormatter = createFormatter(dateFormat: "MMM")
    static let cachedCSVFormatter = createFormatter(dateFormat: "yyyy-MM-dd")

    static var sharedFormatter: DateFormatter {
        formatterQueue.sync { _sharedFormatter }
    }

    // MARK: - Year
    static var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    static var previousYear: Int {
        currentYear - 1
    }
    
    static func year(from date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    static func dateFrom(year: Int, month: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month))
    }

    // MARK: - Format Date
    static func formatDate(
        _ date: Date?,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        guard let date = date else { return "N/A" }
        var formattedString = ""
        formatterQueue.sync {
            let formatter = sharedFormatter
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
            formattedString = formatter.string(from: date)
        }
        return formattedString
    }

    static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString, !dateString.isEmpty else { return nil }

        let formats = ["yyyy-MM-dd", "yyyy-MM", "yyyy"]

        for format in formats {
            formatterQueue.sync {
                sharedFormatter.dateFormat = format
            }
            if let date = sharedFormatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.unitsStyle = .short
        return formatter.string(from: interval) ?? "N/A"
    }

    static func formattedDuration(from start: Date?, to end: Date?) -> String? {
        guard let start, let end else { return nil }
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        
        if days == 0 {
            return "<1 day"
        }
        
        return "\(days) day" + (days == 1 ? "" : "s")
    }

    // MARK: - Current Date String
    static func currentDateString() -> String {
        var dateString = ""
        formatterQueue.sync {
            let formatter = sharedFormatter
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: Date())
        }
        return dateString
    }

    // MARK: - Month
    static var currentMonth: Int {
        calendar.component(.month, from: Date())
    }
    
    static func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(Date(), equalTo: date, toGranularity: .month)
    }
    
    static func monthInterval(
        forYear year: Int,
        month: Int,
        calendar: Calendar = .current
    ) -> DateInterval? {
        guard let date = calendar.date(from: DateComponents(year: year, month: month)) else { return nil }
        return calendar.dateInterval(of: .month, for: date)
    }
    
    static func monthsBetween(start: Date, end: Date) -> Int {
        let components = calendar.dateComponents([.month], from: start, to: end)
        return components.month ?? 0
    }
    
    // MARK: - Year Month
    static func yearMonth(from date: Date) -> YearMonth {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return YearMonth(year: comps.year!, month: comps.month!)
    }
    
    static func previousYearMonth(from month: Int, year: Int) -> (month: Int, year: Int) {
        if month == 1 {
            return (12, year - 1)
        } else {
            return (month - 1, year)
        }
    }
}

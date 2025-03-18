import Foundation

// MARK: - Date Formatter Utility
final class DateFormatterUtils {
    static let formatterQueue = DispatchQueue(
        label: "chip.reader.dateformatter.queue", attributes: .concurrent)
    
    private static let _sharedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()
    
    static var sharedFormatter: DateFormatter {
        formatterQueue.sync {
            return _sharedFormatter
        }
    }
    
    static let cachedMediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
    
    static func formatDate(
        _ date: Date?, dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        guard let date = date else { return "N/A" }
        
        var formattedString: String = ""
        formatterQueue.sync {
            let formatter = sharedFormatter
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
            formattedString = formatter.string(from: date)
        }
        return formattedString
    }
}

// MARK: - Parse Date
func parseDate(_ dateString: String?) -> Date? {
    guard let dateString, !dateString.isEmpty else { return nil }
    
    let formats = ["yyyy-MM-dd", "yyyy-MM", "yyyy"]
    
    for format in formats {
        DateFormatterUtils.formatterQueue.sync {
            DateFormatterUtils.sharedFormatter.dateFormat = format
        }
        if let date = DateFormatterUtils.sharedFormatter.date(from: dateString)
        {
            return date
        }
    }
    
    return nil
}

// MARK: - Current Date
// Used in default save name for exporting data
func currentDateString() -> String {
    var dateString: String = ""
    DateFormatterUtils.formatterQueue.sync {
        let formatter = DateFormatterUtils.sharedFormatter
        formatter.dateFormat = "yyyy-MM-dd"
        dateString = formatter.string(from: Date())
    }
    return dateString
}

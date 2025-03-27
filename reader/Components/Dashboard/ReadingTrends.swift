import SwiftUI

struct ReadingTrends: View {
    @State private var timeScale: Int = 0 // 0: This Year, 1: All Time
    
    let books: [BookData]
    
    private var currentYear: Int {
        DateFormatterUtils.currentYear
    }

    private var currentMonth: Int {
        DateFormatterUtils.currentMonth
    }
    
    private var booksThisYear: Int {
        BookStatisticsService.countBooksThisYear(books)
    }

    private var booksLastYear: Int? {
        BookStatisticsService.countBooksLastYear(books)}

    private var averageBooksPerMonth: Double {
        BookStatisticsService.averageBooksPerMonth(books, timeScale: timeScale)
    }

    private var totalBooks: Int {
        BookStatisticsService.totalBooksRead(books, timeScale: timeScale)
    }

    private var projectedTotal: Double {
        BookStatisticsService.projectedBooksThisYear(books: books)
    }
    
    private var trendMetricsRow: some View {
        HStack(spacing: 24) {
            TrendMetric(
                title: timeScale == 0 ? "Monthly Average" : "Overall Average",
                value: formatted(averageBooksPerMonth, decimals: 1),
                unit: averageBooksPerMonth == 1.0 ? "book" : "books",
                icon: "chart.xyaxis.line"
            )

            Divider()

            TrendMetric(
                title: timeScale == 0 ? "This Year" : "All Time",
                value: "\(totalBooks)",
                unit: totalBooks == 1 ? "book" : "books",
                icon: "calendar"
            )
            
            if timeScale == 0, let lastYear = booksLastYear, lastYear > 0 {
                Divider()
                
                TrendMetric(
                    title: "Last Year",
                    value: "\(lastYear)",
                    unit: lastYear == 1 ? "book" : "books",
                    icon: "calendar.badge.clock"
                )
            }

            if timeScale == 0 {
                
                Divider()

                TrendMetric(
                    title: "Projected \(currentYear)",
                    value: formatted(projectedTotal, decimals: 0),
                    unit: projectedTotal == 1.0 ? "book" : "books",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }

    private var readingStreakText: String? {
        guard let streakInfo = BookStatisticsService.getCurrentReadingStreakInfo(books: books) else {
            return nil
        }

        if streakInfo.months == 1 {
            return "You've read \(streakInfo.totalBooks) book\(streakInfo.totalBooks == 1 ? "" : "s") so far this month!"
        } else {
            return "You've read \(streakInfo.totalBooks) books across \(streakInfo.months) consecutive months!"
        }
    }
    
    private var header: some View {
        HStack {
            DashboardSectionHeader(title: "Reading Trends")
            
            Spacer()
            
            Picker("Time Scale", selection: $timeScale) {
                Text("This Year").tag(0)
                Text("All Time").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let streakText = readingStreakText {
                streakRow(text: streakText)
            }

            Divider()

            trendMetricsRow
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
    }

    private func streakRow(text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }
}

// MARK: Trend Metric
private struct TrendMetric: View {
    let title: String
    let value: String
    let unit: String
    let icon: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

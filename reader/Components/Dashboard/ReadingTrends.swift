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
                icon: "chart.xyaxis.line",
                iconColor: Color.secondary
            )

            Divider().frame(height: 40)

            TrendMetric(
                title: timeScale == 0 ? "This Year" : "All Time",
                value: "\(totalBooks)",
                unit: totalBooks == 1 ? "book" : "books",
                icon: "calendar",
                iconColor: Color.secondary
            )

            if timeScale == 0, let lastYear = booksLastYear, lastYear > 0 {
                Divider().frame(height: 40)

                TrendMetric(
                    title: "Last Year",
                    value: "\(lastYear)",
                    unit: lastYear == 1 ? "book" : "books",
                    icon: "calendar.badge.clock",
                    iconColor: Color.secondary
                )
            }

            if timeScale == 0 {
                Divider().frame(height: 40)

                TrendMetric(
                    title: "Projected \(currentYear)",
                    value: formatted(projectedTotal, decimals: 0),
                    unit: projectedTotal == 1.0 ? "book" : "books",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.secondary
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                DashboardSectionHeader("Reading Trends")
                Spacer()
                Picker("Time Scale", selection: $timeScale) {
                    Text("This Year").tag(0)
                    Text("All Time").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
            }

            if let streakText = readingStreakText {
                streakRow(text: streakText)
            }

            Divider().padding(.vertical, 4)

            trendMetricsRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }

    private func streakRow(text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
    var iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

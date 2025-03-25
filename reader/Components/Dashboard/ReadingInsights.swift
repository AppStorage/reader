import SwiftUI

struct ReadingInsights: View {
    let books: [BookData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Reading Insights")

            GeometryReader { geometry in
                HStack(spacing: 16) {
                    monthlyBooksCard
                    yearlyBooksCard
                    if let avgSeconds = BookStatisticsService.averageReadingTime(books: books) {
                        let avgDays = avgSeconds / 86400
                        averageReadingTimeCard(avgDays: avgDays)
                    }
                }
            }
            .frame(height: 100)
        }
    }

    private var monthlyBooksCard: some View {
        let monthlyComparison = BookStatisticsService.getBooksReadComparison(books: books)

        return InsightCard(
            title: "Books This Month",
            value: monthlyComparison.current,
            unit: monthlyComparison.current == 1 ? "book" : "books",
            icon: "calendar",
            iconColor: Color.secondary
        )
    }

    private var yearlyBooksCard: some View {
        let year = Calendar.current.component(.year, from: Date())
        let yearlyCounts = BookStatisticsService.countBooks(byYear: books)
        let count = yearlyCounts[year] ?? 0

        return InsightCard(
            title: "Books This Year",
            value: count,
            unit: count == 1 ? "book" : "books",
            icon: "calendar",
            iconColor: Color.secondary
        )
    }

    private func averageReadingTimeCard(avgDays: Double) -> some View {
        InsightCard(
            title: "Average Reading Time",
            value: Int(avgDays.rounded()),
            unit: Int(avgDays.rounded()) == 1 ? "day" : "days",
            icon: "clock",
            iconColor: Color.secondary
        )
    }
}

// MARK: - Insight Card
private struct InsightCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let iconColor: Color
    let previousValue: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
                
                Text(unit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
        )
    }
}


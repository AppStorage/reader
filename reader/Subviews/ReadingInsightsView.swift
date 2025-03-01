import SwiftUI

struct ReadingInsightsView: View {
    let books: [BookData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader("Reading Insights")
            
            GeometryReader { geometry in
                HStack(spacing: 16) {
                    monthlyBooksCard
                    yearlyBooksCard
                    if let avgCompletionDays = calculateCompletionTimes().average {
                        averageReadingTimeCard(avgDays: avgCompletionDays)
                    }
                }
            }
            .frame(height: 100)
        }
    }
    
    private var monthlyBooksCard: some View {
        let monthlyComparison = BookStatisticsService.getBooksReadComparison(books: books)
        
        return InsightCardView(
            title: "Books This Month",
            value: monthlyComparison.current,
            unit: "books",
            icon: "calendar",
            iconColor: Color.accentColor
        )
    }
    
    private var yearlyBooksCard: some View {
        let yearlyComparison = BookStatisticsService.getBooksReadYearlyComparison(books: books)
        
        return InsightCardView(
            title: "Books This Year",
            value: yearlyComparison.current,
            unit: "books",
            icon: "chart.bar.fill",
            iconColor: Color.accentColor
        )
    }
    
    private func averageReadingTimeCard(avgDays: Double) -> some View {
        InsightCardView(
            title: "Average Reading Time",
            value: Int(avgDays),
            unit: "days",
            icon: "clock.fill",
            iconColor: Color.accentColor
        )
    }
    
    private func calculateCompletionTimes() -> (
        average: Double?, fastest: Double?, fastestBook: String?,
        totalBooksWithDates: Int
    ) {
        let booksWithBothDates = books.filter {
            $0.dateStarted != nil && $0.dateFinished != nil
        }
        
        let completionTimes = booksWithBothDates.map { book -> (title: String, days: Double) in
            let start = book.dateStarted ?? Date()
            let finish = book.dateFinished ?? Date()
            let days = Calendar.current.dateComponents([.day], from: start, to: finish).day ?? 0
            return (title: book.title, days: max(Double(days), 1))
        }
        
        if completionTimes.isEmpty {
            return (average: nil, fastest: nil, fastestBook: nil, totalBooksWithDates: 0)
        }
        
        let avgDays = completionTimes.map { $0.days }.reduce(0, +) / Double(completionTimes.count)
        let fastestBook = completionTimes.min { $0.days < $1.days }
        
        return (
            average: avgDays,
            fastest: fastestBook?.days,
            fastestBook: fastestBook?.title,
            totalBooksWithDates: completionTimes.count
        )
    }
}
